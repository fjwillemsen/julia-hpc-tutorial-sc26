using Pkg


Pkg.add("IJulia")

using IJulia

IJulia.installkernel(
    "julia_gpu_kerneltuning",
    "--project=@.",
    "--threads=auto",
)
notebook(dir=@__DIR__)