using Pkg, Test

root = pwd()
scratch = joinpath(ENV["RUNNER_TEMP"], "mongoc-exit-observer")
mkpath(scratch)
package = joinpath(scratch, "Mongoc")
mkpath(package)
cp(joinpath(root, "Project.toml"), joinpath(package, "Project.toml"))
cp(joinpath(root, "src"), joinpath(package, "src"))

# Instrument only the native callback target. The registration call is unchanged.
source_file = joinpath(package, "src", "Mongoc.jl")
source = read(source_file, String)
target = "    cleanup = Libdl.dlsym(Libdl.dlopen(libmongoc), :mongoc_cleanup)"
replacement = raw"""    cleanup = Libdl.dlsym(Libdl.dlopen(libmongoc), :mongoc_cleanup)
    observer = Libdl.dlopen(ENV["SWEEP_MONGOC_EXIT_OBSERVER"])
    setter = Libdl.dlsym(observer, :set_cleanup)
    ccall(setter, Cvoid, (Ptr{Cvoid}, Cstring), cleanup, ENV["SWEEP_MONGOC_EXIT_LOG"])
    cleanup = Libdl.dlsym(observer, :observed_cleanup)"""
@assert count(target, source) == 1
write(source_file, replace(source, target => replacement))
println("OBSERVED_PACKAGE_SOURCE=", source_file)

environment = joinpath(scratch, "environment")
Pkg.activate(environment)
Pkg.develop(PackageSpec(path=package))
Pkg.instantiate()
Pkg.status()

child_file = joinpath(scratch, "exit_client.jl")
child = read(joinpath(root, "test", "exit_client.jl"), String)
child *= raw"""

import Libdl
const marker = Libdl.dlsym(Libdl.dlopen(ENV["SWEEP_MONGOC_EXIT_OBSERVER"]), :observed_client)
for client in clients
    finalizer(client) do value
        Mongoc.destroy!(value)
        ccall(marker, Cvoid, ())
    end
end
"""
write(child_file, child)

@testset "Native CRT callback lifetime" begin
    port = get(ENV, "SWEEP_MONGOC_TEST_PORT", "27017")
    uri = "mongodb://localhost:" * port * "/?heartbeatFrequencyMS=500&serverSelectionTimeoutMS=1000&connectTimeoutMS=500"
    for mode in ("standalone", "pooled", "standalone-destroyed", "pooled-destroyed")
        log = joinpath(scratch, mode * ".log")
        ENV["SWEEP_MONGOC_EXIT_LOG"] = log
        command = `$(Base.julia_cmd()) --startup-file=no --project=$environment $child_file $uri $mode`
        @test success(command)
        @test isfile(log)
        events = readlines(log)
        println(mode, " NATIVE_EVENTS=", events)
        @test events == ["CLIENT_FINALIZED", "CLIENT_FINALIZED", "DRIVER_CLEANUP_COMPLETED"]
    end
end
