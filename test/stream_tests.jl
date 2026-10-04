using Mongoc, Test
@testset "Native file stream reads and writes" begin
    mktempdir() do dir
        path = joinpath(dir, "bytes.dat")
        data = collect(UInt8(1):UInt8(13))
        write(path, data)
        for chunk_size in (1, 5)
            stream = Mongoc.MongoStreamFile(path; chunk_size=chunk_size)
            try
                buffer = fill(0xff, 6)
                @test readbytes!(stream, buffer) == 6
                @test buffer == data[1:6]
                @test readbytes!(stream, buffer) == 6
                @test buffer == data[7:12]
                @test readbytes!(stream, buffer) == 1
                @test buffer[1] == data[13]
                @test readbytes!(stream, buffer) == 0
            finally
                close(stream)
                Mongoc.destroy!(stream)
            end
            stream = Mongoc.MongoStreamFile(path; chunk_size=chunk_size)
            try
                @test readbytes!(stream, UInt8[]) == 0
                @test readbytes!(stream, UInt8[], 0) == 0
                buffer = UInt8[]
                @test readbytes!(stream, buffer, 20) == 13
                @test buffer == data
                @test readbytes!(stream, buffer, 20) == 0
            finally
                close(stream)
                Mongoc.destroy!(stream)
            end
            stream = Mongoc.MongoStreamFile(path; chunk_size=chunk_size)
            try
                @test_throws ErrorException write(stream, UInt8[0])
            finally
                close(stream)
                Mongoc.destroy!(stream)
            end
            stream = Mongoc.MongoStreamFile(path; flags=Base.Filesystem.JL_O_WRONLY,
                chunk_size=chunk_size)
            try
                @test_throws ErrorException readbytes!(stream, UInt8[0], 1)
            finally
                close(stream)
                Mongoc.destroy!(stream)
            end
            output = joinpath(dir, "output-$chunk_size.dat")
            stream = Mongoc.MongoStreamFile(output;
                flags=Base.Filesystem.JL_O_WRONLY | Base.Filesystem.JL_O_CREAT, mode=0o600,
                chunk_size=chunk_size)
            try
                @test write(stream, data) == length(data)
            finally
                close(stream)
                Mongoc.destroy!(stream)
            end
            @test read(output) == data
        end
    end
end
