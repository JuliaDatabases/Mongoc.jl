
#
# Tests depend on a running server at localhost:27017,
# and will create a database named "mongoc".
#
# Start a fresh MongoDB instance with:
#
# ```
# $ mkdir db
# $ mongod --dbpath ./db
# ```
#

import Mongoc

using Test
using Dates

const DB_NAME = "mongoc"

@testset "MongoDB" begin

    client = Mongoc.Client()

    @testset "Destroy" begin
        cli = Mongoc.Client()
        db = cli["database"]
        coll = db["collection"]

        Mongoc.destroy!(coll)
        Mongoc.destroy!(db)
        Mongoc.destroy!(cli)
    end

    @testset "Types" begin
        bson = Mongoc.BSON()
        @test_throws Mongoc.BSONError Mongoc.Client("////invalid-url")

        try
            Mongoc.Client("////invalid-url")
        catch err
            @test isa(err, Mongoc.BSONError)
            io = IOBuffer()
            showerror(io, err)
        end

        @test client.uri.uri == "mongodb://localhost:27017"
        Mongoc.set_appname!(client, "Runtests")
        db = client[DB_NAME]
        coll = db["new_collection"]

        io = IOBuffer()
        show(io, bson)
        show(io, client)
        show(io, db)
        show(io, coll)
        show(io, Mongoc.BSONCode("function() = 1"))
        show(io, Mongoc.QUERY_FLAG_TAILABLE_CURSOR)

        #=
        # This test requires the mongo client to create unsupported values.
        # 
        @testset "reading" begin
            script = "db.types.drop(); db.types.insertOne({ undefined: undefined, regex: /a regex/ });"
            run(`mongo --eval "$(script)" $DB_NAME`)
            doc = Mongoc.find_one(db["types"])

            @test doc["undefined"] == Mongoc.BSONUnsupported(0x06)
            @test doc["regex"] == Mongoc.BSONUnsupported(0x0b)
        end
        =#
    end

    @testset "Connection" begin

        @testset "ping" begin
            bson_ping_result = Mongoc.ping(client)
            @test haskey(bson_ping_result, "ok")
            @test Mongoc.as_json(Mongoc.ping(client)) == """{ "ok" : 1.0 }"""
        end

        @testset "Server Status" begin
            bson_server_status = Mongoc.command_simple(client["admin"], Mongoc.BSON("""{ "serverStatus" : 1 }"""))
            println("Server Mongo Version: ", bson_server_status["version"])
        end

        @testset "error print" begin
            error_happened = false
            try
                Mongoc.command_simple(client["hey"], Mongoc.BSON("""{ "you" : 1 }"""))
            catch e
                println(IOBuffer(), e)
                error_happened = true
            end

            @test error_happened
        end

        @testset "new_collection" begin
            coll = client[DB_NAME]["new_collection"]

            @testset "Insert One with generated OID" begin
                io = IOBuffer()
                result = push!(coll, Mongoc.BSON("""{ "hello" : "world" }"""))
                @test isa(result, Mongoc.InsertOneResult)
                show(io, result)
                @test result.inserted_oid != nothing
                first_inserted_oid = result.inserted_oid
                @test result.reply["insertedCount"] == 1
                result = push!(coll, Mongoc.BSON("""{ "hey" : "you" }"""))
                show(io, result)
                @test result.inserted_oid != nothing
                @test result.inserted_oid != first_inserted_oid
                @test result.reply["insertedCount"] == 1
            end

            @testset "Insert One with custom OID" begin
                io = IOBuffer()
                bson = Mongoc.BSON("_id" => 123, "out" => "there")
                result = push!(coll, bson)
                show(io, result)
                @test result.inserted_oid == nothing
                @test result.reply["insertedCount"] == 1
            end

            bson = Mongoc.BSON()
            bson["hey"] = "you"

            bson["zero_date"] = DateTime(0)
            bson["date_2018"] = DateTime(2018)

            result = push!(coll, bson)
            @test result.reply["insertedCount"] == 1

            i = 0
            for bson in coll
                @test haskey(bson, "hello") || haskey(bson, "hey") || haskey(bson, "out")
                @test haskey(bson, "_id")
                i += 1
            end
            @test i == length(coll)

            i = 0
            for bson in Mongoc.find(coll, Mongoc.BSON("""{ "hello" : "world" }"""))
                i += 1
            end
            @test i == 1

            @testset "cursor in comprehension" begin
                bsons = [bson for bson in Mongoc.find(coll, Mongoc.BSON("""{ "hello" : "world" }"""))]
                @test length(bsons) == 1
                @test eltype(bsons) == Mongoc.BSON
            end

            @testset "collection in comprehension" begin
                bsons = [bson for bson in coll]
                @test length(bsons) == 4
                @test eltype(bsons) == Mongoc.BSON
            end

            @testset "collection command_simple" begin
                result = Mongoc.command_simple(coll, Mongoc.BSON("""{ "collStats" : "new_collection" }"""))
                @test result["ok"] == 1
            end

            empty!(coll)
        end

        @testset "find_databases" begin
            found = false
            for obj in Mongoc.find_databases(client)
                if obj["name"] == DB_NAME
                    found = true
                end
            end
            @test found

            @test DB_NAME ∈ Mongoc.get_database_names(client)
        end

        @testset "catch cursor error" begin
            # issue #15
            invalid_client = Mongoc.Client("mongodb://invalid_url")
            collection = invalid_client["db_name"]["collection_name"]
            @test_throws Mongoc.BSONError Mongoc.find_one(collection, Mongoc.BSON(""" { "a" : 1 } """))
        end

        @testset "cursor batch size" begin
            collection = client[DB_NAME]["batch_size_test"]
            cursor = Mongoc.find(collection)
            @test Mongoc.batch_size(cursor) == 0
            Mongoc.batch_size!(cursor, 10)
            @test Mongoc.batch_size(cursor) == 10
        end

        @static if !Sys.iswindows() # skipping binary tests for windows
            @testset "Binary data" begin
                coll = client[DB_NAME]["new_collection"]
                bsonDoc = Mongoc.BSON()
                testdata = rand(UInt8, 100)
                bsonDoc["someId"] = "1234"
                bsonDoc["bindata"] = testdata
                result = push!(coll, bsonDoc)
                @test result.reply["insertedCount"] == 1

                # read data out and confirm
                selector = Mongoc.BSON("""{ "someId": "1234" }""")
                results = Mongoc.find_one(coll,  selector)

                @test results["bindata"] == testdata
            end
        end

        @testset "find_collections" begin
            for obj in Mongoc.find_collections(client["local"])
                @test obj["name"] == "startup_log"
            end

            @test Mongoc.get_collection_names(client["local"]) == [ "startup_log" ]
        end

        @testset "BulkOperation" begin
            coll = client[DB_NAME]["new_collection"]
            bulk_operation = Mongoc.BulkOperation(coll)
            Mongoc.destroy!(bulk_operation)
            bulk_2 = Mongoc.BulkOperation(coll) # will be freed by GC
        end

        @testset "Cleanup" begin
            coll = client[DB_NAME]["new_collection"]
            Mongoc.drop(coll)
        end

        @testset "insert_many" begin
            collection = client[DB_NAME]["insert_many"]
            vector = Vector{Mongoc.BSON}()
            push!(vector, Mongoc.BSON("""{ "hey" : "you" }"""))
            push!(vector, Mongoc.BSON("""{ "out" : "there" }"""))
            push!(vector, Mongoc.BSON("""{ "count" : 3 }"""))

            result = append!(collection, vector)
            @test isa(result, Mongoc.BulkOperationResult)
            @test result.reply["nInserted"] == 3
            for oid in result.inserted_oids
                @test oid != nothing
            end
            io = IOBuffer()
            show(io, result)
            @test length(collection) == 3
            @test length(collect(collection)) == 3

            Mongoc.drop(collection)
        end

        @testset "bulk_replace_one" begin
            collection = client[DB_NAME]["replace_many"]
            push!(collection, Mongoc.BSON("""{ "x": 1, "y": 100 }"""))
            push!(collection, Mongoc.BSON("""{ "x": 2, "y": 200 }"""))
            push!(collection, Mongoc.BSON("""{ "x": 3, "y": 300 }"""))

            bulk = Mongoc.BulkOperation(collection)
            Mongoc.bulk_replace_one!(
                bulk,
                Mongoc.BSON("""{ "x": 1 }"""),
                Mongoc.BSON("""{ "x": 1, "y": -100 }"""),
            )
            Mongoc.bulk_replace_one!(
                bulk,
                Mongoc.BSON("""{ "x": 2 }"""),
                Mongoc.BSON("""{ "x": 2, "y": -200 }"""),
            )
            Mongoc.bulk_replace_one!(
                bulk,
                Mongoc.BSON("""{ "x": 4 }"""),
                Mongoc.BSON("""{ "x": 4, "y": 400 }""");
                options = Mongoc.BSON("""{ "upsert": true }""")
            )
            result = Mongoc.execute!(bulk)
            @test result.reply["nInserted"] == 0
            @test result.reply["nMatched"] == 2
            @test result.reply["nModified"] == 2
            @test result.reply["nUpserted"] == 1
            @test length(collection) == 4
            @test length(collect(collection)) == 4

            Mongoc.drop(collection)
        end

        @testset "bulk_update_one" begin
            collection = client[DB_NAME]["bulk_update_one"]
            push!(collection, Mongoc.BSON("""{ "x": 1, "y": 100 }"""))
            push!(collection, Mongoc.BSON("""{ "x": 2, "y": 200 }"""))

            bulk = Mongoc.BulkOperation(collection)
            Mongoc.bulk_update_one!(
                bulk,
                Mongoc.BSON("""{ "x": 1 }"""),
                Mongoc.BSON("""{ "\$set": { "y": 150 } }"""),
            )
            Mongoc.bulk_update_one!(
                bulk,
                Mongoc.BSON("""{ "x": 2 }"""),
                Mongoc.BSON("""{ "\$inc": { "y": 13 } }"""),
            )
            result = Mongoc.execute!(bulk)
            @test result.reply["nInserted"] == 0
            @test result.reply["nMatched"] == 2
            @test result.reply["nModified"] == 2
            @test result.reply["nUpserted"] == 0
            @test length(collection) == 2
            @test length(collect(collection)) == 2
            x1 = Mongoc.find_one(collection, Mongoc.BSON("x" => 1))
            @test x1["x"] == 1
            @test x1["y"] == 150
            x2 = Mongoc.find_one(collection, Mongoc.BSON("x" => 2))
            @test x2["x"] == 2
            @test x2["y"] == 213

            Mongoc.drop(collection)
        end

        @testset "delete_one" begin
            collection = client[DB_NAME]["delete_one"]
            doc = Mongoc.BSON("""{ "to" : "delete", "hey" : "you" }""")
            doc2 = Mongoc.BSON("""{ "to" : "keep", "out" : "there" }""")
            insert_result = push!(collection, doc)
            oid = insert_result.inserted_oid
            push!(collection, doc2)

            selector = Mongoc.BSON()
            selector["_id"] = oid
            @test length(collection, selector) == 1
            result = Mongoc.delete_one(collection, selector)
            @test result["deletedCount"] == 1
            @test length(collection, selector) == 0

            Mongoc.drop(collection)
        end

        @testset "delete_many" begin
            collection = client[DB_NAME]["delete_many"]
            result = append!(collection, [ Mongoc.BSON("""{ "first" : 1, "delete" : true }"""), Mongoc.BSON("""{ "second" : 2, "delete" : true }"""), Mongoc.BSON("""{ "third" : 3, "delete" : false }""") ])
            @test length(collection) == 3
            result = Mongoc.delete_many(collection, Mongoc.BSON("""{ "delete" : true }"""))
            @test result["deletedCount"] == 2
            @test length(collection) == 1
            result = Mongoc.delete_many(collection, Mongoc.BSON())
            @test result["deletedCount"] == 1
            @test isempty(collection)
            Mongoc.drop(collection)
        end

        @testset "update_one, update_many" begin
            collection = client[DB_NAME]["update_one"]
            append!(collection, [ Mongoc.BSON("""{ "first" : 1, "delete" : true }"""), Mongoc.BSON("""{ "second" : 2, "delete" : true }"""), Mongoc.BSON("""{ "third" : 3, "delete" : false }""") ])
            @test length(collection) == 3

            selector = Mongoc.BSON("""{ "delete" : false }""")
            update = Mongoc.BSON("""{ "\$set" : { "delete" : true, "new_field" : 1 } }""")
            result = Mongoc.update_one(collection, selector, update)

            @test result["modifiedCount"] == 1
            @test result["matchedCount"] == 1
            @test result["upsertedCount"] == 0

            updated_bson = Mongoc.find_one(collection, Mongoc.BSON("""{ "third" : 3 }"""))
            @test updated_bson != nothing
            @test updated_bson["delete"] == true
            @test updated_bson["new_field"] == 1

            selector = Mongoc.BSON("""{ "delete" : true }""")
            update = Mongoc.BSON("""{ "\$set" : { "delete" : false } }""")
            result = Mongoc.update_many(collection, selector, update)
            @test result["modifiedCount"] == 3
            @test result["matchedCount"] == 3
            @test result["upsertedCount"] == 0

            for doc in Mongoc.find(collection)
                @test doc["delete"] == false
            end

            @test Mongoc.find_one(collection, Mongoc.BSON("""{ "delete" : true }""")) == nothing

            Mongoc.drop(collection)
        end

        @testset "replace_one" begin
            collection = client[DB_NAME]["replace_one"]
            append!(collection, [ Mongoc.BSON("""{ "first" : 1, "delete" : true }"""), Mongoc.BSON("""{ "second" : 2, "delete" : true }"""), Mongoc.BSON("""{ "third" : 3, "delete" : false }""") ])
            @test length(collection) == 3

            selector = Mongoc.BSON("""{ "delete" : false }""")
            replacement = Mongoc.BSON("""{ "third" : 3, "new_field" : 1 }""")
            result = Mongoc.replace_one(collection, selector, replacement)

            @test result["modifiedCount"] == 1
            @test result["matchedCount"] == 1
            @test result["upsertedCount"] == 0

            replaced_bson = Mongoc.find_one(collection, Mongoc.BSON("""{ "third" : 3 }"""))
            @test replaced_bson !== nothing
            @test !haskey(replaced_bson, "delete")
            @test replaced_bson["new_field"] == 1

            Mongoc.drop(collection)
        end

        @testset "aggregation, map_reduce" begin

            @testset "QueryFlags" begin
                qf_composite = Mongoc.QUERY_FLAG_PARTIAL | Mongoc.QUERY_FLAG_NO_CURSOR_TIMEOUT
                @test qf_composite & Mongoc.QUERY_FLAG_PARTIAL == Mongoc.QUERY_FLAG_PARTIAL
                @test qf_composite & Mongoc.QUERY_FLAG_NO_CURSOR_TIMEOUT == Mongoc.QUERY_FLAG_NO_CURSOR_TIMEOUT
            end

            # reproducing the examples at https://docs.mongodb.com/manual/aggregation/
            docs = [
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
            ]

            database = client[DB_NAME]
            collection = database["aggregation_example"]
            append!(collection, docs)
            @test length(collection) == 4

            # Aggregation
            let
                bson_pipeline = Mongoc.BSON("""
                    [
                        { "\$match" : { "status" : "A" } },
                        { "\$group" : { "_id" : "\$cust_id", "total" : { "\$sum" : "\$amount" } } }
                    ]""")

                # Response should be
                #   BSON("{ "_id" : "B212", "total" : 200 }")
                #   BSON("{ "_id" : "A123", "total" : 750 }")
                for doc in Mongoc.aggregate(collection, bson_pipeline)
                    if doc["_id"] == "A123"
                        @test doc["total"] == 750
                    elseif doc["_id"] == "B212"
                        @test doc["total"] == 200
                    else
                        # shouldn't get in here
                        @test false
                    end
                end
            end

            # map_reduce
            let
                input_collection_name = "aggregation_example"
                mapper = Mongoc.BSONCode(""" function() { emit( this.cust_id, this.amount ); } """)
                reducer = Mongoc.BSONCode(""" function(key, values) { return Array.sum( values ) } """)
                output_collection_name = "order_totals"
                query = Mongoc.BSON("""{ "status" : "A" }""")

                map_reduce_command = Mongoc.BSON()
                map_reduce_command["mapReduce"] = input_collection_name
                map_reduce_command["map"] = mapper
                map_reduce_command["reduce"] = reducer
                map_reduce_command["out"] = output_collection_name
                map_reduce_command["query"] = query

                result = Mongoc.read_command(database, map_reduce_command)
                @test result["result"] == "order_totals"
                @test result["ok"] == 1.0

                for doc in Mongoc.find(database["order_totals"])
                   if doc["_id"] == "A123"
                        @test doc["value"] == 750
                    elseif doc["_id"] == "B212"
                        @test doc["value"] == 200
                    else
                        # shouldn't get in here
                        @test false
                    end
                end

               # Response should be
               # BSON("{ "_id" : "A123", "value" : 750.0 }")
               # BSON("{ "_id" : "B212", "value" : 200.0 }")
            end

            Mongoc.drop(collection)
        end
    end

    @testset "find and modify" begin
        @testset "create/destroy opts" begin
            opts = Mongoc.FindAndModifyOptsBuilder()
            Mongoc.destroy!(opts)
        end

        @testset "set opts" begin
            opts = Mongoc.FindAndModifyOptsBuilder()
            opts.update = Mongoc.BSON("""{ "\$set" : { "position" : "striker" }}""")
            opts.sort = Mongoc.BSON("""{ "age" : -1 }""")
            opts.fields = Mongoc.BSON("""{ "goals" : 1 }""")
            opts.flags = Mongoc.FIND_AND_MODIFY_FLAG_UPSERT | Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW
        end

        @testset "main function" begin
            collection = client[DB_NAME]["find_and_modify"]

            docs = [
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
                Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
            ]

            append!(collection, docs)

            @testset "update simple" begin
                query = Mongoc.BSON("amount" => 500)

                reply = Mongoc.find_and_modify(
                    collection,
                    query,
                    update = Mongoc.BSON("""{ "\$set" : { "status" : "N" } }"""),
                    flags = Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW # will return the new version of the document
                )

                let
                    modified_doc = reply["value"]
                    @test modified_doc["status"] == "N"
                end

                let
                    modified_doc = Mongoc.find_one(collection, Mongoc.BSON("amount" => 500))
                    @test modified_doc["status"] == "N"
                end
            end

            @testset "upsert and return new" begin
                query = Mongoc.BSON("""{ "cust_id" : "C555", "amount" : 10, "status" : "X" }""")

                reply = Mongoc.find_and_modify(
                    collection,
                    query,
                    update = Mongoc.BSON("""{ "\$set" : { "status" : "S" } }"""),
                    flags = Mongoc.FIND_AND_MODIFY_FLAG_UPSERT | Mongoc.FIND_AND_MODIFY_FLAG_RETURN_NEW
                )

                let
                    new_document = reply["value"]
                    @test new_document["cust_id"] == "C555"
                    @test new_document["amount"] == 10
                    @test new_document["status"] == "S"
                end
            end

            @testset "update sorted with selected fields" begin
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

                let
                    new_document = reply["value"]
                    @test new_document["amount"] == 10
                    @test new_document["status"] == "Z"
                    @test !haskey(new_document, "cust_id")
                end
            end

            Mongoc.drop(collection)
        end
    end

    @testset "find one and delete" begin
        collection = client[DB_NAME]["find_one_and_delete"]

        docs = [
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
        ]

        append!(collection, docs)

        @testset "delete by filter" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")

            doc = Mongoc.find_one_and_delete(collection, query)

            @test !isnothing(doc)
            @test doc["cust_id"] == "B212"
            @test doc["amount"] == 200
        end

        @testset "nothing result when not found" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")

            doc = Mongoc.find_one_and_delete(collection, query)

            @test isnothing(doc)
        end

        @testset "delete with sort" begin
            query = Mongoc.BSON("""{ "cust_id" : "A123" }""")
            options = Mongoc.BSON("""{ "sort" : {"amount" : 1 } }""")

            doc = Mongoc.find_one_and_delete(collection, query, options=options)

            @test !isnothing(doc)
            @test doc["cust_id"] == "A123"
            @test doc["amount"] == 250
        end

        @testset "delete with projection" begin
            query = Mongoc.BSON("""{ "cust_id" : "A123" }""")
            options = Mongoc.BSON("""{ "projection": { "amount" : 0 } }""")

            doc = Mongoc.find_one_and_delete(collection, query, options=options)

            @test !isnothing(doc)
            @test doc["cust_id"] == "A123"
            @test !haskey(doc, "amount")
        end

        Mongoc.drop(collection)
    end

    @testset "find one and replace" begin
        collection = client[DB_NAME]["find_one_and_replace"]

        docs = [
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
        ]

        append!(collection, docs)

        @testset "replace by filter" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")
            replacement = Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "B" }""")

            doc = Mongoc.find_one_and_replace(collection, query, replacement)

            @test doc["cust_id"] == "B212"
            @test doc["amount"] == 200
            # Returns original document
            @test doc["status"] == "A"
        end

        @testset "replace with sort" begin
            query = Mongoc.BSON("""{ "cust_id" : "A123" }""")
            replacement = Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 275, "status" : "B" }""")
            options = Mongoc.BSON("""{ "sort" : {"amount": 1 } }""")

            doc = Mongoc.find_one_and_replace(collection, query, replacement, options=options)

            @test doc["cust_id"] == "A123"
            @test doc["amount"] == 250
            # Returns original document
            @test doc["status"] == "A"
        end

        @testset "return new document" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")
            replacement = Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "C" }""")
            options = Mongoc.BSON("""{ "returnNewDocument" : true }""")

            doc = Mongoc.find_one_and_replace(collection, query, replacement, options=options)

            @test doc["cust_id"] == "B212"
            @test doc["amount"] == 200
            # Returns new document
            @test doc["status"] == "C"
        end

        @testset "returns nothing if it does not exist" begin
            query = Mongoc.BSON("""{ "cust_id" : "C313" }""")
            replacement = Mongoc.BSON("""{ "cust_id" : "C313", "amount" : 400, "status" : "A" }""")

            doc = Mongoc.find_one_and_replace(collection, query, replacement)
            @test isnothing(doc)
        end

        @testset "returns nothing if it does not exist and returning new document" begin
            query = Mongoc.BSON("""{ "cust_id" : "C313" }""")
            replacement = Mongoc.BSON("""{ "cust_id" : "C313", "amount" : 400, "status" : "A" }""")
            options = Mongoc.BSON("""{ "returnNewDocument" : true }""")

            doc = Mongoc.find_one_and_replace(collection, query, replacement, options=options)
            @test isnothing(doc)
        end

        @testset "upsert" begin
            query = Mongoc.BSON("""{ "cust_id" : "C313" }""")
            replacement = Mongoc.BSON("""{ "cust_id" : "C313", "amount" : 400, "status" : "A" }""")
            options = Mongoc.BSON("""{ "upsert" : true }""")

            doc = Mongoc.find_one_and_replace(collection, query, replacement, options=options)
            @test isnothing(doc)

            replacement = Mongoc.BSON("""{ "cust_id" : "C313", "amount" : 400, "status" : "B" }""")
            doc = Mongoc.find_one_and_replace(collection, query, replacement, options=options)
            @test !isnothing(doc)
        end

        @testset "throws if operator in replacement" begin
            query = Mongoc.BSON("""{"cust_id" : "B212"}""")
            replacement = Mongoc.BSON("""{ "\$set" : {"cust_id" : "B212", "amount" : 200, "status" : "C" } }""")

            @test_throws ArgumentError Mongoc.find_one_and_replace(collection, query, replacement)
        end

        Mongoc.drop(collection)
    end

    @testset "find one and update" begin
        collection = client[DB_NAME]["find_one_and_update"]

        docs = [
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 500, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 250, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "A" }"""),
            Mongoc.BSON("""{ "cust_id" : "A123", "amount" : 300, "status" : "D" }""")
        ]

        append!(collection, docs)

        @testset "update by filter" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")
            update = Mongoc.BSON("""{"\$set" : { "status" : "B" } }""")

            doc = Mongoc.find_one_and_update(collection, query, update)

            @test doc["cust_id"] == "B212"
            @test doc["amount"] == 200
            # Returns original document
            @test doc["status"] == "A"
        end

        @testset "update with sort" begin
            query = Mongoc.BSON("""{ "cust_id" : "A123" }""")
            update = Mongoc.BSON("""{ "\$set" : { "status" : "B", "amount" : 275 } }""")
            options = Mongoc.BSON("""{ "sort": {"amount": 1 } }""")

            doc = Mongoc.find_one_and_update(collection, query, update, options=options)

            @test doc["cust_id"] == "A123"
            @test doc["amount"] == 250
            # Returns original document
            @test doc["status"] == "A"
        end

        @testset "return new document" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")
            update = Mongoc.BSON("""{ "\$set" : { "status" : "C" } }""")
            options = Mongoc.BSON("""{ "returnNewDocument" : true}""")

            doc = Mongoc.find_one_and_update(collection, query, update, options=options)

            @test doc["cust_id"] == "B212"
            @test doc["amount"] == 200
            # Returns new document
            @test doc["status"] == "C"
        end

        @testset "returns nothing if it does not exist" begin
            query = Mongoc.BSON("""{ "cust_id" : "C313" }""")
            update = Mongoc.BSON("""{ "\$set" : { "cust_id" : "C313", "amount" : 400, "status" : "A" } }""")

            doc = Mongoc.find_one_and_update(collection, query, update)
            @test isnothing(doc)
        end

        @testset "returns nothing if it does not exist and returning new document" begin
            query = Mongoc.BSON("""{ "cust_id" : "C313" }""")
            update = Mongoc.BSON("""{ "\$set" : { "cust_id" : "C313", "amount" : 400, "status" : "A" } }""")
            options = Mongoc.BSON("""{ "returnNewDocument" : true }""")

            doc = Mongoc.find_one_and_update(collection, query, update, options=options)
            @test isnothing(doc)
        end

        @testset "upsert" begin
            query = Mongoc.BSON("""{ "cust_id" : "C313" }""")
            update = Mongoc.BSON("""{ "\$setOnInsert" : { "cust_id" : "C313", "amount" : 400 }, "\$set" : { "status" : "A" } }""")
            options = Mongoc.BSON("""{ "upsert" : true }""")

            doc = Mongoc.find_one_and_update(collection, query, update, options=options)
            @test isnothing(doc)

            update = Mongoc.BSON("""{ "\$setOnInsert" : { "cust_id" : "C313", "amount" : 400 }, "\$set" : { "status" : "B" } }""")
            doc = Mongoc.find_one_and_update(collection, query, update, options=options)
            @test !isnothing(doc)
        end

        @testset "throws if no operator in update" begin
            query = Mongoc.BSON("""{ "cust_id" : "B212" }""")
            update = Mongoc.BSON("""{ "cust_id" : "B212", "amount" : 200, "status" : "C" }""")

            @test_throws ArgumentError Mongoc.find_one_and_update(collection, query, update)
        end

        Mongoc.drop(collection)
    end

    @testset "command" begin
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
            @test length(collection) == 3
        end

        @testset "database write_command" begin
            create_indexes_cmd = Mongoc.BSON(
                    "createIndexes" => collection_name,
                    "indexes" => [ Mongoc.BSON("key" => Mongoc.BSON("group" => 1), "name" => "group_index") ]
                )
            reply = Mongoc.write_command(database, create_indexes_cmd)
            @test reply["ok"] == 1
        end

        @testset "database read_command" begin
            reply = Mongoc.read_command(client["admin"], Mongoc.BSON("""{ "serverStatus" : 1 }"""))
            @test reply["ok"] == 1
        end

        Mongoc.drop(collection)
    end

    @testset "Users" begin
        # creates admin user - https://docs.mongodb.com/manual/tutorial/enable-authentication/
        @test Mongoc.has_database(client, DB_NAME) # at this point, DB_NAME should exist
        database = client[DB_NAME]

        user_name = "myUser"
        pass = "abc123"
        roles = Mongoc.BSON()

        if Mongoc.has_user(database, user_name)
            Mongoc.remove_user(database, user_name)
        end

        Mongoc.add_user(database, user_name, pass, roles)
        Mongoc.remove_user(database, user_name)
        @test !Mongoc.has_user(database, user_name)
    end

    @testset "Session Options" begin
        opt = Mongoc.SessionOptions()
        try
            @test Mongoc.get_casual_consistency(opt)
            Mongoc.set_casual_consistency!(opt, false)
            @test !Mongoc.get_casual_consistency(opt)
        finally
            Mongoc.destroy!(opt)
        end
        @test opt.handle == C_NULL
        @test Mongoc.destroy!(opt) === nothing
    end

    server_version = Mongoc.get_server_mongodb_version(client)

    if server_version < v"3.6"
        @warn("MongoDB server version $server_version does not support Sessions. Skipping tests.")
    else
        @testset "Session" begin
            session = Mongoc.Session(client)
            try
                db = session[DB_NAME]
                collection = db["session_collection"]
                push!(collection, Mongoc.BSON("""{ "try-insert" : 1 }"""))
                Mongoc.drop(collection)
            finally
                Mongoc.destroy!(session)
                Mongoc.destroy!(session.options)
            end
            @test session.handle == C_NULL
            @test session.options.handle == C_NULL
            @test Mongoc.destroy!(session) === nothing
        end
    end

    @testset "Drop Database" begin
        Mongoc.drop(client[DB_NAME])
    end

    @testset "GridFS" begin
        @testset "Create/Destroy" begin
            db = client[DB_NAME]
            bucket = Mongoc.Bucket(db)
            Mongoc.destroy!(bucket)
        end

        @testset "Stream from filepath" begin
            fp = joinpath(@__DIR__, "replica_set_initiate.js")
            @assert isfile(fp)
            io = Mongoc.MongoStreamFile(fp)
            @test isopen(io)
            Mongoc.close(io)
            @test !isopen(io)
            Mongoc.destroy!(io)
        end

        @testset "Upload/Download/Find/Delete file" begin
            db = client[DB_NAME]
            bucket = Mongoc.Bucket(db)
            local_fp = joinpath(@__DIR__, "replica_set_initiate.js")
            @assert isfile(local_fp)
            original_str = read(local_fp, String)

            remote_filename = "remote_replica_set_initiate.js"

            @testset "Upload" begin
                Mongoc.upload(bucket, remote_filename, local_fp)
            end

            @test !isempty(bucket)

            download_filepath = joinpath(@__DIR__, "tmp_replica_set_initiate.js")


            @testset "Download to file" begin
                try
                    Mongoc.download(bucket, remote_filename, download_filepath)

                    let
                        tmp_str = read(download_filepath, String)
                        @test original_str == tmp_str
                    end
                finally
                    isfile(download_filepath) && rm(download_filepath)
                end
            end

            @testset "transfer_to_buffer!" begin
                @testset "empty buffer" begin
                    buff = UInt8[]
                    pos = 0
                    data = UInt8[1,2,0,0]
                    nr = 2

                    @test Mongoc.nb_free(buff, pos) == 0
                    @test Mongoc.nb_to_fill(buff, pos, nr) == 0
                    @test Mongoc.nb_to_append(buff, pos, nr) == 2
                    Mongoc.transfer_to_buffer!(buff, pos, data, nr)
                    @test buff == UInt8[1,2]
                end

                @testset "increase buffer" begin
                    buff = UInt8[1,2,0,0]
                    pos = 2
                    data = UInt8[3,4,5,6]
                    nr = 3
                    @test Mongoc.nb_free(buff, pos) == 2
                    @test Mongoc.nb_to_fill(buff, pos, nr) == 2
                    @test Mongoc.nb_to_append(buff, pos, nr) == 1
                    Mongoc.transfer_to_buffer!(buff, pos, data, nr)
                    @test buff == UInt8[1,2,3,4,5]
                end

                @testset "big buffer" begin
                    buff = UInt8[1,0,0,0]
                    pos = 1
                    data = UInt8[2,3,4,5]
                    nr = 1
                    Mongoc.transfer_to_buffer!(buff, pos, data, nr)
                    @test buff == UInt8[1,2,0,0]
                end
            end

            @testset "Download to stream" begin
                Mongoc.open_download_stream(bucket, remote_filename) do io
                    @test isopen(io)
                    tmp_str = read(io, String)
                    @test original_str == tmp_str
                end
            end

            @testset "Find and Delete" begin
                cursor = Mongoc.find(bucket)
                found = false
                for doc in cursor
                    @test !found
                    found = true

                    @test doc["filename"] == remote_filename
                    Mongoc.delete(bucket, doc)
                end

                @test isempty(bucket)
            end

            @testset "Upload and Delete with id" begin

                Mongoc.upload(bucket, remote_filename, local_fp, file_id="my_id")

                found = false
                for doc in Mongoc.find(bucket, Mongoc.BSON("_id" => "my_id"))
                    found = true
                end
                @test found

                @test !isempty(bucket)
                empty!(bucket)
                @test isempty(bucket)
            end

            @testset "open upload stream - text" begin
                remote_filename = "uploaded_file.txt"

                io = Mongoc.open_upload_stream(bucket, remote_filename)
                msg = "hey you out there"
                write(io, msg)
                close(io)

                Mongoc.open_download_stream(bucket, remote_filename) do io
                    @test isopen(io)
                    tmp_str = read(io, String)
                    @test msg == tmp_str
                end

                empty!(bucket)
            end

            @testset "open upload stream - bytes" begin
                data = rand(UInt8, 3_000_000)
                remote_filename = "uploaded.data"
                io = Mongoc.open_upload_stream(bucket, remote_filename)
                write(io, data)
                close(io)

                Mongoc.open_download_stream(bucket, remote_filename) do io
                    @test isopen(io)
                    downloaded_data = read(io)
                    @test downloaded_data == data
                end

                empty!(bucket)
            end

            @testset "upload abort" begin
                remote_filename = "uploaded_file.txt"

                io = Mongoc.open_upload_stream(bucket, remote_filename)
                msg = "hey you out there"
                write(io, msg)
                Mongoc.abort_upload(io)
                close(io)
                @test isempty(bucket)
            end
        end
    end
end
