
module Mongoc
using MongoC_jll

import Base.UUID
using Dates, DecFP, Serialization, OrderedCollections

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
    atexit(mongoc_cleanup)
end

end # module Mongoc
