using Mongoc

uri, mode = ARGS
const pool = startswith(mode, "pooled") ? Mongoc.ClientPool(uri) : nothing
const clients = [pool === nothing ? Mongoc.Client(uri) : Mongoc.Client(pool) for _ in 1:2]

foreach(Mongoc.ping, clients)
# A stale topology makes session cleanup scan again when clients are destroyed.
sleep(1.1)

if endswith(mode, "destroyed")
    foreach(Mongoc.destroy!, clients)
    pool === nothing || Mongoc.destroy!(pool)
end
