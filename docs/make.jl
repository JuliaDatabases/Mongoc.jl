
using Documenter, Mongoc

makedocs(
    sitename = "Mongoc.jl",
    modules = [ Mongoc ],
    pages = [ "Home" => "index.md",
              "Tutorial" => "tutorial.md",
              "CRUD Operations" => "crud.md",
              "Authentication" => "authentication.md",
              "Transactions" => "transaction.md",
              "Connection Pool" => "connection_pool.md",
              "GridFS" => "gridfs.md",
              "Logging" => "logging.md",
              "API Reference" => "api.md",
            ]
)

deploydocs(
    repo = "github.com/JuliaDatabases/Mongoc.jl.git",
    target = "build",
)
