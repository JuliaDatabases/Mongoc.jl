
#
# libbson
#

function bson_oid_init(oid_ref::Ref{BSONObjectId}, context::Ptr{Cvoid})
    ccall((:bson_oid_init, libbson), Cvoid, (Ref{BSONObjectId}, Ptr{Cvoid}), oid_ref, context)
end

function bson_oid_init_from_string(oid_ref::Ref{BSONObjectId}, oid_string::AbstractString)
    ccall((:bson_oid_init_from_string, libbson), Cvoid,
          (Ref{BSONObjectId}, Cstring),
          oid_ref, oid_string)
end

function bson_oid_to_string(oid::BSONObjectId) :: String
    buffer_len = 25
    buffer = zeros(UInt8, buffer_len)

    ccall((:bson_oid_to_string, libbson), Cvoid,
          (Ref{BSONObjectId}, Ref{UInt8}),
          Ref(oid), Ref(buffer, 1))

    @assert buffer[end] == 0
    return String(buffer[1:end-1])
end

function bson_oid_compare(oid1::BSONObjectId, oid2::BSONObjectId)
    ccall((:bson_oid_compare, libbson), Cint,
          (Ref{BSONObjectId}, Ref{BSONObjectId}),
          Ref(oid1), Ref(oid2))
end

function bson_oid_get_time_t(oid::BSONObjectId)
    ccall((:bson_oid_get_time_t, libbson), Clong, (Ref{BSONObjectId},), Ref(oid))
end

function bson_oid_is_valid(str::String)
    str_length = Csize_t(length(str))
    ccall((:bson_oid_is_valid, libbson), Bool, (Cstring, Csize_t), str, str_length)
end

function bson_reinit(bson_document::BSON)
    ccall((:bson_reinit, libbson), Cvoid, (Ptr{Cvoid},), bson_document.handle)
end

function bson_append_oid(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::BSONObjectId)
    ccall((:bson_append_oid, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Ref{BSONObjectId}),
          bson_document, key, key_length, value)
end

function bson_append_int32(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Int32)
    ccall((:bson_append_int32, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Cint),
          bson_document, key, key_length, value)
end

function bson_append_int64(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Int64)
    ccall((:bson_append_int64, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Clonglong),
          bson_document, key, key_length, value)
end

function bson_append_utf8(bson_document::Ptr{Cvoid},
                          key::AbstractString, key_length::Int, value::AbstractString, len::Int)
    ccall((:bson_append_utf8, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Cstring, Cint),
          bson_document, key, key_length, value, len)
end

function bson_append_bool(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Bool)
    ccall((:bson_append_bool, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Bool),
          bson_document, key, key_length, value)
end

function bson_append_double(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Float64)
    ccall((:bson_append_double, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Cdouble),
          bson_document, key, key_length, value)
end

function bson_append_decimal128(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Dec128)
    ccall((:bson_append_decimal128, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Ref{Dec128}),
          bson_document, key, key_length, Ref(value))
end

function bson_append_date_time(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Int64)
    ccall((:bson_append_date_time, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Clonglong),
          bson_document, key, key_length, value)
end

function bson_append_document(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Ptr{Cvoid})
    ccall((:bson_append_document, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Ptr{Cvoid}),
          bson_document, key, key_length, value)
end

function bson_append_array(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::Ptr{Cvoid})
    ccall((:bson_append_array, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Ptr{Cvoid}),
          bson_document, key, key_length, value)
end

function bson_append_binary(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int,
                            subtype::BSONSubType, value::Vector{UInt8}, val_length::UInt32)

    ccall((:bson_append_binary, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, BSONSubType, Ptr{Cvoid}, Culong),
          bson_document, key, key_length, subtype, value, val_length)
end

function bson_append_code(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int, value::String)
    ccall((:bson_append_code, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint, Cstring),
          bson_document, key, key_length, value)
end

function bson_append_null(bson_document::Ptr{Cvoid}, key::AbstractString, key_length::Int)
    ccall((:bson_append_null, libbson), Bool,
          (Ptr{Cvoid}, Cstring, Cint),
          bson_document, key, key_length)
end

function bson_new()
    ccall((:bson_new, libbson), Ptr{Cvoid}, ())
end

function bson_new_from_json(data::String, len::Int=-1)
    ccall((:bson_new_from_json, libbson), Ptr{Cvoid},
          (Ptr{UInt8}, Cssize_t, Ptr{Cvoid}),
          data, len, C_NULL)
end

function bson_destroy(bson_document::Ptr{Cvoid})
    ccall((:bson_destroy, libbson), Cvoid, (Ptr{Cvoid},), bson_document)
end

function bson_as_canonical_extended_json(bson_document::Ptr{Cvoid})
    ccall((:bson_as_canonical_extended_json, libbson), Cstring,
          (Ptr{Cvoid}, Ptr{Cvoid}),
          bson_document, C_NULL)
