import Libdl, LibGit2, LinearAlgebra

# Use this version of Elemental
Elsha = "79987d38b04838acf6b6195be1967177521ee908"

if Sys.iswindows()
    error("Elemental only works on Unix Platforms")
end

depdir = dirname(@__FILE__)

if !isdir(joinpath(depdir, "src"))
    mkdir(joinpath(depdir, "src"))
end
srcdir = joinpath(depdir, "src", "Elemental")

if !isdir(joinpath(depdir, "usr"))
    mkdir(joinpath(depdir, "usr"))
end
prefix = joinpath(depdir, "usr")

if !isdir(srcdir)
    LibGit2.clone("https://github.com/elemental/Elemental.git", "$srcdir")
end
cd(srcdir) do
    LibGit2.checkout!(LibGit2.GitRepo("."), "$Elsha")
end

LinearAlgebra.BLAS.check()
blas = LinearAlgebra.BLAS.vendor()
mathlib = Libdl.dlpath(LinearAlgebra.BLAS.libblas)
blas64 = LinearAlgebra.USE_BLAS64 ? "ON" : "OFF"
blas_suffix = blas === :openblas64 ? "_64_" : "_"
build_procs = (haskey(ENV, "CI") && ENV["CI"] == "true") ? 2 : Sys.CPU_THREADS

builddir = joinpath(depdir, "builds")
if isdir(builddir)
    rm(builddir, recursive=true)
end
mkdir(builddir)

cd(builddir) do
    run(`cmake -D CMAKE_INSTALL_PREFIX=$prefix
               -D INSTALL_PYTHON_PACKAGE=OFF
               -D PYTHON_EXECUTABLE=""
               -D PYTHON_SITE_PACKAGES=""
               -D EL_USE_64BIT_INTS=$blas64
               -D EL_USE_64BIT_BLAS_INTS=$blas64
               -D MATH_LIBS=$mathlib
               -D EL_BLAS_SUFFIX=$blas_suffix
               -D EL_LAPACK_SUFFIX=$blas_suffix
               -D CMAKE_INSTALL_RPATH=$prefix/lib
               $srcdir`)
    run(`make -j $build_procs`)
    run(`make install`)
end
GC.gc() # work-around for https://github.com/JuliaLang/julia/issues/28306
