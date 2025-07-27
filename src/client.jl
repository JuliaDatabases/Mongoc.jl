
Base.show(io::IO, uri::URI) = print(io, "URI(\"", replace(uri.uri, r":.*@" => ":******@"), "\")")
Base.show(io::IO, client::Client) = print(io, "Client(", client.uri, ")")
Base.getindex(client::Client, database::String) = Database(client, database)

"""
    Client(host, port)
    Client(uri)
    Client()
    Client(pool; [try_pop=false])

Creates a `Client`, which represents a connection to a MongoDB database.

See also [`Mongoc.ClientPool`](@ref).

# Examples:

These lines are equivalent.

```julia
c = Mongoc.Client()
c = Mongoc.Client("localhost", 27017)
c = Mongoc.Client("mongodb://localhost:27017")
```
"""
Client(host::String, port::Int) = Client(URI("mongodb://$host:$port"))
Client(uri::String) = Client(URI(uri))
Client() = Client("localhost", 27017)

"""
    set_appname!(client::Client, appname::String)

Sets the application name for this client.

This string, along with other internal driver details,
is sent to the server as part of the initial connection handshake.

# C API

* [`mongoc_client_set_appname`](https://mongoc.org/libmongoc/current/mongoc_client_set_appname.html).
"""
function set_appname!(client::Client, appname::String)
    ok = mongoc_client_set_appname(client.handle, appname)
    if !ok
        error("Couldn't set appname=$appname for client $client.")
    end
    nothing
end

"""
    ping(client::Client) :: BSON

Pings the server, testing wether it is reachable.

One thing to keep in mind is that operations on MongoDB are *lazy*,
which means that a client reaches a server only when it needs to
transfer documents.

# Example

```julia
julia> client = Mongoc.Client() # nothing happens here between client and server
Client(URI("mongodb://localhost:27017"))

julia> Mongoc.ping(client) # connection to server happens here
BSON("{ "ok" : 1.0 }")
```
"""
function ping(client::Client) :: BSON
    return command_simple(client["admin"], BSON("""{ "ping" : 1 }"""))
end

"""
    get_server_mongodb_version(client::Client) :: VersionNumber

Queries the version for the MongoDB server instance.
"""
function get_server_mongodb_version(client::Client) :: VersionNumber
    bson_server_status = command_simple(client["admin"], BSON("""{ "serverStatus" : 1 }"""))
    return VersionNumber(bson_server_status["version"])
end

"""
    find_databases(client::Client; options::Union{Nothing, BSON}=nothing) :: Cursor

Queries for databases.
"""
function find_databases(client::Client; options::Union{Nothing, BSON}=nothing) :: Cursor
    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_client_find_databases_with_opts(client.handle, options_handle)
    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(client, cursor_handle)
end

"""
    get_database_names(client::Client; options::Union{Nothing, BSON}=nothing) :: Vector{String}

Helper method to get a list of names for all databases.

See also [`Mongoc.find_databases`](@ref).
"""
function get_database_names(client::Client; options::Union{Nothing, BSON}=nothing) :: Vector{String}
    result = Vector{String}()
    for bson_database in find_databases(client, options=options)
        push!(result, bson_database["name"])
    end
    return result
end

"""
    has_database(client::Client, database_name::String;
        options::Union{Nothing, BSON}=nothing) :: Bool

Helper method to check if there is a database named `database_name`.

See also [`Mongoc.find_databases`](@ref).
"""
function has_database(client::Client, database_name::String;
                      options::Union{Nothing, BSON}=nothing) :: Bool
    for bson_database in find_databases(client, options=options)
        if bson_database["name"] == database_name
            return true
        end
    end
    return false
end