end

function bson_as_relaxed_extended_json(bson_document::Ptr{Cvoid})
    ccall((:bson_as_relaxed_extended_json, libbson), Cstring,
          (Ptr{Cvoid}, Ptr{Cvoid}),
          bson_document, C_NULL)
end

function bson_copy(bson_document::Ptr{Cvoid})
    ccall((:bson_copy, libbson), Ptr{Cvoid}, (Ptr{Cvoid},), bson_document)
end

function bson_has_field(bson_document::Ptr{Cvoid}, key::AbstractString)
    ccall((:bson_has_field, libbson), Bool, (Ptr{Cvoid}, Cstring), bson_document, key)
end

function bson_count_keys(bson_document::Ptr{Cvoid})
    ccall((:bson_count_keys, libbson), UInt32, (Ptr{Cvoid},), bson_document)
end

function bson_iter_init(iter_ref::Ref{BSONIter}, bson_document::Ptr{Cvoid})
    ccall((:bson_iter_init, libbson), Bool, (Ref{BSONIter}, Ptr{Cvoid}), iter_ref, bson_document)
end

function bson_iter_next(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_next, libbson), Bool, (Ref{BSONIter},), iter_ref)
end

function bson_iter_find(iter_ref::Ref{BSONIter}, key::AbstractString)
    ccall((:bson_iter_find, libbson), Bool, (Ref{BSONIter}, Cstring), iter_ref, key)
end

function bson_iter_init_find(iter_ref::Ref{BSONIter}, bson_document::Ptr{Cvoid}, key::AbstractString)
    ccall((:bson_iter_init_find, libbson), Bool,
          (Ref{BSONIter}, Ptr{Cvoid}, Cstring),
          iter_ref, bson_document, key)
end

function bson_iter_type(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_type, libbson), BSONType, (Ref{BSONIter},), iter_ref)
end

function bson_iter_key(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_key, libbson), Cstring, (Ref{BSONIter},), iter_ref)
end

function bson_iter_int32(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_int32, libbson), Int32, (Ref{BSONIter},), iter_ref)
end

function bson_iter_int64(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_int64, libbson), Int64, (Ref{BSONIter},), iter_ref)
end

function bson_iter_utf8(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_utf8, libbson), Cstring, (Ref{BSONIter}, Ptr{Cvoid}), iter_ref, C_NULL)
end

function bson_iter_bool(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_bool, libbson), Bool, (Ref{BSONIter},), iter_ref)
end

function bson_iter_double(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_double, libbson), Float64, (Ref{BSONIter},), iter_ref)
end

function bson_iter_decimal128(iter_ref::Ref{BSONIter})
    x = Ref{Dec128}()
    success = ccall((:bson_iter_decimal128, libbson), Bool, (Ref{BSONIter}, Ref{Dec128}), iter_ref, x)
    success || error("Unexpected data type when iterating decimal128")
    x[]
end

function bson_iter_oid(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_oid, libbson), Ptr{BSONObjectId}, (Ref{BSONIter},), iter_ref)
end

function bson_iter_date_time(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_date_time, libbson), Clonglong, (Ref{BSONIter},), iter_ref)
end

function bson_iter_timestamp(iter_ref::Ref{BSONIter}) :: BSONTimestamp
    timestamp = Ref{UInt32}()
    increment = Ref{UInt32}()

    ccall(
        (:bson_iter_timestamp, libbson),
        Cvoid,
        (Ref{BSONIter}, Ref{UInt32}, Ref{UInt32}),
        iter_ref, timestamp, increment
    )

    return BSONTimestamp(timestamp[], increment[])
end

function bson_iter_recurse(iter_ref::Ref{BSONIter}, child_iter_ref::Ref{BSONIter})
    ccall((:bson_iter_recurse, libbson), Bool, (Ref{BSONIter}, Ref{BSONIter}), iter_ref, child_iter_ref)
end

function bson_iter_code(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_code, libbson), Cstring, (Ref{BSONIter}, Ptr{UInt32}), iter_ref, C_NULL)
end

function bson_iter_binary(iter_ref::Ref{BSONIter}, length_ref::Ref{UInt32}, buffer_ref::Ref{Ptr{UInt8}})
    bsonsubtype_ref = Ref(BSON_SUBTYPE_BINARY)
    bson_iter_binary(iter_ref, bsonsubtype_ref, length_ref, buffer_ref)
end

function bson_iter_binary(iter_ref::Ref{BSONIter}, bsonsubtype_ref::Ref{BSONSubType}, length_ref::Ref{UInt32}, buffer_ref::Ref{Ptr{UInt8}})
    ccall((:bson_iter_binary, libbson), Cvoid,
          (Ref{BSONIter}, Ref{BSONSubType}, Ref{UInt32}, Ref{Ptr{UInt8}}),
          iter_ref, bsonsubtype_ref, length_ref, buffer_ref)
