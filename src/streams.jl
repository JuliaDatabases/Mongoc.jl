
"""
    MongoStreamFile(filepath;
        [flags=JL_O_RDONLY], [mode=0],
        [timeout_msec=DEFAULT_TIMEOUT_MSEC],
        [chunk_size=DEFAULT_CHUNK_SIZE])

Creates a stream from file located at `filepath`.

`flags` is the input to pass to `open`. Must be one of the constants
defined at `Base.Filesystem`: `Base.Filesystem.JL_O_RDONLY`,
`Base.Filesystem.JL_O_CREAT`, etc.

`mode` is an optional mode to pass to `open`.
"""
function MongoStreamFile(filepath::AbstractString;
    flags::Integer=Base.Filesystem.JL_O_RDONLY,
    mode::Integer=0,
    timeout_msec::Integer=DEFAULT_TIMEOUT_MSEC,
    chunk_size::Integer=DEFAULT_CHUNK_SIZE)

    handle = mongoc_stream_file_new_for_path(filepath, flags, mode)
    if handle == C_NULL
        error("Couldn't create stream for $filepath.")
    end
    return MongoStreamFile(nothing, handle, timeout_msec=timeout_msec, chunk_size=chunk_size)
end

function check_stream_error(stream::MongoIOStream)
    err_ref = Ref{BSONError}()

    if mongoc_gridfs_bucket_stream_error(stream.handle, err_ref)
        throw(err_ref[])
    end

    nothing
end

function check_stream_error(stream::AbstractMongoStream)
    nothing
end

"""
    abort_upload(io::MongoIOStream)

Aborts the upload of a GridFS upload stream.
"""
function abort_upload(io::MongoIOStream)
    ok = mongoc_gridfs_bucket_abort_upload(io.handle)
    if !ok
        check_stream_error(io)
        error("Error aborting upload.")
    end
    nothing
end

function Base.flush(stream::AbstractMongoStream)
    ok = mongoc_stream_flush(stream.handle)
    if ok == -1
        check_stream_error(stream)
        error("Error flushing stream.")
    end
    @assert ok == 0 "Unexpected result from mongoc_stream_flush: $(Int(ok))"
    nothing
end

function Base.close(stream::AbstractMongoStream)
    if stream.isopen
        ok = mongoc_stream_close(stream.handle)
        if ok == -1
            check_stream_error(stream)
            error("Error closing stream.")
        end
        @assert ok == 0 "Unexpected result from mongoc_stream_close: $(Int(ok))"
        stream.isopen = false
    end
    nothing
end

Base.isopen(stream::AbstractMongoStream) = stream.isopen

function Base.readbytes!(s::AbstractMongoStream, buffer::AbstractArray{UInt8}, nb=length(buffer))

    chunk = Vector{UInt8}(undef, s.chunk_size)
    total_nr = 0

    while true
        next_nb = min(s.chunk_size, nb - total_nr)
        nr = fillbuffer!(s, chunk, next_nb)

        if nr == 0
            # reached end of stream
            break
        end

        transfer_to_buffer!( buffer, total_nr, chunk, nr )

        total_nr += nr

        # should never happen
        @assert total_nr <= nb

        if total_nr == nb
            # read the number of bytes requested
            break
        end
    end

    return total_nr
end

# returns the number of available bytes in the buffer
function nb_free(buffer, buffer_pos::Integer)
    @assert length(buffer) >= buffer_pos
    return length(buffer) - buffer_pos
end

# returns the number of bytes that will be copied to the buffer
function nb_to_fill(buffer, buffer_pos::Integer, nr::Integer)
    fr = nb_free(buffer, buffer_pos)
    return min(nr, fr)
end

# returns the number of bytes that will be appended to the buffer
function nb_to_append(buffer, buffer_pos::Integer, nr::Integer)
    result = nr - nb_to_fill(buffer, buffer_pos, nr)
    @assert result >= 0
    return result
end

# transfers nr bytes from data to target.buffer
# writes data after target.pos, increasing buffer size if needed
function transfer_to_buffer!(buffer::T, buffer_pos::Integer, data::T, nr::Integer) where {T}

    # sanity checks
    @assert nr > 0
    @assert length(data) >= nr
    @assert buffer_pos <= length(buffer)

    resize!(buffer, length(buffer) + nb_to_append(buffer, buffer_pos, nr))

    for i in 1:nr
        buffer[buffer_pos + i] = data[i]
    end
end

# reads at most nb byter to buffer without resizing it
# returns the number of bytes read
function fillbuffer!(s::AbstractMongoStream, buffer::AbstractArray{UInt8}, nb::Integer)
    @assert nb <= length(buffer)
    nr = mongoc_stream_read(s.handle, pointer(buffer), nb, 0, s.timeout_msec)

    if nr == -1
        check_stream_error(s)
        error("Error reading from stream.")
    end

    return nr
end

function Base.unsafe_write(io::AbstractMongoStream, p::Ptr{UInt8}, n::UInt)
    written = mongoc_stream_write(io.handle, p, n, io.timeout_msec)

    if written == -1
        check_stream_error(io)
        error("Error writing to stream.")
    end

    @assert written >= 0
    return Int(written)
end
