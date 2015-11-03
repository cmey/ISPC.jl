
"""
Runs `ispc` on `code` and prints the resulting assembly to stdout.
"""
function ispc_native(code, options=``)
    ispc_cmd = `ispc -o - --emit-asm $options -`
    open(ispc_cmd, "w", STDOUT) do stdin
        write(stdin, code)
    end
end

"""
Runs `ispc` on `code` and prints the resulting LLVM IR to stdout.
"""
function ispc_llvm(code, options=``, llvm_dis="/usr/local/opt/llvm/bin/llvm-dis")
    ispc_cmd = pipeline(`ispc -o - --emit-llvm $options -`, `$llvm_dis -`)
    open(ispc_cmd, "w", STDOUT) do stdin
        write(stdin, code)
    end
end

# Detect how to link a shared library:
try
    run(`which libtool`)
    link(objfile, libfile) = run(
        `libtool -dynamic -o "$libfile" "$objfile"`)
catch
    run(`which g++`)
    link(objfile, libfile) = run(
        `g++ -dynamiclib -undefined suppress -flat_namespace "$objfile" -o "$libfile"`)
end

"""
Runs `ispc` on `code`, creates a shared library and returns a library
handle `lib` for use with `Libdl.dlsym(lib, symbol)`.
"""
function load_ispc(code, options=``)
    mktempdir() do tmpdir
        objfile = "$tmpdir/program.o"
        libfile = "$tmpdir/program.so"
        
        # Pipe the input program to ispc:
        ispc_cmd = `ispc -o "$objfile" --pic $options -`
        open(ispc_cmd, "w", STDOUT) do stdin
            write(stdin, code)
        end
        
        # Create a shared library:
        link(objfile, libfile)
        return Libdl.dlopen(libfile)
    end
    # Note: the temp dir and library files will be deleted now.
    # That's OK because the library is already loaded.
end