end

function bson_iter_value(iter_ref::Ref{BSONIter})
    ccall((:bson_iter_value, libbson), Ptr{Cvoid}, (Ref{BSONIter},), iter_ref)
end

function bson_free(mem::Ptr{Cvoid})
    ccall((:bson_free, libbson), Cvoid, (Ptr{Cvoid},), mem)
end

function bson_reader_destroy(bson_reader_handle::Ptr{Cvoid})
    ccall((:bson_reader_destroy, libbson), Cvoid, (Ptr{Cvoid},), bson_reader_handle)
end

function bson_reader_new_from_file(filepath::AbstractString, bson_error_ref::Ref{BSONError})
    ccall((:bson_reader_new_from_file, libbson), Ptr{Cvoid},
          (Cstring, Ref{BSONError}),
          filepath, bson_error_ref)
end

function bson_reader_new_from_data(data::Ptr{UInt8}, data_length::Integer)
    ccall((:bson_reader_new_from_data, libbson), Ptr{Cvoid}, (Ptr{UInt8}, Csize_t), data, data_length)
end

function bson_reader_read(bson_reader_handle::Ptr{Cvoid}, reached_eof_ref::Ref{Bool})
    ccall((:bson_reader_read, libbson), Ptr{Cvoid},
          (Ptr{Cvoid}, Ref{Bool}),
          bson_reader_handle, reached_eof_ref)
end

function bson_writer_destroy(bson_writer_handle::Ptr{Cvoid})
    ccall((:bson_writer_destroy, libbson), Cvoid, (Ptr{Cvoid},), bson_writer_handle)
end

function bson_writer_begin(bson_writer_handle::Ptr{Cvoid}, bson_document_handle_ref::Ref{Ptr{Cvoid}})
    ccall((:bson_writer_begin, libbson), Bool,
          (Ptr{Cvoid}, Ref{Ptr{Cvoid}}),
          bson_writer_handle, bson_document_handle_ref)
end

function bson_writer_end(bson_writer_handle::Ptr{Cvoid})
    ccall((:bson_writer_end, libbson), Cvoid, (Ptr{Cvoid},), bson_writer_handle)
end

function bson_writer_new(buffer_handle_ref::Ref{Ptr{UInt8}}, buffer_length_ref::Ref{Csize_t},
                         offset::Csize_t, realloc_func::Ptr{Cvoid}, realloc_func_ctx::Ptr{Cvoid})

    ccall((:bson_writer_new, libbson), Ptr{Cvoid},
         (Ref{Ptr{UInt8}}, Ref{Csize_t}, Csize_t, Ptr{Cvoid}, Ptr{Cvoid}),
         buffer_handle_ref, buffer_length_ref, offset, realloc_func, realloc_func_ctx)
end

function bson_writer_get_length(bson_writer_handle::Ptr{Cvoid})
    ccall((:bson_writer_get_length, libbson), Csize_t, (Ptr{Cvoid},), bson_writer_handle)
end

function bson_copy_to(src_bson_handle::Ptr{Cvoid}, dst_bson_handle::Ptr{Cvoid})
    ccall((:bson_copy_to, libbson), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), src_bson_handle, dst_bson_handle)
end

function bson_copy_to_noinit(src_bson_handle::Ptr{Cvoid}, dst_bson_handle::Ptr{Cvoid})

    # This hack will create a key that is not present in src_bson
    # since bson_copy_to_excluding_noinit requires at least one `exclude` arg.
    # This is needed because there's no `bson_copy_to_noinit` in libbson.
    function exclude_key(bson_handle::Ptr{Cvoid})
        new_exclude_key() = "___" * string(Int(rand(UInt16)))

        exclude = new_exclude_key()
        bson = BSON(bson_handle, enable_finalizer=false) # disable finalizer

        while haskey(bson, exclude)
            exclude = new_exclude_key()
        end

        return exclude
    end

    exclude = exclude_key(src_bson_handle)

    bson_copy_to_excluding_noinit(src_bson_handle, dst_bson_handle, exclude)
end

function bson_copy_to_excluding_noinit(src_bson_handle::Ptr{Cvoid}, dst_bson_handle::Ptr{Cvoid},
                                       exclude::AbstractString)
    @ccall libbson.bson_copy_to_excluding_noinit(src_bson_handle::Ptr{Cvoid},
                                                 dst_bson_handle::Ptr{Cvoid},
                                                 exclude::Cstring;
                                                 C_NULL::Cstring)::Cvoid
end

function bson_json_reader_new_from_file(filepath::AbstractString, bson_error_ref::Ref{BSONError})
    ccall((:bson_json_reader_new_from_file, libbson), Ptr{Cvoid},
          (Cstring, Ref{BSONError}),
          filepath, bson_error_ref
        )
end

