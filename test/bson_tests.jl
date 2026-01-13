
import Mongoc

import Base.UUID
using Test
using Dates
using DecFP
using Distributed

@testset "BSON" begin

    @testset "as_json" begin
        @test_throws ErrorException Mongoc.BSON(""" { ajskdla sdjsafd } """)
        bson = Mongoc.BSON("""{"hey" : 1}""")
        @test bson["hey"] == 1
        @test Mongoc.as_json(bson) == """{ "hey" : 1 }"""
        @test Mongoc.as_json(bson, canonical=true) == """{ "hey" : { "\$numberInt" : "1" } }"""
    end

    @testset "oid conversion" begin
        str = "5b9fb22b3192e3fa155693a1"
        local oid::Mongoc.BSONObjectId = str
        @test String(oid) == str
    end

    @testset "oid compare" begin
        x = Mongoc.BSONObjectId()
        y = Mongoc.BSONObjectId()
        @test x != y
        @test x == x
        @test y == y
        @test hash(x) == hash(x)
        @test hash(y) == hash(y)
        @test hash(x) != hash(y)
        @test Mongoc.bson_oid_compare(x, y) < 0
        @test Mongoc.bson_oid_compare(y, x) > 0
        @test Mongoc.bson_oid_compare(x, x) == 0
        @test Mongoc.bson_oid_compare(y, y) == 0
    end

    @testset "oid copy" begin
        x = Mongoc.BSONObjectId()
        y = copy(x)
        @test x == y
        @test hash(x) == hash(y)
        @test Mongoc.bson_oid_compare(x, y) == 0
    end

    @testset "oid string" begin
        x = Mongoc.BSONObjectId()
        y = Mongoc.BSONObjectId(String(x))
        @test x == y

        @test_throws ErrorException Mongoc.BSONObjectId("invalid_objectid")
    end

    @testset "oid time" begin
        Mongoc.get_time( Mongoc.BSONObjectId("5b9eaa2711c3dd0d6a46a5c4") ) == DateTime(2018, 9, 16, 19, 8, 23) # 2018-09-16T19:08:23
    end

    @testset "BSONObjectId segfault issue (#2)" begin
        io = IOBuffer()
        v = Vector{Mongoc.BSONObjectId}()

        for i in 1:5
            push!(v, Mongoc.BSONObjectId())
        end
        show(io, v)
    end

    @testset "oid sort" begin
        v = Vector{Mongoc.BSONObjectId}()
        for i in 1:10_000
            push!(v, Mongoc.BSONObjectId())
        end
        @test length(v) == length(unique(v))

        v_sorted = sort(v, lt = (a,b) -> Mongoc.bson_oid_compare(a,b) < 0)
        @test v_sorted == v
    end

    @testset "AbstractString support" begin
        keys_with_prefix = ["aKey1", "aKey2", "aKey3"]
        substring_keys = [ SubString(k, 2, length(k)) for k in keys_with_prefix ]
        vals = [ 1, "hey", nothing ]

        bson = Mongoc.BSON()
        for (i, k) in enumerate(substring_keys)
            bson[k] = vals[i]
        end

        for k in substring_keys
            @test haskey(bson, k)
        end

        for i in 1:3
            @test haskey(bson, "Key$i")
        end

        bson["ah"] = substring_keys[1]
        @test isa(bson["ah"], String)
        @test bson["ah"] == "Key1"
    end

    @testset "UUID support" begin
        uuid = UUID("a1f18b06-2210-499b-8313-28e69090511f")
        uuid_bytes = [0xa1, 0xf1, 0x8b, 0x06, 0x22, 0x10, 0x49, 0x9b, 0x83, 0x13, 0x28, 0xe6, 0x90, 0x90, 0x51, 0x1f]
        bson = Mongoc.BSON("uuid" => uuid)
        Mongoc.bson_append_binary(bson.handle, "uuid2", -1, Mongoc.BSON_SUBTYPE_UUID, uuid_bytes, UInt32(16))
        @test isa(bson["uuid"], UUID)
        @test bson["uuid"] == uuid
        @test isa(bson["uuid2"], UUID)
        @test bson["uuid2"] == uuid
    end

    @testset "Binary data iteration (#145)" begin
        # This would segfault on Julia 1.12 before the enum size fix
        b = Mongoc.BSON("a" => UInt8[0x1, 0x2, 0x3])

        # Test iteration
        result = iterate(b)
        @test result !== nothing
        (pair, state) = result
        @test pair.first == "a"
        @test pair.second == UInt8[0x1, 0x2, 0x3]

        # Test Dict conversion (uses iteration internally)
        d = Dict(b)
        @test d["a"] == UInt8[0x1, 0x2, 0x3]

        # Test as_dict
        d2 = Mongoc.as_dict(b)
        @test d2["a"] == UInt8[0x1, 0x2, 0x3]
    end

    @testset "BSON key/values itr support" begin
        bson = Mongoc.BSON()
        bson["hey"] = 10
        bson["you"] = "aaa"
        bson["out"] = nothing

        @test ["hey" => 10, "you" => "aaa", "out" => nothing] == [k => v for (k, v) in bson]
        @test ["hey" => 10, "you" => "aaa", "out" => nothing] == collect(pairs(bson))

        @test ["hey", "you", "out"] == collect(keys(bson))

        @test [10, "aaa", nothing] == collect(values(bson))
    end

    @testset "BSON Iterator" begin
        doc = Mongoc.BSON("""{ "a" : 1, "b" : 2.2, "str" : "my string", "bool_t" : true, "bool_f" : false, "array" : [1, 2, false, "inner_string"], "float_array" : [0.1, 0.2, 0.3, 0.4], "document" : { "a" : 1, "b" : "b_string"}, "null" : null  }""")

        new_id = Mongoc.BSONObjectId()
        doc["_id"] = new_id

        @test haskey(doc, "a")
        @test haskey(doc, "b")
        @test !haskey(doc, "c")
        @test haskey(doc, "str")
        @test haskey(doc, "_id")
        @test haskey(doc, "array")
        @test haskey(doc, "float_array")
        @test haskey(doc, "document")
        @test haskey(doc, "null")

        @test doc["a"] == 1
        @test doc["b"] == 2.2
        @test doc["str"] == "my string"
        @test doc["bool_t"]
        @test !doc["bool_f"]
        @test doc["_id"] == new_id
        @test doc["array"] == [1, 2, false, "inner_string"]
        @test doc["document"] == Dict("a"=>1, "b"=>"b_string")
        @test doc["null"] == nothing

        @test_throws KeyError doc["invalid key"]
        @test isequal(get(doc, "invalid key", missing), missing)
        @test get(doc, "_id", missing) == new_id

        doc_dict = Mongoc.as_dict(doc)
        @test keytype(doc_dict) === String
        @test doc_dict["a"] == 1
        @test doc_dict["b"] == 2.2
        @test doc_dict["str"] == "my string"
        @test doc_dict["bool_t"]
        @test !doc_dict["bool_f"]
        @test doc_dict["_id"] == new_id
        @test doc_dict["array"] == [1, 2, false, "inner_string"]
        @test doc_dict["document"] == Dict("a"=>1, "b"=>"b_string")
        @test doc_dict["null"] == nothing

        @testset "convert(Dict, BSON)" begin
            doc_dict2 = @inferred(convert(Dict, doc))
            @test doc_dict2 == doc_dict
            doc_dict3 = @inferred(convert(Dict{String, Any}, doc))
            @test doc_dict3 == doc_dict
        end

        # Type-stable API
        @test @inferred(Mongoc.get_array(doc, "float_array", Float64)) == [0.1, 0.2, 0.3, 0.4]
        @test @inferred(Mongoc.get_array(doc, "float_array", Float32)) == Float32[0.1, 0.2, 0.3, 0.4]

        @test_throws MethodError Mongoc.get_array(doc, "float_array", String)
        @test_throws ErrorException Mongoc.get_array(doc, "document", Any)
    end

    @testset "BSON write" begin
        bson = Mongoc.BSON()
        new_oid = Mongoc.BSONObjectId()
        bson["_id"] = new_oid
        bson["int32"] = Int32(10)
        bson["int64"] = Int64(20)
        bson["string"] = "hey you"
        bson["bool_true"] = true
        bson["bool_false"] = false
        bson["double"] = 2.3
        bson["decimal128"] = d128"1.2"
        bson["datetime"] = DateTime(2018, 2, 1, 10, 20, 35, 10)
        bson["vector"] = collect(1:10)
        bson["source"] = Mongoc.BSONCode("function() = 1")
        bson["null"] = nothing
        @test_throws ErrorException bson["key"] = Date(2018, 9, 18)
        str = "the real string"
        sub = SubString(str, 4, 7)
        bson["substring"] = sub

        let
            sub_bson = Mongoc.BSON()
            sub_bson["hey"] = "you"
            sub_bson["num"] = 10
            bson["sub_document"] = sub_bson
        end

        @test bson["_id"] == new_oid
        @test bson["int32"] == Int32(10)
        @test bson["int64"] == Int64(20)
        @test bson["string"] == "hey you"
        @test bson["bool_true"]
        @test !bson["bool_false"]
        @test bson["double"] == 2.3
        @test bson["decimal128"] == d128"1.2"
        @test bson["datetime"] == DateTime(2018, 2, 1, 10, 20, 35, 10)
        @test bson["sub_document"]["hey"] == "you"
        @test bson["sub_document"]["num"] == 10
        @test bson["vector"] == collect(1:10)
        @test bson["source"] == Mongoc.BSONCode("function() = 1")
        @test bson["null"] == nothing
        @test bson["substring"] == sub

        let
            sub_bson = bson["sub_document"]
            @test sub_bson["hey"] == "you"
            @test sub_bson["num"] == 10
        end
    end

    @testset "BSON to Dict conversion" begin
        dict = Dict("a" => 1, "b" => false, "c" => "string", "d" => nothing)
        doc = Mongoc.BSON(dict)
        @test doc["a"] == 1
        @test doc["b"] == false
        @test doc["c"] == "string"
        @test doc["d"] == nothing
        @test dict == Mongoc.as_dict(doc)
        @test dict == Dict(doc)
        @test dict == Dict{String, Any}(doc)
        @test dict == convert(Dict, doc)
        @test dict == convert(Dict{String, Any}, doc)
    end

    @testset "BSON Dict API" begin
        doc = Mongoc.BSON("a" => 1, "b" => false, "c" => "string", "d" => nothing)

        @test doc["a"] == 1
        @test doc["b"] == false
        @test doc["c"] == "string"
        @test doc["d"] == nothing

        for (key, value) in doc
            if key == "a"
                @test value == 1
            elseif key == "b"
                @test value == false
            elseif key == "c"
                @test value == "string"
            elseif key == "d"
                @test value == nothing
            else
                # test fails
                @test false
            end
        end
    end

    @testset "BSON copy" begin
        @testset "exclude one key" begin
            src = Mongoc.BSON("hey" => "you", "out" => 1)
            dst = Mongoc.BSON()
            Mongoc.bson_copy_to_excluding_noinit(src.handle, dst.handle, "out")
            @test !haskey(dst, "out")
            @test dst["hey"] == "you"
        end

        @testset "no exclude keys" begin
            src = Mongoc.BSON("hey" => "you", "out" => 1)
            dst = Mongoc.BSON()
            Mongoc.bson_copy_to_noinit(src.handle, dst.handle)
            @test Mongoc.as_dict(src) == Mongoc.as_dict(dst)
        end
    end

    @testset "BSON Write to IO" begin

        @testset "write_bson closure" begin
            io = IOBuffer()

            Mongoc.bson_writer(io, initial_buffer_capacity=1) do writer
                Mongoc.write_bson(writer) do bson
                    bson["id"] = 10
                    bson["str"] = "aa"
                end
            end

            @test take!(io) == [0x1d,0x00,0x00,0x00,0x12,0x69,0x64,0x00,0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x73,0x74,0x72,0x00,0x03,0x00,0x00,0x00,0x61,0x61,0x00,0x00]
        end

        @testset "BSON copy single doc" begin
            src = Mongoc.BSON("id" => 10, "str" => "aa")

            io = IOBuffer()
            Mongoc.write_bson(io, src)

            @test take!(io) == [0x1d,0x00,0x00,0x00,0x12,0x69,0x64,0x00,0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x73,0x74,0x72,0x00,0x03,0x00,0x00,0x00,0x61,0x61,0x00,0x00]
        end

        @testset "BSON copy doc list" begin
            list = Vector{Mongoc.BSON}()

            let
                src = Mongoc.BSON("id" => 1, "name" => "1st")
                push!(list, src)
            end

            let
                src = Mongoc.BSON("id" => 2, "name" => "2nd")
                push!(list, src)
            end

            io = IOBuffer()
            Mongoc.write_bson(io, list)

            seekstart(io)
            vec_bson = Mongoc.read_bson(io)
            @test length(vec_bson) == 2

            let
                fst_bson = vec_bson[1]
                @test fst_bson["id"] == 1
                @test fst_bson["name"] == "1st"
            end

            let
                sec_bson = vec_bson[2]
                @test sec_bson["id"] == 2
                @test sec_bson["name"] == "2nd"
            end

            seekstart(io)
            reader = Mongoc.BSONReader(read(io))
            vec_bson_from_reader = collect(reader)

            let
                fst_bson = vec_bson_from_reader[1]
                @test fst_bson["id"] == 1
                @test fst_bson["name"] == "1st"
            end

            let
                sec_bson = vec_bson_from_reader[2]
                @test sec_bson["id"] == 2
                @test sec_bson["name"] == "2nd"
            end
        end

        @testset "read BSON from data" begin
            vec_bson = Mongoc.read_bson([0x1d,0x00,0x00,0x00,0x12,0x69,0x64,0x00,0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x73,0x74,0x72,0x00,0x03,0x00,0x00,0x00,0x61,0x61,0x00,0x00,0x00,0x00,0x00])
            @test length(vec_bson) == 1
            bson = vec_bson[1]
            @test bson["id"] == 10
            @test bson["str"] == "aa"
        end

        @testset "read/write BSON to/from File" begin
            filepath = joinpath(@__DIR__, "data.bson")
            isfile(filepath) && rm(filepath)

            list = Vector{Mongoc.BSON}()

            let
                src = Mongoc.BSON("id" => 1, "name" => "1st")
                push!(list, src)
            end

            let
                src = Mongoc.BSON("id" => 2, "name" => "2nd")
                push!(list, src)
            end

            try
                open(filepath, "w") do io
                    Mongoc.write_bson(io, list)
                end

                @test isfile(filepath)

                reader = Mongoc.BSONReader(filepath)
                for (i, bson) in enumerate(reader)
                    if i == 1
                        @test bson["id"] == 1
                        @test bson["name"] == "1st"
                    elseif i == 2
                        @test bson["id"] == 2
                        @test bson["name"] == "2nd"
                    else
                        error("Got document $i.")
                    end
                end
                Mongoc.destroy!(reader)

            finally
                if isfile(filepath)
                    try
                        rm(filepath)
                    catch err
                        @warn("Failed to remove test file $filepath: $(err.msg)")
                        stacktrace(catch_backtrace())
                    end
                end
            end
        end
    end

    @testset "BSONJSONReader" begin

        @testset "Iterate Reader" begin
            fp = joinpath(@__DIR__, "docs.json")
            @assert isfile(fp)
            reader = Mongoc.BSONJSONReader(fp)

            for (i, bson) in enumerate(reader)
                if i == 1
                    @test bson["num"] == 1
                    @test bson["str"] == "two"
                elseif i == 2
                    @test bson["num"] == 2
                    @test bson["str"] == "three"
                else
                    error("Got bson $i.")
                end
            end

            Mongoc.destroy!(reader)
        end

        @testset "read_bson_from_json" begin
            fp = joinpath(@__DIR__, "docs.json")
            @assert isfile(fp)

            for (i, bson) in enumerate(Mongoc.read_bson_from_json(fp))
                if i == 1
                    @test bson["num"] == 1
                    @test bson["str"] == "two"
                elseif i == 2
                    @test bson["num"] == 2
                    @test bson["str"] == "three"
                else
                    error("Got bson $i.")
                end
            end
        end
    end

    @testset "BSONError" begin
        err = Mongoc.BSONError(0x00000005, 0x00000101, (0x54, 0x6f, 0x74, 0x61, 0x6c, 0x20, 0x73, 0x69, 0x7a, 0x65, 0x20, 0x6f,
            0x66, 0x20, 0x61, 0x6c, 0x6c, 0x20, 0x74, 0x72, 0x61, 0x6e, 0x73, 0x61, 0x63, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x6f, 0x70, 0x65, 0x72, 0x61, 0x74,
            0x69, 0x6f, 0x6e, 0x73, 0x20, 0x6d, 0x75, 0x73, 0x74, 0x20, 0x62, 0x65, 0x20, 0x6c, 0x65, 0x73, 0x73, 0x20, 0x74, 0x68, 0x61, 0x6e, 0x20, 0x31,
            0x36, 0x37, 0x39, 0x33, 0x36, 0x30, 0x30, 0x2e, 0x20, 0x41, 0x63, 0x74, 0x75, 0x61, 0x6c, 0x20, 0x73, 0x69, 0x7a, 0x65, 0x20, 0x69, 0x73, 0x20,
            0x31, 0x36, 0x37, 0x39, 0x34, 0x31, 0x37, 0x34, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00))

        str = sprint(show, err)
        @test str == "BSONError: domain=5, code=257, message=Total size of all transaction operations must be less than 16793600. Actual size is 16794174"
        @test sprint(showerror, err) == str
    end

    @testset "serialize" begin

        @testset "BufferedBSON" begin
            bson = Mongoc.BSON("a" => 1)
            x = Mongoc.BufferedBSON(bson)
            bson_copy = Mongoc.BSON(x)
            @test bson_copy["a"] == 1
        end

        addprocs(1)
        @everywhere using Mongoc

        @testset "serialize BufferedBSON" begin
            f = @spawn Mongoc.BufferedBSON(Mongoc.BSON("a" => 1))
            bson = Mongoc.BSON(fetch(f))
            @test bson["a"] == 1
        end

        @testset "read/write single BSON" begin
            doc = Mongoc.BSON("a" => 1)
            io = IOBuffer()
            write(io, doc)
            seekstart(io)
            doc2 = read(io, Mongoc.BSON)
            @test doc2["a"] == 1
        end

        @testset "Serialize BSON" begin
            f = @spawn Mongoc.BSON("a" => 1)
            bson = fetch(f)
            @test bson["a"] == 1
        end
    end
end
