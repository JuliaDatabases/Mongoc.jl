
# Tutorial

This tutorial illustrates common use cases for accessing a MongoDB database with **Mongoc.jl** package.

## Setup

First, make sure you have **Mongoc.jl** package installed.

```julia
julia> using Pkg

julia> Pkg.add("Mongoc")
```

The following tutorial assumes that a MongoDB instance is running on the
default host and port: `localhost:27017`.

To start a new server instance on the default location use the following command on your shell.

```shell
$ mkdir db

$ mongod --dbpath ./db
```

## Connecting to MongoDB

Connect to a MongoDB instance using a `Mongoc.Client`.
Use the [MongoDB URI format](https://docs.mongodb.com/manual/reference/connection-string/) to set the server location.

```julia
julia> import Mongoc

julia> client = Mongoc.Client("mongodb://localhost:27017")
Client(URI("mongodb://localhost:27017"))
```

As a shorthand, you can also use:

```julia
julia> client = Mongoc.Client("localhost", 27017)
```

To connect to the server at the default location `localhost:27017`
you can use the `Mongoc.Client` constructor with no arguments.

```julia
julia> client = Mongoc.Client()
```

One thing to keep in mind about MongoDB is that operations are usually lazy.
So you don't actually connect to the database until you need to issue a command or query.

If you need to check the connection status before sending commands,
use `Mongoc.ping(client)` to ping the server.

```julia
julia> Mongoc.ping(client)
BSON("{ "ok" : 1.0 }")
```

## Getting a Database

A MongoDB instance consists on a set of independent databases.
You get a Database reference using the following command.

```julia
julia> database = client["my-database"]
Database(Client(URI("mongodb://localhost:27017")), "my-database")
```

If `"my-database"` does not exist on your MongoDB instance, it will be created
in the first time you insert a document in it.

## Getting a Collection

A Collection is a set of documents in a MongoDB database.
You get a collection reference using the following command.

```julia
julia> collection = database["my-collection"]
Collection(Database(Client(URI("mongodb://localhost:27017")), "my-database"), "my-collection")
```

If it does not exist inside your database, the Collection
is created in the first time you insert a document in it.

## BSON Documents

[BSON](https://bsonspec.org/) is the document format for MongoDB.

To create a BSON document instance in **Mongoc.jl** just use Dictionary syntax,
using `String`s as keys.

```julia
julia> document = Mongoc.BSON()

julia> document["name"] = "Felipe"

julia> document["age"] = 35

julia> document["preferences"] = [ "Music", "Computer", "Photography" ]

julia> document["null_value"] = nothing # maps to BSON null value

julia> using Dates; document["details"] = Dict("birth date" => DateTime(1983, 4, 16), "location" => "Rio de Janeiro")

julia> using UUIDs; document["id"] = uuid4()
```

As another example:

```julia
julia> document = Mongoc.BSON("a" => 1, "b" => "field_b", "c" => [1, 2, 3])
BSON("{ "a" : 1, "b" : "field_b", "c" : [ 1, 2, 3 ] }")
```

You can also create a BSON document from a JSON string.

```julia
julia> document = Mongoc.BSON("""{ "hey" : "you" }""")
```

And also from a Dictionary.

```julia
julia> dict = Dict("hey" => "you")
Dict{String,String} with 1 entry:
  "hey" => "you"

julia> document = Mongoc.BSON(dict)
BSON("{ "hey" : "you" }")
```

Reading data from a BSON is like reading from a `Dict`.

```julia
julia> document = Mongoc.BSON("a" => 1, "b" => "field_b", "c" => [1, 2, 3])
BSON("{ "a" : 1, "b" : "field_b", "c" : [ 1, 2, 3 ] }")

julia> document["a"]
1

julia> document["b"]
"field_b"
```

Like a `Dict`, you can iterate thru BSON's `(key, value)` pairs, like so:

```julia
julia> for (k, v) in document
           println("[$k] = $v")
       end
[a] = 1
[b] = field_b
[c] = Any[1, 2, 3]
```

To convert a BSON to a JSON string, use:

```julia
julia> Mongoc.as_json(document)
"{ \"name\" : \"Felipe\", \"age\" : 35, \"preferences\" : [ \"Music\", \"Computer\", \"Photography\" ], \"null_value\" : null, \"details\" : { \"location\" : \"Rio de Janeiro\", \"birth date\" : { \"\$date\" : \"1983-04-16T00:00:00Z\" } } }"
```

To convert a BSON document to a Dictionary, use `Mongoc.as_dict`.

```julia
julia> Mongoc.as_dict(document)
Dict{Any,Any} with 1 entry:
  "hey" => "you"
```

## Read/Write BSON documents from/to IO Stream

You can read and write BSON documents in binary format to IO streams.

### High-level API

BSON documents can be serialized using Julia's `Serialization` stdlib.
This means that BSON documents can also be shared among Julia workers
using Julia's `Distributed` stdlib.

```julia

using Test, Mongoc

@testset "read/write single BSON" begin
    doc = Mongoc.BSON("a" => 1)
    io = IOBuffer()
    write(io, doc)
    seekstart(io)
    doc2 = read(io, Mongoc.BSON)
    @test doc2["a"] == 1
end

addprocs(1)
@everywhere using Mongoc

@testset "Serialize BSON" begin
    f = @spawn Mongoc.BSON("a" => 1)
    bson = fetch(f)
    @test bson["a"] == 1
end
```

### Low-level API

The following example shows how to:

1. Create a vector of BSON documents.
2. Save the vector to a file.
3. Read back the vector of BSON documents from a file.

```julia
using Test, Mongoc

filepath = "data.bson"
list = Vector{Mongoc.BSON}()

let
    src = Mongoc.BSON()
    src["id"] = 1
    src["name"] = "1st"
    push!(list, src)
end

let
    src = Mongoc.BSON()
    src["id"] = 2
    src["name"] = "2nd"
    push!(list, src)
end

open(filepath, "w") do io
    Mongoc.write_bson(io, list)
end

list_from_file = Mongoc.read_bson(filepath)
@test length(list_from_file) == 2

let
    fst_bson = list_from_file[1]
    @test fst_bson["id"] == 1
    @test fst_bson["name"] == "1st"
end

let
    sec_bson = list_from_file[2]
    @test sec_bson["id"] == 2
    @test sec_bson["name"] == "2nd"
end
```

## Read BSON Documents from a JSON File

Given a JSON file `docs.json` with the following content:

```json
{ "num" : 1, "str" : "two" }
{ "num" : 2, "str" : "three" }
```

This file can be read using a `Mongoc.BSONJSONReader`.
A high-level function `Mongoc.read_bson_from_json` is also available.

Notice how strange the json format is: it is a sequence of JSON documents without separator.
Adding a separator (`, `) between JSON documents will duplicate the BSON fields.
Also, if you enclose the whole file with a vector of JSONs, a single BSON will be returned
with a vector of elements.

### Examples

```julia
vec_of_bsons = Mongoc.read_bson_from_json("docs.json")
```

```julia
reader = Mongoc.BSONJSONReader("docs.json")
for bson in reader
    println(bson)
end
```

## Inserting Documents

To insert a single document into a collection, just `Base.push!` a BSON document to it.
The result of this operation wraps the server reply and the inserted oid.

```julia
julia> document = Mongoc.BSON("""{ "hey" : "you" }""")
BSON("{ "hey" : "you" }")

julia> result = push!(collection, document)
Mongoc.InsertOneResult{Mongoc.BSONObjectId}(BSON("{ "insertedCount" : 1 }"), BSONObjectId("5c9fdb5d11c3dd04a83ba6c2"))

julia> result.inserted_oid
BSONObjectId("5c9fdb5d11c3dd04a83ba6c2")
```

Use `Base.append!` to insert a vector of documents to a collection.
The result of this operation also wraps the server reply and the inserted oids.

```julia
julia> doc1 = Mongoc.BSON("""{ "hey" : "you", "out" : "there" }""")
BSON("{ "hey" : "you", "out" : "there" }")

julia> doc2 = Mongoc.BSON("""{ "hey" : "others", "in the" : "cold" }""")
BSON("{ "hey" : "others", "in the" : "cold" }")

julia> vector = [ doc1, doc2 ]
2-element Array{Mongoc.BSON,1}:
 BSON("{ "hey" : "you", "out" : "there" }")
 BSON("{ "hey" : "others", "in the" : "cold" }")

julia> append!(collection, vector)
Mongoc.BulkOperationResult{Union{Nothing, BSONObjectId}}(BSON("{ "nInserted" : 2, "nMatched" : 0, "nModified" : 0, "nRemoved" : 0, "nUpserted" : 0, "writeErrors" : [  ] }"), 0x00000001, Union{Nothing, BSONObjectId}[BSONObjectId("5c9fdbab11c3dd04a83ba6c3"), BSONObjectId("5c9fdbab11c3dd04a83ba6c4")])
```

## Querying Documents

To query a single document, use `Mongoc.find_one`. Pass a BSON argument as a query filter.

```julia
julia> document = Mongoc.find_one(collection, Mongoc.BSON("""{ "hey" : "you" }"""))
BSON("{ "_id" : { "$oid" : "5b9ef9cc11c3dd1da14675c3" }, "hey" : "you" }")
```

To iterate all documents from a collection, just use a for loop on a `collection`.

```julia
julia> for document in collection
        println(document)
       end
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e5" }, "hey" : "you", "out" : "there" }")
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e6" }, "hey" : "others", "in the" : "cold" }")
```

To query multiple documents, use `Mongoc.find`. Pass a BSON query argument as a query filter.
It returns a iterator of BSON documents that can be read using a `for` loop.

```julia
julia> for document in Mongoc.find(collection, Mongoc.BSON("""{ "in the" : "cold" }"""))
           println(document)
       end
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e6" }, "hey" : "others", "in the" : "cold" }")
```

Use `Base.collect` to convert the result of `Mongoc.find` into a vector of BSON documents.

Also, applying `Base.collect` to a Collection gathers all documents in the collection.

```julia
julia> collect(collection)
2-element Array{Mongoc.BSON,1}:
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e5" }, "hey" : "you", "out" : "there" }")
BSON("{ "_id" : { "$oid" : "5b9f02fb11c3dd1f4f3e26e6" }, "hey" : "others", "in the" : "cold" }")
```

## Project fields to Return from Query

To select which fields you want a query to return,
use a `projection` command in the `options` argument
of `Mongoc.find` or `Mongoc.find_one`.

As an example:

```julia
function find_contract_codes(collection, criteria::Dict=Dict()) :: Vector{String}
    result = Vector{String}()

    let
        bson_filter = Mongoc.BSON(criteria)
        bson_options = Mongoc.BSON("""{ "projection" : { "_id" : true }, "sort" : { "_id" : 1 } }""")
        for bson_document in Mongoc.find(collection, bson_filter, options=bson_options)
            push!(result, bson_document["_id"])
        end
    end

    return result
end
```

Check the [libmongoc documentation for options field](https://mongoc.org/libmongoc/current/mongoc_collection_find_with_opts.html) for details.

## Counting Documents

Use `Base.length` function to count the number of documents in a collection.
Pass a BSON argument as a query filter.

```julia
julia> length(collection)
2

julia> length(collection, Mongoc.BSON("""{ "in the" : "cold" }"""))
1
```

## Aggregation and Map-Reduce

Use `Mongoc.aggregate` to execute an aggregation command.

The following reproduces the example from the [MongoDB Tutorial](https://docs.mongodb.com/manual/aggregation/).

```julia
docs = [
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
]

collection = client["my-database"]["aggregation-collection"]
append!(collection, docs)

# Sets the pipeline command
bson_pipeline = Mongoc.BSON("""
    [
        { "\$match" : { "status" : "A" } },
        { "\$group" : { "_id" : "\$cust_id", "total" : { "\$sum" : "\$amount" } } }
    ]
""")

for doc in Mongoc.aggregate(collection, bson_pipeline)
  println(doc)
end
```

The result of the script above is:

```julia
BSON("{ "_id" : "B212", "total" : 200 }")
BSON("{ "_id" : "A123", "total" : 750 }")
```

A **Map-Reduce** operation can be executed with `Mongoc.command_simple` or `Mongoc.read_command`.

```julia
input_collection_name = "aggregation-collection"
output_collection_name = "order_totals"
query = Mongoc.BSON("""{ "status" : "A" }""")

# use `Mongoc.BSONCode` to represent JavaScript elements in BSON
mapper = Mongoc.BSONCode(""" function() { emit( this.cust_id, this.amount ); } """)
reducer = Mongoc.BSONCode(""" function(key, values) { return Array.sum( values ) } """)

map_reduce_command = Mongoc.BSON()
map_reduce_command["mapReduce"] = input_collection_name
map_reduce_command["map"] = mapper
map_reduce_command["reduce"] = reducer
map_reduce_command["out"] = output_collection_name
map_reduce_command["query"] = query

result = Mongoc.read_command(database, map_reduce_command)
println(result)

for doc in Mongoc.find(database["order_totals"])
   println(doc)
end
```

The result of the script above is:

```julia
BSON("{ "result" : "order_totals", "timeMillis" : 135, "counts" : { "input" : 3, "emit" : 3, "reduce" : 1, "output" : 2 }, "ok" : 1.0 }")
BSON("{ "_id" : "A123", "value" : 750.0 }")
BSON("{ "_id" : "B212", "value" : 200.0 }")
```

## "distinct" command

This example demonstrates the `distinct` command,
based on [libmongoc docs](https://mongoc.org/libmongoc/current/distinct-mapreduce.html).

```julia
import Mongoc
client = Mongoc.Client()

docs = [
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
]

collection = client["my-database"]["my-collection"]
append!(collection, docs)

distinct_cmd = Mongoc.BSON()
distinct_cmd["distinct"] = "my-collection"
distinct_cmd["key"] = "status"

result = Mongoc.command_simple(client["my-database"], distinct_cmd)
```

Which yields:

```julia
BSON("{ "values" : [ "A", "D" ], "ok" : 1.0 }")
```

## Find and Modify

Use `Mongoc.find_and_modify` to query and update documents in a single pass.

```julia
#
# populate a new collection
#

collection = client["database_name"]["find_and_modify"]

docs = [
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
    Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
]

append!(collection, docs)

#
# updates the item with amount 5000 with status "N"
#
query = Mongoc.BSON("amount" => 500)

reply = Mongoc.find_and_modify(
    collection,
    query,
    update = Mongoc.BSON("""{ "\$set" : { "status" : "N" } }"""),
    flags = Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW # will return the new version of the document
)

modified_doc = reply["value"]
@test modified_doc["status"] == "N"

#
# UPSERT example: if the queried item is not found, it is created
#

query = Mongoc.BSON("""{ "cust_id" : "C555", "amount" : 10, "status" : "X" }""")

reply = Mongoc.find_and_modify(
    collection,
    query,
    update = Mongoc.BSON("""{ "\$set" : { "status" : "S" } }"""),
    flags = Mongoc.FIND_AND_MODIFY_FLAG_UPSERT | Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW
)

new_document = reply["value"]
@test new_document["cust_id"] == "C555"
@test new_document["amount"] == 10
@test new_document["status"] == "S"

#
# Update sorted with selected fields
#
query = Mongoc.BSON("""{ "amount" : { "\$lt" : 300 } }""")
update = Mongoc.BSON("""{ "\$set" : { "status" : "Z" } }""")
fields = Mongoc.BSON("""{ "amount" : 1, "status" : 1 }""")
sort = Mongoc.BSON("""{ "amount" : 1 }""")

reply = Mongoc.find_and_modify(
    collection,
    query,
    update=update,
    sort=sort,
    fields=fields,
    flags=Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW)

new_document = reply["value"]
@test new_document["amount"] == 10
@test new_document["status"] == "Z"
@test !haskey(new_document, "cust_id")
```

## Create Index

Use `Mongoc.write_command` to issue a `createIndexes` command to the database.

```julia
database = client[DB_NAME]
collection_name = "index_collection"
collection = database[collection_name]

let
    items = [
            Mongoc.BSON("_id" => 1, "group" => "g1"),
            Mongoc.BSON("_id" => 2, "group" => "g1"),
            Mongoc.BSON("_id" => 3, "group" => "g2")
        ]

    append!(collection, items)
end

create_indexes_cmd = Mongoc.BSON(
        "createIndexes" => collection_name,
        "indexes" => [ Mongoc.BSON("key" => Mongoc.BSON("group" => 1), "name" => "group_index") ]
    )
reply = Mongoc.write_command(database, create_indexes_cmd)
@assert reply["ok"] == 1
```

See also: https://mongoc.org/libmongoc/current/create-indexes.html.