function bson_json_reader_destroy(reader_handle::Ptr{Cvoid})
    ccall((:bson_json_reader_destroy, libbson), Cvoid,
          (Ptr{Cvoid},),
          reader_handle)
end

function bson_json_reader_read(reader_handle::Ptr{Cvoid}, bson_handle::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})
    ccall((:bson_json_reader_read, libbson), Cint,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          reader_handle, bson_handle, bson_error_ref)
end

#
# libmongoc
#

function mongoc_init()
    ccall((:mongoc_init, libmongoc), Cvoid, ())
end

function mongoc_cleanup()
    ccall((:mongoc_cleanup, libmongoc), Cvoid, ())
end

function mongoc_uri_new_with_error(uri_string::String, bson_error_ref::Ref{BSONError})
    ccall((:mongoc_uri_new_with_error, libmongoc), Ptr{Cvoid},
          (Cstring, Ref{BSONError}),
          uri_string, bson_error_ref)
end

function mongoc_uri_destroy(uri_handle::Ptr{Cvoid})
    ccall((:mongoc_uri_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), uri_handle)
end

function mongoc_client_new_from_uri(uri_handle::Ptr{Cvoid})
    ccall((:mongoc_client_new_from_uri, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid},), uri_handle)
end

function mongoc_client_destroy(client_handle::Ptr{Cvoid})
    ccall((:mongoc_client_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), client_handle)
end

function mongoc_client_set_appname(client_handle::Ptr{Cvoid}, appname::String)
    ccall((:mongoc_client_set_appname, libmongoc), Bool, (Ptr{Cvoid}, Cstring), client_handle, appname)
end

function mongoc_client_get_database(client_handle::Ptr{Cvoid}, db_name::String)
    ccall((:mongoc_client_get_database, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Cstring),
          client_handle, db_name)
end

function mongoc_client_find_databases_with_opts(client_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid})
    ccall((:mongoc_client_find_databases_with_opts, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}),
          client_handle, bson_opts)
end

function mongoc_client_start_session(client_handle::Ptr{Cvoid}, session_options_handle::Ptr{Cvoid},
                                     bson_error_ref::Ref{BSONError})

    ccall((:mongoc_client_start_session, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          client_handle, session_options_handle, bson_error_ref)
end

function mongoc_client_session_destroy(session_handle::Ptr{Cvoid})
    ccall((:mongoc_client_session_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), session_handle)
end

function mongoc_client_session_append(session_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid},
                                      bson_error_ref::Ref{BSONError})

    ccall((:mongoc_client_session_append, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          session_handle, bson_opts, bson_error_ref)
end

function mongoc_client_session_start_transaction(session_handle::Ptr{Cvoid},
                                                 transaction_options_handle::Ptr{Cvoid},
                                                 bson_error_ref::Ref{BSONError})

    ccall((:mongoc_client_session_start_transaction, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          session_handle, transaction_options_handle, bson_error_ref)
end

function mongoc_client_session_abort_transaction(session_handle::Ptr{Cvoid},
                                                 bson_error_ref::Ref{BSONError})

    ccall((:mongoc_client_session_abort_transaction, libmongoc), Bool,
          (Ptr{Cvoid}, Ref{BSONError}),
          session_handle, bson_error_ref)
end

function mongoc_client_session_commit_transaction(session_handle::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                                  bson_error_ref::Ref{BSONError})

    ccall((:mongoc_client_session_commit_transaction, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          session_handle, bson_reply, bson_error_ref)
end

function mongoc_client_session_in_transaction(session_handle::Ptr{Cvoid})
    ccall((:mongoc_client_session_in_transaction, libmongoc), Bool, (Ptr{Cvoid},), session_handle)
end

function mongoc_client_pool_new(uri_handle::Ptr{Cvoid})
    ccall((:mongoc_client_pool_new, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid},), uri_handle)
end

function mongoc_client_pool_destroy(client_pool_handle::Ptr{Cvoid})
    ccall((:mongoc_client_pool_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), client_pool_handle)
end

function mongoc_client_pool_pop(client_pool_handle::Ptr{Cvoid})
    ccall((:mongoc_client_pool_pop, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid},), client_pool_handle)
end

function mongoc_client_pool_try_pop(client_pool_handle::Ptr{Cvoid})
    ccall((:mongoc_client_pool_try_pop, libmongoc), Ptr{Cvoid}, (Ptr{Cvoid},), client_pool_handle)
end

function mongoc_client_pool_push(client_pool_handle::Ptr{Cvoid}, client_handle::Ptr{Cvoid})
    ccall((:mongoc_client_pool_push, libmongoc), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), client_pool_handle, client_handle)
end

function mongoc_client_pool_max_size(client_pool_handle::Ptr{Cvoid}, max_pool_size::UInt32)
    ccall((:mongoc_client_pool_max_size, libmongoc), Cvoid, (Ptr{Cvoid}, UInt32), client_pool_handle, max_pool_size)
