
Base.show(io::IO, db::Database) = print(io, "Database($(db.client), \"", db.name, "\")")
Base.getindex(database::Database, collection_name::String) = Collection(database, collection_name)

"""
    command_simple(database::Database, command::BSON) :: BSON
    command_simple(collection::Collection, command::BSON) :: BSON

Executes a `command` given by a JSON string or a BSON instance.

It returns the first document from the result cursor.

# Example

```julia
julia> client = Mongoc.Client() # connects to localhost at port 27017
Client(URI("mongodb://localhost:27017"))

julia> bson_result = Mongoc.command_simple(client[\"admin\"], "{ \"ping\" : 1 }")
BSON("{ "ok" : 1.0 }")
```

# C API

* [`mongoc_database_command_simple`](https://mongoc.org/libmongoc/current/mongoc_database_command_simple.html)
"""
function command_simple(database::Database, command::BSON) :: BSON
    reply = BSON()
    err_ref = Ref{BSONError}()
    ok = mongoc_database_command_simple(database.handle, command.handle, C_NULL, reply.handle,
        err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

"""
    write_command(database::Database, command::BSON;
        options::Union{Nothing, BSON}=nothing) :: BSON

Issue a command with write semantics.

See https://mongoc.org/libmongoc/current/mongoc_database_read_write_command_with_opts.html.
"""
function write_command(database::Database, command::BSON;
        options::Union{Nothing, BSON}=nothing) :: BSON

    options_handle = options == nothing ? C_NULL : options.handle
    reply = BSON()
    err_ref = Ref{BSONError}()
    ok = mongoc_database_write_command_with_opts(database.handle, command.handle,
            options_handle, reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

"""
    read_command(database::Database, command::BSON;
        options::Union{Nothing, BSON}=nothing) :: BSON

Issue a command with read semantics.

See https://mongoc.org/libmongoc/current/mongoc_database_read_command_with_opts.html.
"""
function read_command(database::Database, command::BSON;
        options::Union{Nothing, BSON}=nothing) :: BSON

    options_handle = options == nothing ? C_NULL : options.handle
    reply = BSON()
    err_ref = Ref{BSONError}()
    ok = mongoc_database_read_command_with_opts(database.handle, command.handle,
            C_NULL, options_handle, reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

"""
    add_user(database::Database, username::String, password::String, roles::Union{Nothing, BSON},
        custom_data::Union{Nothing, BSON}=nothing)

This function shall create a new user with access to database.

**Warning:** Do not call this function without TLS.
"""
function add_user(database::Database, username::String, password::String,
        roles::Union{Nothing, BSON}, custom_data::Union{Nothing, BSON}=nothing)

    err_ref = Ref{BSONError}()
    roles_handle = roles == nothing ? C_NULL : roles.handle
    custom_data_handle = custom_data == nothing ? C_NULL : custom_data.handle
    ok = mongoc_database_add_user(database.handle, username, password, roles_handle,
                                  custom_data_handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    nothing
end

"""
    remove_user(database::Database, username::String)

Removes a user from database.
"""
function remove_user(database::Database, username::String)
    err_ref = Ref{BSONError}()
    ok = mongoc_database_remove_user(database.handle, username, err_ref)
    if !ok
        throw(err_ref[])
    end
    nothing
end

"""
    has_user(database::Database, user_name::String) :: Bool

Checks if `database` has a user named `user_name`.
"""
function has_user(database::Database, user_name::String) :: Bool
    cmd_result = command_simple(database, BSON("""{ "usersInfo": "$user_name" }"""))
    return !isempty(cmd_result["users"])
end

"""
    find_collections(database::Database; options::Union{Nothing, BSON}=nothing) :: Cursor

Queries for collections in a `database`.
"""
function find_collections(database::Database; options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_database_find_collections_with_opts(database.handle, options_handle)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(database, cursor_handle)
end

"""
    get_collection_names(database::Database;
        options::Union{Nothing, BSON}=nothing) :: Vector{String}

Helper method to get collection names.

See also [`Mongoc.find_collections`](@ref).
"""
function get_collection_names(database::Database;
                              options::Union{Nothing, BSON}=nothing) :: Vector{String}
    result = Vector{String}()
    for bson_collection in find_collections(database, options=options)
        push!(result, bson_collection["name"])
    end
    return result
end

# docstring for drop is at collection.jl
function drop(database::Database;
        options::Union{Nothing, BSON}=nothing)

    err_ref = Ref{BSONError}()
    opts_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_database_drop_with_opts(database.handle, opts_handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    nothing
end
