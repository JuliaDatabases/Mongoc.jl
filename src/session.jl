
# Append session to options.
# Given that options may be nothing, always use the return value as the new value for options.
function _join(options::Union{Nothing, BSON}, session::Session) :: BSON
    result = options == nothing ? Mongoc.BSON() : options
    err_ref = Ref{BSONError}()
    ok = mongoc_client_session_append(session.handle, result.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return result
end

function set_casual_consistency!(session_options::SessionOptions, casual_consistency::Bool)
    mongoc_session_opts_set_causal_consistency(session_options.handle, casual_consistency)
    nothing
end

function get_casual_consistency(session_options::SessionOptions) :: Bool
    mongoc_session_opts_get_causal_consistency(session_options.handle)
end

get_session(database_session::DatabaseSession) = database_session.session
get_session(collection_session::CollectionSession) = get_session(collection_session.database_session)

function DatabaseSession(session::Session, db_name::String)
    DatabaseSession(Database(session.client, db_name), session)
end

function CollectionSession(database_session::DatabaseSession, collection_name::String)
    CollectionSession(database_session, Collection(database_session.database, collection_name))
end

Base.getindex(session::Session, db_name::String) = DatabaseSession(session, db_name)

function Base.getindex(database_session::DatabaseSession, collection_name::String)
    CollectionSession(database_session, collection_name)
end

#
# Overload
#
function find_collections(database::DatabaseSession; options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(database))
    find_collections(database.database; options=options_with_session)
end

function get_collection_names(database::DatabaseSession; options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(database))
    get_collection_names(database.database, options=options_with_session)
end

function insert_one(collection::CollectionSession, document::BSON;
                    options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(collection))
    insert_one(collection.collection, document, options=options_with_session)
end

function delete_one(collection::CollectionSession, selector::BSON;
                    options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(collection))
    delete_one(collection.collection, selector, options=options_with_session)
end

function delete_many(collection::CollectionSession, selector::BSON;
                     options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(collection))
    delete_many(collection.collection, selector, options=options_with_session)
end

function update_one(collection::CollectionSession, selector::BSON, update::BSON;
                    options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(collection))
    update_one(collection.collection, selector, update, options=options_with_session)
end

function update_many(collection::CollectionSession, selector::BSON, update::BSON;
                     options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(collection))
    update_many(collection.collection, selector, update, options=options_with_session)
end

function insert_many(collection::CollectionSession, documents::Vector{BSON};
                     bulk_options::Union{Nothing, BSON}=nothing,
                     insert_options::Union{Nothing, BSON}=nothing,
                     reply::Union{Nothing, Ref{BSON}}=nothing)
    bulk_options_with_session = _join(bulk_options, get_session(collection))
    insert_many(collection.collection, documents,
                bulk_options=bulk_options_with_session, insert_options=insert_options, reply=reply)
end

function find(collection::CollectionSession, bson_filter::BSON=BSON();
              options::Union{Nothing, BSON}=nothing) :: Cursor
    options_with_session = _join(options, get_session(collection))
    find(collection.collection, bson_filter, options=options_with_session)
end

function count_documents(collection::CollectionSession, bson_filter::BSON=BSON();
                         options::Union{Nothing, BSON}=nothing)
    options_with_session = _join(options, get_session(collection))
    count_documents(collection.collection, bson_filter, options=options_with_session)
end

function find_one(collection::CollectionSession, bson_filter::BSON=BSON();
                  options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}
    options_with_session = _join(options, get_session(collection))
    find_one(collection.collection, bson_filter, options=options_with_session)
end

function aggregate(collection::CollectionSession, bson_pipeline::BSON;
                   flags::QueryFlags=QUERY_FLAG_NONE,
                   options::Union{Nothing, BSON}=nothing) :: Cursor
    options_with_session = _join(options, get_session(collection))
    aggregate(collection.collection, bson_pipeline, flags=flags, options=options_with_session)
end

function find_one_and_delete(collection::CollectionSession, bson_filter::BSON;
                             options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}
    options_with_session = _join(options, get_session(collection))
    find_one_and_delete(collection.collection, bson_filter, options=options_with_session)
end

function find_one_and_replace(collection::CollectionSession, bson_filter::BSON, bson_replacement::BSON;
                              options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}
    options_with_session = _join(options, get_session(collection))
    find_one_and_replace(collection.collection, bson_filter, bson_replacement, options=options_with_session)
end

function find_one_and_update(collection::CollectionSession, bson_filter::BSON, bson_update::BSON;
                             options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}
    options_with_session = _join(options, get_session(collection))
    find_one_and_update(collection.collection, bson_filter, bson_update, options=options_with_session)
end

function drop(collection::CollectionSession, opts::Union{Nothing, BSON}=nothing)
    drop(collection.collection, opts)
end

#
# Transaction
#

function start_transaction!(session::Session)
    err_ref = Ref{BSONError}()
    ok = mongoc_client_session_start_transaction(session.handle, C_NULL, err_ref)
    if !ok
        throw(err_ref[])
    end
    nothing
end

function abort_transaction!(session::Session)
    err_ref = Ref{BSONError}()
    ok = mongoc_client_session_abort_transaction(session.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    nothing
end

function commit_transaction!(session::Session) :: BSON
    reply = BSON()
    err_ref = Ref{BSONError}()
    ok = mongoc_client_session_commit_transaction(session.handle, reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

in_transaction(session::Session) :: Bool = mongoc_client_session_in_transaction(session.handle)

#
# High-level API
#

"""
    transaction(f::Function, client::Client; session_options::SessionOptions=SessionOptions())

Use *do-syntax* to execute a transaction.

Transaction will be commited automatically. If an error occurs, the transaction is aborted.

The `session` parameter should be treated the same way as a `Client`:
from a `session` you get a `database`,
and a `collection` that are bound to the session.

```julia
Mongoc.transaction(client) do session
    database = session["my_database"]
    collection = database["my_collection"]
    new_item = Mongoc.BSON()
    new_item["inserted"] = true
    push!(collection, new_item)
end
```
"""
function transaction(f::Function, client::Client; session_options::SessionOptions=SessionOptions())
    local result::Union{Nothing, BSON} = nothing
    local aborted::Bool = false
    session = Session(client, options=session_options)
    start_transaction!(session)

    try
        f(session)
    catch
        abort_transaction!(session)
        aborted = true
        rethrow()
    finally
        if !aborted
            result = commit_transaction!(session)
        end
        Mongoc.destroy!(session)
    end

    return result
end