end

function mongoc_session_opts_new()
    ccall((:mongoc_session_opts_new, libmongoc), Ptr{Cvoid}, ())
end

function mongoc_session_opts_destroy(session_options_handle::Ptr{Cvoid})
    ccall((:mongoc_session_opts_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), session_options_handle)
end

function mongoc_session_opts_get_causal_consistency(session_options_handle::Ptr{Cvoid})
    ccall((:mongoc_session_opts_get_causal_consistency, libmongoc), Bool,
          (Ptr{Cvoid},),
          session_options_handle)
end

function mongoc_session_opts_set_causal_consistency(session_options_handle::Ptr{Cvoid},
                                                    casual_consistency::Bool)

    ccall((:mongoc_session_opts_set_causal_consistency, libmongoc), Cvoid,
          (Ptr{Cvoid}, Bool),
          session_options_handle, casual_consistency)
end

function mongoc_database_destroy(database_handle::Ptr{Cvoid})
    ccall((:mongoc_database_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), database_handle)
end

function mongoc_database_get_collection(database_handle::Ptr{Cvoid}, collection_name::String)
    ccall((:mongoc_database_get_collection, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Cstring),
          database_handle, collection_name)
end

function mongoc_database_find_collections_with_opts(database_handle::Ptr{Cvoid}, bson_opts::Ptr{Cvoid})
    ccall((:mongoc_database_find_collections_with_opts, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}),
          database_handle, bson_opts)
end

function mongoc_database_command_simple(database_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid},
                                        read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                        bson_error_ref::Ref{BSONError})

    ccall((:mongoc_database_command_simple, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          database_handle, bson_command, read_prefs, bson_reply, bson_error_ref)
end

function mongoc_database_write_command_with_opts(database_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid},
                                                 bson_opts_handle::Ptr{Cvoid},
                                                 bson_reply_ref::Ref{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_database_write_command_with_opts, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{Cvoid}, Ref{BSONError}),
           database_handle, bson_command, bson_opts_handle, bson_reply_ref, bson_error_ref)
end

function mongoc_database_read_command_with_opts(database_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid},
                                                 read_prefs_handle::Ptr{Cvoid}, bson_opts_handle::Ptr{Cvoid},
                                                 bson_reply_ref::Ref{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_database_read_command_with_opts, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{Cvoid}, Ref{BSONError}),
           database_handle, bson_command, read_prefs_handle, bson_opts_handle, bson_reply_ref, bson_error_ref)
end

function mongoc_database_add_user(database_handle::Ptr{Cvoid}, username::String, password::String,
                                  bson_roles::Ptr{Cvoid}, bson_custom_data::Ptr{Cvoid},
                                  bson_error_ref::Ref{BSONError})

    ccall((:mongoc_database_add_user, libmongoc), Bool,
          (Ptr{Cvoid}, Cstring, Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          database_handle, username, password, bson_roles, bson_custom_data, bson_error_ref)
end

function mongoc_database_remove_user(database_handle::Ptr{Cvoid}, username::String,
                                     bson_error_ref::Ref{BSONError})

    ccall((:mongoc_database_remove_user, libmongoc), Bool,
          (Ptr{Cvoid}, Cstring, Ref{BSONError}),
          database_handle, username, bson_error_ref)
end

function mongoc_database_drop_with_opts(database_handle::Ptr{Cvoid},
        opts_handle::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_database_drop_with_opts, libmongoc),
          Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          database_handle, opts_handle, bson_error_ref
        )
end

function mongoc_collection_command_simple(collection_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid},
                                          read_prefs::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                          bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_command_simple, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_command, read_prefs, bson_reply, bson_error_ref)
end

function mongoc_collection_read_command_with_opts(collection_handle::Ptr{Cvoid}, bson_command::Ptr{Cvoid},
                                                    read_prefs::Ptr{Cvoid}, bson_opts_handle::Ptr{Cvoid},
                                                    bson_reply::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_command_simple, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
           collection_handle, bson_command, read_prefs, bson_opts_handle, bson_reply, bson_error_ref)
end

function mongoc_collection_destroy(collection_handle::Ptr{Cvoid})
    ccall((:mongoc_collection_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), collection_handle)
end

function mongoc_collection_insert_one(collection_handle::Ptr{Cvoid}, bson_document::Ptr{Cvoid},
                                      bson_options::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                      bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_insert_one, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_document, bson_options, bson_reply, bson_error_ref)
end

function mongoc_collection_find_with_opts(collection_handle::Ptr{Cvoid}, bson_filter::Ptr{Cvoid},
                                          bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid})

    ccall((:mongoc_collection_find_with_opts, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
          collection_handle, bson_filter, bson_opts, read_prefs)
end

function mongoc_collection_count_documents(collection_handle::Ptr{Cvoid}, bson_filter::Ptr{Cvoid},
                                           bson_opts::Ptr{Cvoid}, read_prefs::Ptr{Cvoid},
                                           bson_reply::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_count_documents, libmongoc), Int64,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_filter, bson_opts, read_prefs, bson_reply, bson_error_ref)
