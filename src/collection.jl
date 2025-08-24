
Base.show(io::IO, coll::Collection) = print(io, "Collection($(coll.database), \"", coll.name, "\")")

# docstring for this function is at database.jl
function command_simple(collection::Collection, command::BSON) :: BSON
    reply = BSON()
    err_ref = Ref{BSONError}()
    ok = mongoc_collection_command_simple(collection.handle, command.handle, C_NULL, reply.handle,
        err_ref)

    if !ok
        throw(err_ref[])
    end
    return reply
end

function read_command(collection::Collection, command::BSON;
        options::Union{Nothing, BSON}=nothing) :: BSON

    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_read_command_with_opts(collection.handle,
            command.handle, C_NULL, options_handle, reply.handle, err_ref)

    if !ok
        throw(err_ref[])
    end
    return reply
end

# Aux function to add _id field to document if it does not exist.
# If `_id_` is not present, creates a copy of `document`.
# This function returns `document, inserted_oid`.
function _new_id(document::BSON)
    if haskey(document, "_id")
        return document, nothing
    else
        inserted_oid = BSONObjectId()

        # copies it so this function doesn't have side effects
        document = deepcopy(document)

        document["_id"] = inserted_oid
        return document, inserted_oid
    end
end

function insert_one(collection::Collection, document::BSON;
        options::Union{Nothing, BSON}=nothing) :: InsertOneResult

    document, inserted_oid = _new_id(document)
    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_insert_one(collection.handle, document.handle, options_handle,
                                      reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return InsertOneResult(reply, inserted_oid)
end

function delete_one(collection::Collection, selector::BSON; options::Union{Nothing, BSON}=nothing)
    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_delete_one(collection.handle, selector.handle, options_handle,
                                      reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

function delete_many(collection::Collection, selector::BSON; options::Union{Nothing, BSON}=nothing)
    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_delete_many(collection.handle, selector.handle, options_handle,
                                       reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

function update_one(collection::Collection, selector::BSON, update::BSON;
        options::Union{Nothing, BSON}=nothing)

    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_update_one(collection.handle, selector.handle, update.handle,
                                      options_handle, reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end
    return reply
end

function update_many(collection::Collection, selector::BSON, update::BSON;
        options::Union{Nothing, BSON}=nothing)

    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle

    ok = mongoc_collection_update_many(collection.handle, selector.handle, update.handle,
        options_handle, reply.handle, err_ref)

    if !ok
        throw(err_ref[])
    end
    return reply
end

"""
    replace_one(
            collection::Collection,
            selector::BSON,
            replacement::BSON;
            options::Union{Nothing, BSON}=nothing
        )

Replace the result of querying by `selector` with `replacement`.
"""
function replace_one(
            collection::Collection,
            selector::BSON,
            replacement::BSON;
            options::Union{Nothing, BSON}=nothing
        )

    reply = BSON()
    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_collection_replace_one(collection.handle, selector.handle, replacement.handle,
                                       options_handle, reply.handle, err_ref)
    if !ok
        throw(err_ref[])
    end

    return reply
end


function BulkOperationResult(reply::BSON, server_id::UInt32)
    BulkOperationResult(reply, server_id, Vector{Union{Nothing, BSONObjectId}}())
end

function execute!(bulk_operation::BulkOperation) :: BulkOperationResult
    if bulk_operation.executed
        error("Bulk operation was already executed.")
    end

    try
        reply = BSON()
        err_ref = Ref{BSONError}()

        bulk_operation_result = mongoc_bulk_operation_execute(bulk_operation.handle,
            reply.handle, err_ref)

        if bulk_operation_result == 0
            throw(err_ref[])
        end
        return BulkOperationResult(reply, bulk_operation_result)
    finally
        destroy!(bulk_operation)
    end
end

function bulk_insert!(bulk_operation::BulkOperation, document::BSON;
        options::Union{Nothing, BSON}=nothing)

    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    ok = mongoc_bulk_operation_insert_with_opts(bulk_operation.handle, document.handle,
        options_handle, err_ref)

    if !ok
        throw(err_ref[])
    end
    nothing
end

function bulk_replace_one!(bulk_operation::BulkOperation, selector::BSON, replacement::BSON;
        options::Union{Nothing, BSON}=nothing)

    err_ref = Ref{BSONError}()
    options_handle = options === nothing ? C_NULL : options.handle
    ok = mongoc_bulk_operation_replace_one_with_opts(
        bulk_operation.handle,
        selector.handle,
        replacement.handle,
        options_handle,
        err_ref
    )
    if !ok
        throw(err_ref[])
    end
    nothing
end

function bulk_update_one!(
    bulk_operation::BulkOperation, selector::BSON, document::BSON;
    options::Union{Nothing, BSON} = nothing
)
    err_ref = Ref{BSONError}()
    options_handle = options === nothing ? C_NULL : options.handle
    ok = mongoc_bulk_operation_update_one_with_opts(
        bulk_operation.handle,
        selector.handle,
        document.handle,
        options_handle,
        err_ref
    )
    if !ok
        throw(err_ref[])
    end
    nothing
end


function insert_many(collection::Collection, documents::Vector{BSON};
        bulk_options::Union{Nothing, BSON}=nothing, insert_options::Union{Nothing, BSON}=nothing)

    inserted_oids = Vector{Union{Nothing, BSONObjectId}}()

    bulk_operation = BulkOperation(collection, options=bulk_options)
    for doc in documents
        doc, inserted_oid = _new_id(doc)
        bulk_insert!(bulk_operation, doc, options=insert_options)
        push!(inserted_oids, inserted_oid)
    end
    result = execute!(bulk_operation)
    append!(result.inserted_oids, inserted_oids)
    return result
end

"""
    find(collection::Collection, bson_filter::BSON=BSON();
        options::Union{Nothing, BSON}=nothing) :: Cursor

Executes a query on `collection` and returns an iterable `Cursor`.

# Example

```julia
function find_contract_codes(collection, criteria::Dict=Dict()) :: Vector{String}
    result = Vector{String}()

    let
        bson_filter = Mongoc.BSON(criteria)
        bson_options = Mongoc.BSON(\"\"\"{ "projection" : { "_id" : true }, "sort" : { "_id" : 1 } }\"\"\")
        for bson_document in Mongoc.find(collection, bson_filter, options=bson_options)
            push!(result, bson_document["_id"])
        end
    end

    return result
end
```

Check the [libmongoc documentation](https://mongoc.org/libmongoc/current/mongoc_collection_find_with_opts.html)
for more information.
"""
function find(collection::Collection, bson_filter::BSON=BSON();
        options::Union{Nothing, BSON}=nothing) :: Cursor

    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_collection_find_with_opts(collection.handle, bson_filter.handle,
        options_handle, C_NULL)

    if cursor_handle == C_NULL
        error("Couldn't execute query.")
    end
    return Cursor(collection, cursor_handle)
end

"""
    count_documents(collection::Collection, bson_filter::BSON=BSON();
        options::Union{Nothing, BSON}=nothing) :: Int

Returns the number of documents on a `collection`,
with an optional filter given by `bson_filter`.

`length(collection)` and `Mongoc.count_documents(collection)`
produces the same output.

# Example

```julia
result = length(collection, Mongoc.BSON("_id" => oid))
```
"""
function count_documents(collection::Collection, bson_filter::BSON=BSON();
        options::Union{Nothing, BSON}=nothing) :: Int

    err_ref = Ref{BSONError}()
    options_handle = options == nothing ? C_NULL : options.handle
    len = mongoc_collection_count_documents(collection.handle, bson_filter.handle,
        options_handle, C_NULL, C_NULL, err_ref)

    if len == -1
        throw(err_ref[])
    end
    return Int(len)
end

function set_limit!(cursor::Cursor, limit::Int)
    ok = mongoc_cursor_set_limit(cursor.handle, limit)
    if !ok
        error("Couldn't set cursor limit to $limit.")
    end
    nothing
end

"""
    find_one(collection::Collection, bson_filter::BSON=BSON();
        options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

Execute a query to a collection and returns the first element of the result set.

Returns `nothing` if the result set is empty.
"""
function find_one(collection::Collection, bson_filter::BSON=BSON();
                  options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

    cursor = find(collection, bson_filter, options=options)
    set_limit!(cursor, 1)
    next = _iterate(cursor)
    if next == nothing
        return nothing
    else
        bson_document, _state = next
        return bson_document
    end
end

"""
    aggregate(collection::Collection, bson_pipeline::BSON;
        flags::QueryFlags=QUERY_FLAG_NONE,
        options::Union{Nothing, BSON}=nothing) :: Cursor

Use `Mongoc.aggregate` to execute an aggregation command.

# Example

The following reproduces the example from the
[MongoDB Tutorial](https://docs.mongodb.com/manual/aggregation/).

```julia
docs = [
    Mongoc.BSON(\"\"\"{ "cust_id" : "A123", "amount" : 500, "status" : "A" }\"\"\"),
    Mongoc.BSON(\"\"\"{ "cust_id" : "A123", "amount" : 250, "status" : "A" }\"\"\"),
    Mongoc.BSON(\"\"\"{ "cust_id" : "B212", "amount" : 200, "status" : "A" }\"\"\"),
    Mongoc.BSON(\"\"\"{ "cust_id" : "A123", "amount" : 300, "status" : "D" }\"\"\")
]

collection = client["my-database"]["aggregation-collection"]
append!(collection, docs)

# Sets the pipeline command
bson_pipeline = Mongoc.BSON(\"\"\"
    [
        { "\$match" : { "status" : "A" } },
        { "\$group" : { "_id" : "\$cust_id", "total" : { "\$sum" : "\$amount" } } }
    ]
\"\"\")

for doc in Mongoc.aggregate(collection, bson_pipeline)
  println(doc)
end
```

The result of the script above is:

```julia
BSON("{ "_id" : "B212", "total" : 200 }")
BSON("{ "_id" : "A123", "total" : 750 }")
```
"""
function aggregate(collection::Collection, bson_pipeline::BSON;
                   flags::QueryFlags=QUERY_FLAG_NONE,
                   options::Union{Nothing, BSON}=nothing) :: Cursor

    options_handle = options == nothing ? C_NULL : options.handle
    cursor_handle = mongoc_collection_aggregate(collection.handle, flags,
                        bson_pipeline.handle, options_handle, C_NULL)

    if cursor_handle == C_NULL
        error("Couldn't execute aggregate command.")
    end
    return Cursor(collection, cursor_handle)
end

"""
    drop(database::Database, opts::Union{Nothing, BSON}=nothing)
    drop(collection::Collection, opts::Union{Nothing, BSON}=nothing)

Drops `database` or `collection`.

For information about `opts` argument, check the libmongoc documentation for
[database drop](https://mongoc.org/libmongoc/current/mongoc_database_drop_with_opts.html)
or
[collection drop](https://mongoc.org/libmongoc/current/mongoc_collection_drop_with_opts.html).
"""
function drop(collection::Collection, opts::Union{Nothing, BSON}=nothing)
    opts_handle = opts == nothing ? C_NULL : opts.handle
    err_ref = Ref{BSONError}()
    ok = mongoc_collection_drop_with_opts(collection.handle, opts_handle, err_ref)

    if !ok
        throw(err_ref[])
    end
    nothing
end

# findAndModify
function Base.setproperty!(builder::FindAndModifyOptsBuilder, opt::Symbol, val::BSON)
    if opt == :update
        set_opt_update!(builder, val)

    elseif opt == :sort
        set_opt_sort!(builder, val)

    elseif opt == :fields
        set_opt_fields!(builder, val)

    else
        error("Unknown option for FindAndModifyOptsBuilder: $opt")
    end
end

function Base.setproperty!(builder::FindAndModifyOptsBuilder, opt::Symbol, val::FindAndModifyFlags)
    @assert opt == :flags "Can't set $val to field $opt."
    set_opt_flags!(builder, val)
end

function set_opt_update!(builder::FindAndModifyOptsBuilder, val::BSON)
    ok = mongoc_find_and_modify_opts_set_update(builder.handle, val.handle)
    if !ok
        error("Couldn't set option update $val for FindAndModifyOptsBuilder.")
    end
    nothing
end

function set_opt_sort!(builder::FindAndModifyOptsBuilder, val::BSON)
    ok = mongoc_find_and_modify_opts_set_sort(builder.handle, val.handle)
    if !ok
        error("Couldn't set option sort $val for FindAndModifyOptsBuilder.")
    end
    nothing
end

function set_opt_fields!(builder::FindAndModifyOptsBuilder, val::BSON)
    ok = mongoc_find_and_modify_opts_set_fields(builder.handle, val.handle)
    if !ok
        error("Couldn't set option fields $val for FindAndModifyOptsBuilder.")
    end
    nothing
end

function set_opt_flags!(builder::FindAndModifyOptsBuilder, val::FindAndModifyFlags)
    ok = mongoc_find_and_modify_opts_set_flags(builder.handle, val)
    if !ok
        error("Couldn't set option flags $val for FindAndModifyOptsBuilder.")
    end
    nothing
end

function Base.setproperty!(builder::FindAndModifyOptsBuilder, opt::Symbol, val::Bool)
    @assert opt == :bypass_document_validation "Can't set $val to field $opt."
    set_opt_bypass_document_validation!(builder, val)
end

function set_opt_bypass_document_validation!(builder::FindAndModifyOptsBuilder, bypass::Bool)
    ok = mongoc_find_and_modify_opts_set_bypass_document_validation(builder.handle, bypass)
    if !ok
        error("Couldn't set option `bypass document validation` for FindAndModifyOptsBuilder.")
    end
    nothing
end

"""
    find_and_modify(collection::Collection, query::BSON;
        update::Union{Nothing, BSON}=nothing,
        sort::Union{Nothing, BSON}=nothing,
        fields::Union{Nothing, BSON}=nothing,
        flags::Union{Nothing, FindAndModifyFlags}=nothing,
        bypass_document_validation::Bool=false,
    ) :: BSON

Find documents and updates them in one go.

See [`Mongoc.FindAndModifyFlags`](@ref) for a list of accepted values
for `flags` argument.

# C API

* [mongoc_collection_find_and_modify](https://mongoc.org/libmongoc/current/mongoc_collection_find_and_modify.html).
"""
function find_and_modify(collection::Collection, query::BSON;
            update::Union{Nothing, BSON}=nothing,
            sort::Union{Nothing, BSON}=nothing,
            fields::Union{Nothing, BSON}=nothing,
            flags::Union{Nothing, FindAndModifyFlags}=nothing,
            bypass_document_validation::Bool=false,
        ) :: BSON

    opts = FindAndModifyOptsBuilder(
            update=update,
            sort=sort,
            fields=fields,
            flags=flags,
            bypass_document_validation=bypass_document_validation,
    )

    reply = BSON()
    err_ref = Ref{BSONError}()

    ok = mongoc_collection_find_and_modify_with_opts(
            collection.handle,
            query.handle, opts.handle,
            reply.handle, err_ref)

    if !ok
        throw(err_ref[])
    end

    return reply
end

const FIND_ONE_AND_DELETE_FIELDS = Dict(
    "collation" => "collation",
    "maxTimeMS" => "maxTimeMS",
    "projection" => "fields",
    "sort" => "sort",
    "writeConcern" => "writeConcern",
)

"""
    find_one_and_delete(collection::Collection, bson_filter::BSON;
        options::Union{Nothing, BSON}=nothing
    ) :: Union{Nothing, BSON}

Delete a document and return it.

See [db.collection.findOneAndDelete](https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndDelete/)
for a list of accepted options.
"""
function find_one_and_delete(collection::Collection, bson_filter::BSON;
        options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

    command_bson = BSON(
        "findAndModify" => collection.name,
        "query" => bson_filter,
        "remove" => true,
    )

    options_bson = BSON()

    if !isnothing(options)
        for (opt_key, comm_key) in FIND_ONE_AND_DELETE_FIELDS
            if haskey(options, opt_key)
                command_bson[comm_key] = options[opt_key]
            end
        end

        if haskey(options, "sessionId")
            options_bson["sessionId"] = options["sessionId"]
        end
    end

    reply = write_command(
        collection.database,
        command_bson,
        options=options_bson,
    )

    return reply["value"]
end

const FIND_ONE_AND_MODIFY_FIELDS = Dict(
    "arrayFilters" => "arrayFilters",
    "bypassDocumentValidation" .=> "bypassDocumentValidation",
    "collation" => "collation",
    "maxTimeMS" => "maxTimeMS",
    "projection" => "fields",
    "returnNewDocument" => "new",
    "sort" => "sort",
    "upsert" => "upsert",
    "writeConcern" => "writeConcern",
)

function _find_one_and_modify(collection::Collection, bson_filter::BSON, bson_modify::BSON;
        options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

    command_bson = BSON(
        "findAndModify" => collection.name,
        "query" => bson_filter,
        "update" => bson_modify,
    )

    options_bson = BSON()

    if !isnothing(options)
        for (opt_key, comm_key) in FIND_ONE_AND_MODIFY_FIELDS
            if haskey(options, opt_key)
                command_bson[comm_key] = options[opt_key]
            end
        end

        if haskey(options, "sessionId")
            options_bson["sessionId"] = options["sessionId"]
        end
    end

    reply = write_command(
        collection.database,
        command_bson,
        options=options_bson,
    )

    return reply["value"]
end

"""
    find_one_and_replace(collection::Collection, bson_filter::BSON, bson_replacement::BSON;
        options::Union{Nothing, BSON}=nothing
    ) :: Union{Nothing, BSON}

Replace a document and return the original.

See [db.collection.findOneAndReplace](https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndReplace/)
for a list of accepted options.
"""
function find_one_and_replace(collection::Collection, bson_filter::BSON, bson_replacement::BSON;
        options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

    # Ensure the document has no operators
    for key in keys(bson_replacement)
        if startswith(key, '$')
            throw(ArgumentError("replacement must not contain update operators"))
        end
    end

    return _find_one_and_modify(collection, bson_filter, bson_replacement, options=options)
end

"""
    find_one_and_update(collection::Collection, bson_filter::BSON, bson_update::BSON;
        options::Union{Nothing, BSON}=nothing
    ) :: Union{Nothing, BSON}

Update a document and return the original.

See [db.collection.findOneAndUpdate](https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndUpdate/)
for a list of accepted options.
"""
function find_one_and_update(collection::Collection, bson_filter::BSON, bson_update::BSON;
        options::Union{Nothing, BSON}=nothing) :: Union{Nothing, BSON}

    # Ensure the document only contains operators
    for key in keys(bson_update)
        if !startswith(key, '$')
            throw(ArgumentError("update must only contain update operators"))
        end
    end

    return _find_one_and_modify(collection, bson_filter, bson_update, options=options)
end

#
# High-level API
#

function _iterate(cursor::Cursor, state::Nothing=nothing)
    bson_handle_ref = Ref{Ptr{Cvoid}}()
    has_next = mongoc_cursor_next(cursor.handle, bson_handle_ref)

    if has_next
        # The bson document is valid only until the next call to mongoc_cursor_next.
        # So we should return a deepcopy.
        return deepcopy(BSON(bson_handle_ref[], enable_finalizer=false)), nothing
    else
        err_ref = Ref{BSONError}()
        if mongoc_cursor_error(cursor.handle, err_ref)
            throw(err_ref[])
        end

        return nothing
    end
end

# Cursor implementation of the iteration interface
Base.iterate(cursor::Cursor, state::Nothing=nothing) = _iterate(cursor, state)

Base.IteratorSize(::Type{Cursor{T}}) where T = Base.SizeUnknown()
Base.IteratorEltype(::Type{Cursor{T}}) where T = Base.HasEltype()
Base.eltype(::Type{Cursor{T}}) where T = BSON

# Collection implementation of the iteration interface
Base.IteratorSize(::Type{<:AbstractCollection}) = Base.HasLength()
Base.IteratorEltype(::Type{<:AbstractCollection}) = Base.HasEltype()
Base.eltype(::Type{<:AbstractCollection}) = BSON

function Base.iterate(coll::Collection)
    cursor = find(coll)
    return iterate(coll, cursor)
end

function Base.iterate(coll::Collection, state::Cursor)
    next = _iterate(state)
    if next === nothing
        return nothing
    else
        doc, _ = next
        return doc, state
    end
end

function Base.push!(collection::AbstractCollection, document::BSON;
                    options::Union{Nothing, BSON}=nothing)
    insert_one(collection, document; options=options)
end

function Base.append!(collection::AbstractCollection, documents::Vector{BSON};
                      bulk_options::Union{Nothing, BSON}=nothing,
                      insert_options::Union{Nothing, BSON}=nothing)
    insert_many(collection, documents; bulk_options=bulk_options, insert_options=insert_options)
end

function Base.length(collection::AbstractCollection, bson_filter::BSON=BSON();
                     options::Union{Nothing, BSON}=nothing)
    count_documents(collection, bson_filter; options=options)
end

function Base.isempty(collection::AbstractCollection, bson_filter::BSON=BSON();
                      options::Union{Nothing, BSON}=nothing)
    count_documents(collection, bson_filter; options=options) == 0
end

Base.empty!(collection::C) where {C<:AbstractCollection} = delete_many(collection, BSON())

function Base.collect(cursor::Cursor) :: Vector{BSON}
    result = Vector{BSON}()
    for doc in cursor
        push!(result, doc)
    end
    return result
end

function Base.collect(collection::AbstractCollection, bson_filter::BSON=BSON())
    return collect(find(collection, bson_filter))
end
