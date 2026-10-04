
module Mongoc
using MongoC_jll
import Libdl

import Base.UUID
using Dates, DecFP, Serialization

#
# utility functions for date conversion
#

# offsets an additional year from UNIXEPOCH in milliseconds.
const ISODATE_OFFSET = Dates.UNIXEPOCH + 24 * 60 * 60 * 1000 * 365
isodate2datetime(millis::Int64) = Dates.epochms2datetime(millis + ISODATE_OFFSET)
datetime2isodate(dt::DateTime) = Dates.datetime2epochms(dt) - ISODATE_OFFSET

include("bson.jl")
include("types.jl")
include("c_api.jl")
include("client.jl")
include("clientpool.jl")
include("database.jl")
include("collection.jl")
include("session.jl")
include("streams.jl")
include("gridfs.jl")

function __init__()
    mongoc_init()
    # Julia's exit hooks precede object finalizers. Keep libmongoc loaded and
    # register its native cleanup with libc so clients are destroyed first.
    cleanup = Libdl.dlsym(Libdl.dlopen(libmongoc), :mongoc_cleanup)
    registered = if Sys.islinux()
        # glibc's atexit is hidden; use the registration function it calls.
        ccall(:__cxa_atexit, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), cleanup, C_NULL, C_NULL)
    else
        ccall(:atexit, Cint, (Ptr{Cvoid},), cleanup)
    end
    registered == 0 ||
        error("Could not register libmongoc cleanup at process exit.")
end

end # module Mongoc