end

function mongoc_collection_create_bulk_operation_with_opts(collection_handle::Ptr{Cvoid},
                                                           bson_opts::Ptr{Cvoid})

    ccall((:mongoc_collection_create_bulk_operation_with_opts, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}),
          collection_handle, bson_opts)
end

function mongoc_collection_delete_one(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid},
                                      bson_opts::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                      bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_delete_one, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_selector, bson_opts, bson_reply, bson_error_ref)
end

function mongoc_collection_delete_many(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid},
                                       bson_opts::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                       bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_delete_many, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_selector, bson_opts, bson_reply, bson_error_ref)
end

function mongoc_collection_update_one(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid},
                                      bson_update::Ptr{Cvoid}, bson_opts::Ptr{Cvoid},
                                      bson_reply::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_update_one, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_selector, bson_update, bson_opts, bson_reply, bson_error_ref)
end

function mongoc_collection_update_many(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid},
                                       bson_update::Ptr{Cvoid}, bson_opts::Ptr{Cvoid},
                                       bson_reply::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_update_many, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_selector, bson_update, bson_opts, bson_reply, bson_error_ref)
end

function mongoc_collection_replace_one(collection_handle::Ptr{Cvoid}, bson_selector::Ptr{Cvoid},
                                       bson_replacement::Ptr{Cvoid}, bson_opts::Ptr{Cvoid},
                                       bson_reply::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_replace_one, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          collection_handle, bson_selector, bson_replacement, bson_opts, bson_reply, bson_error_ref)
end

function mongoc_collection_aggregate(collection_handle::Ptr{Cvoid}, flags::QueryFlags,
                                     bson_pipeline::Ptr{Cvoid}, bson_opts::Ptr{Cvoid},
                                     read_prefs::Ptr{Cvoid})

    ccall((:mongoc_collection_aggregate, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
          collection_handle, flags, bson_pipeline, bson_opts, read_prefs)
end

function mongoc_cursor_destroy(cursor_handle::Ptr{Cvoid})
    ccall((:mongoc_cursor_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), cursor_handle)
end

function mongoc_cursor_next(cursor_handle::Ptr{Cvoid}, bson_document_ref::Ref{Ptr{Cvoid}})
    ccall((:mongoc_cursor_next, libmongoc), Bool,
          (Ptr{Cvoid}, Ref{Ptr{Cvoid}}),
          cursor_handle, bson_document_ref)
end

function mongoc_cursor_set_limit(cursor_handle::Ptr{Cvoid}, limit::Int)
    ccall((:mongoc_cursor_set_limit, libmongoc), Bool, (Ptr{Cvoid}, Int64), cursor_handle, limit)
end

function mongoc_cursor_get_batch_size(cursor_handle::Ptr{Cvoid})
    ccall((:mongoc_cursor_get_batch_size, libmongoc), UInt32, (Ptr{Cvoid},), cursor_handle)
end

function mongoc_cursor_set_batch_size(cursor_handle::Ptr{Cvoid}, batch_size::Integer)
    ccall(
        (:mongoc_cursor_set_batch_size, libmongoc),
        Cvoid,
        (Ptr{Cvoid}, UInt32,),
        cursor_handle, UInt32(batch_size)
    )
end

function mongoc_cursor_error(cursor_handle::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})
    ccall((:mongoc_cursor_error, libmongoc), Bool,
          (Ptr{Cvoid}, Ref{BSONError}),
          cursor_handle, bson_error_ref)
end

function mongoc_bulk_operation_destroy(bulk_operation_handle::Ptr{Cvoid})
    ccall((:mongoc_bulk_operation_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), bulk_operation_handle)
end

