using Libdl

println("JULIA_VERSION=", VERSION)
for library in ("msvcrt", "ucrtbase")
    handle = Libdl.dlopen_e(library)
    println("CRT_LIBRARY=", library, " HANDLE=", handle)
    handle == C_NULL && continue
    for symbol in (:atexit, :_atexit, :_onexit, :_crt_atexit, :__dllonexit, :__cxa_atexit)
        println(library, " ", symbol, " ", Libdl.dlsym_e(handle, symbol))
    end
end
library = ccall(:jl_dlfind, Cstring, (Cstring,), "atexit")
println("DEFAULT_ATEXIT_LIBRARY=", library == C_NULL ? "not found" : unsafe_string(library))
