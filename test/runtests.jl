
include("bson_tests.jl")
include("mongodb_tests.jl")
include("exit_tests.jl")

#=
if !Sys.iswindows()
	include("replica_set_tests.jl")
end
=#