function mongoc_bulk_operation_insert_with_opts(bulk_operation_handle::Ptr{Cvoid},
                                                bson_document::Ptr{Cvoid},
                                                bson_options::Ptr{Cvoid},
                                                bson_error_ref::Ref{BSONError})

    ccall((:mongoc_bulk_operation_insert_with_opts, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          bulk_operation_handle, bson_document, bson_options, bson_error_ref)
end

function mongoc_bulk_operation_replace_one_with_opts(bulk_operation_handle::Ptr{Cvoid},
                                                     bson_selector::Ptr{Cvoid},
                                                     bson_replacement::Ptr{Cvoid},
                                                     bson_options::Ptr{Cvoid},
                                                     bson_error_ref::Ref{BSONError})

    ccall((:mongoc_bulk_operation_replace_one_with_opts, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          bulk_operation_handle, bson_selector, bson_replacement, bson_options, bson_error_ref)
end

function mongoc_bulk_operation_update_one_with_opts(
    bulk_operation_handle::Ptr{Cvoid},
    bson_selector::Ptr{Cvoid},
    bson_document::Ptr{Cvoid},
    bson_options::Ptr{Cvoid},
    bson_error_ref::Ref{BSONError}
)
    ccall(
        (:mongoc_bulk_operation_update_one_with_opts, libmongoc),
        Bool,
        (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
        bulk_operation_handle, bson_selector, bson_document, bson_options, bson_error_ref
    )
end

function mongoc_bulk_operation_execute(bulk_operation_handle::Ptr{Cvoid}, bson_reply::Ptr{Cvoid},
                                       bson_error_ref::Ref{BSONError})

    ccall((:mongoc_bulk_operation_execute, libmongoc), UInt32,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          bulk_operation_handle, bson_reply, bson_error_ref)
end

function mongoc_collection_drop_with_opts(collection_handle::Ptr{Cvoid},
                                          bson_opts_handle::Ptr{Cvoid},
                                          bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_drop_with_opts, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
           collection_handle, bson_opts_handle, bson_error_ref)
end

function mongoc_find_and_modify_opts_new()
    ccall((:mongoc_find_and_modify_opts_new, libmongoc),
           Ptr{Cvoid},
           ())
end

function mongoc_find_and_modify_opts_destroy(handle::Ptr{Cvoid})
    ccall((:mongoc_find_and_modify_opts_destroy, libmongoc),
           Cvoid,
           (Ptr{Cvoid},),
           handle)
end

function mongoc_find_and_modify_opts_set_update(opts_handle::Ptr{Cvoid},
                bson_handle::Ptr{Cvoid})

    ccall((:mongoc_find_and_modify_opts_set_update, libmongoc),
           Bool,
           (Ptr{Cvoid}, Ptr{Cvoid}),
           opts_handle, bson_handle)
end

function mongoc_find_and_modify_opts_set_sort(opts_handle::Ptr{Cvoid},
                bson_handle::Ptr{Cvoid})

    ccall((:mongoc_find_and_modify_opts_set_sort, libmongoc),
           Bool,
           (Ptr{Cvoid}, Ptr{Cvoid}),
           opts_handle, bson_handle)
end

function mongoc_find_and_modify_opts_set_fields(opts_handle::Ptr{Cvoid},
                                                bson_handle::Ptr{Cvoid})

    ccall((:mongoc_find_and_modify_opts_set_fields, libmongoc),
           Bool,
           (Ptr{Cvoid}, Ptr{Cvoid}),
           opts_handle, bson_handle)
end

function mongoc_find_and_modify_opts_set_flags(opts_handle::Ptr{Cvoid},
                                               flags::FindAndModifyFlags)

    ccall((:mongoc_find_and_modify_opts_set_flags, libmongoc),
           Bool,
           (Ptr{Cvoid}, FindAndModifyFlags),
           opts_handle, flags)
end

function mongoc_find_and_modify_opts_set_bypass_document_validation(
        opts_handle::Ptr{Cvoid}, bypass::Bool)

    ccall((:mongoc_find_and_modify_opts_set_bypass_document_validation, libmongoc),
           Bool,
           (Ptr{Cvoid}, Bool),
           opts_handle, bypass)
end

function mongoc_collection_find_and_modify_with_opts(collection_handle::Ptr{Cvoid},
        query_bson_handle::Ptr{Cvoid}, opts_handle::Ptr{Cvoid},
        result_bson_handle::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_collection_find_and_modify_with_opts, libmongoc),
           Bool,
           (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
           collection_handle, query_bson_handle,
           opts_handle, result_bson_handle, bson_error_ref)
end

function mongoc_gridfs_bucket_new(database_handle::Ptr{Cvoid}, bson_opts_handle::Ptr{Cvoid},
                                  read_prefs::Ptr{Cvoid}, bson_error_ref::Ref{BSONError})

    ccall((:mongoc_gridfs_bucket_new, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          database_handle, bson_opts_handle, read_prefs, bson_error_ref)
end

function mongoc_gridfs_bucket_destroy(bucket_handle::Ptr{Cvoid})
    ccall((:mongoc_gridfs_bucket_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), bucket_handle)
end

function mongoc_stream_destroy(stream_handle::Ptr{Cvoid})
    ccall((:mongoc_stream_destroy, libmongoc), Cvoid, (Ptr{Cvoid},), stream_handle)
end

function mongoc_stream_flush(stream_handle::Ptr{Cvoid})
    ccall((:mongoc_stream_flush, libmongoc), Cint, (Ptr{Cvoid},), stream_handle)
end

function mongoc_stream_close(stream_handle::Ptr{Cvoid})
    ccall((:mongoc_stream_close, libmongoc), Cint, (Ptr{Cvoid},), stream_handle)
end

function mongoc_stream_file_new_for_path(path::AbstractString, flags::Integer, mode::Integer)
    ccall((:mongoc_stream_file_new_for_path, libmongoc), Ptr{Cvoid},
          (Cstring, Cint, Cint),
          path, flags, mode)
end

function mongoc_stream_read(
        stream_handle::Ptr{Cvoid},
        buffer_handle::Ptr{UInt8},
        count::Integer,
        min_bytes::Integer,
        timeout_msec::Integer)

    ccall((:mongoc_stream_read, libmongoc), Csize_t,
          (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Csize_t, Cint),
          stream_handle, buffer_handle, count, min_bytes, timeout_msec)
end

function mongoc_stream_write(
        stream_handle::Ptr{Cvoid},
        buffer_handle::Ptr{UInt8},
        count::Integer,
        timeout_msec::Integer)

    ccall((:mongoc_stream_write, libmongoc), Csize_t,
          (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Cint),
           stream_handle, buffer_handle, count, timeout_msec)
end

function mongoc_gridfs_bucket_upload_from_stream_with_id(
        bucket_handle::Ptr{Cvoid},
        bson_value_file_id_handle::Ptr{Cvoid},
        filename::AbstractString,
        source_stream_handle::Ptr{Cvoid},
        bson_opts_handle::Ptr{Cvoid},
        bson_error_ref::Ref{BSONError}
    )

    ccall((:mongoc_gridfs_bucket_upload_from_stream_with_id, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
          bucket_handle, bson_value_file_id_handle, filename, source_stream_handle,
          bson_opts_handle, bson_error_ref)
end

function mongoc_gridfs_bucket_download_to_stream(
        bucket_handle::Ptr{Cvoid},
        bson_value_file_id_handle::Ptr{Cvoid},
        destination_stream_handle::Ptr{Cvoid},
        bson_error_ref::Ref{BSONError}
    )

    ccall((:mongoc_gridfs_bucket_download_to_stream, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
           bucket_handle, bson_value_file_id_handle, destination_stream_handle, bson_error_ref)
end

function mongoc_gridfs_bucket_open_download_stream(
        bucket_handle::Ptr{Cvoid},
        bson_value_file_id_handle::Ptr{Cvoid},
        bson_error_ref::Ref{BSONError}
    )

    ccall((:mongoc_gridfs_bucket_open_download_stream, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
           bucket_handle, bson_value_file_id_handle, bson_error_ref)
end

function mongoc_gridfs_bucket_open_upload_stream_with_id(
        bucket_handle::Ptr{Cvoid},
        bson_value_file_id_handle::Ptr{Cvoid},
        filename::AbstractString,
        bson_opts_handle::Ptr{Cvoid},
        bson_error_ref::Ref{BSONError})

    ccall((:mongoc_gridfs_bucket_open_upload_stream_with_id, libmongoc), Ptr{Cvoid},
           (Ptr{Cvoid}, Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Ref{BSONError}),
            bucket_handle, bson_value_file_id_handle, filename,
            bson_opts_handle, bson_error_ref)
end

function mongoc_gridfs_bucket_abort_upload(stream_handle::Ptr{Cvoid})
    ccall((:mongoc_gridfs_bucket_abort_upload, libmongoc), Bool,
          (Ptr{Cvoid},), stream_handle)
end

function mongoc_gridfs_bucket_find(
        bucket_handle::Ptr{Cvoid},
        bson_filter_handle::Ptr{Cvoid},
        bson_opts_handle::Ptr{Cvoid})

    ccall((:mongoc_gridfs_bucket_find, libmongoc), Ptr{Cvoid},
          (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
          bucket_handle, bson_filter_handle, bson_opts_handle)
end

function mongoc_gridfs_bucket_delete_by_id(
        bucket_handle::Ptr{Cvoid},
        bson_value_handle::Ptr{Cvoid},
        bson_error_ref::Ref{BSONError})

    ccall((:mongoc_gridfs_bucket_delete_by_id, libmongoc), Bool,
          (Ptr{Cvoid}, Ptr{Cvoid}, Ref{BSONError}),
           bucket_handle, bson_value_handle, bson_error_ref)
end

function mongoc_gridfs_bucket_stream_error(
        stream_handle::Ptr{Cvoid},
        bson_error_ref::Ref{BSONError}
    )

    ccall((:mongoc_gridfs_bucket_stream_error, libmongoc), Bool,
          (Ptr{Cvoid}, Ref{BSONError}),
           stream_handle, bson_error_ref)
end

function mongoc_set_log_handler(
            cfunction::Ptr{Cvoid},
            userdata::Ptr{Cvoid} = C_NULL
        )

    ccall(
        (:mongoc_log_set_handler, libmongoc), Cvoid,
        (Ptr{Cvoid}, Ptr{Cvoid}),
        cfunction, userdata)
end
