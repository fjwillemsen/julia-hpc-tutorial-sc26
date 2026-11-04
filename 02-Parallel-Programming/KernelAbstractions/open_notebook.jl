using Pkg

Pkg.add("IJulia")

using IJulia

IJulia.installkernel(
    "GPU Julia",
    "--project=@.",
    "--threads=auto",
)
notebook(dir=@__DIR__)