using Test

@testset "Exit after using clients" begin
    uri = "mongodb://localhost:27017/?heartbeatFrequencyMS=500&serverSelectionTimeoutMS=1000&connectTimeoutMS=500"
    project = dirname(Base.active_project())
    script = joinpath(@__DIR__, "exit_client.jl")
    for mode in ("standalone", "pooled", "standalone-destroyed", "pooled-destroyed")
        command = `$(Base.julia_cmd()) --startup-file=no --project=$project $script $uri $mode`
        @test success(pipeline(command, stdout=devnull))
    end
end
