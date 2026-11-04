# Matrix multiplication notebook — discussion question answers

Answers for `matrix_multiplication.ipynb`. The same text appears in `solved_notebooks/matrix_multiplication.ipynb` after each question.

## Answer (2.1.3)

1. Work item `(j, i)` — it touches the same two matrix entries in the opposite order.
2. Not reliably. If `(j, i)` runs first and writes `A[j, i]` before `(i, j)` reads, `(i, j)` may see the updated value instead of the original — a global race like the sum kernel in the GPU introduction.
3. `DAT` is a separate output buffer and `@Const(DA)` keeps the input read-only so work items do not overwrite data other work items still need to read.

## Answer (2.1.4)

1. Device `permutedims!` pays **kernel launch and synchronization** (and any library setup) on every timed call. When `N` is tiny, the actual permute moves negligible data, so the curve stays on a launch floor and barely tracks `N`.
2. On the CPU there is no GPU launch; small problems stay on the host with low overhead. On the device, the same call must amortize that fixed cost over **Θ(`N²`)** memory traffic and parallel work. Once `N` is large enough on *your* plot, bulk movement on the GPU wins; the exact crossover is not universal.
3. **No.** Launch latency, memory bandwidth, CPU speed, backend (`DEV`), driver, and even whether arrays already live on the device all shift the curves. Compare trends (floor, then rise, then which curve is above) rather than a single magic `N`.

## Answer (2.2.4)

1. Each device call pays **kernel launch and synchronization** overhead before useful work runs. For tiny matrices the `O(N³)` multiply is negligible, so device `*` and the naive kernel sit on a similar floor and time barely tracks `N`.
2. Matrix multiplication does **Θ(`N³`)** multiply-adds and moves **Θ(`N²`)** data; as `N` increases those costs grow until they dominate the fixed launch cost and the curves climb on the log plot.
3. On the GPU, `DA * DB` calls a **vendor GEMM** (cuBLAS, rocBLAS, Metal, …) with cache-aware blocking, SIMD or wide loads, and often tensor cores. The naive kernel repeats global memory traffic and lacks that tuning. With `DEV = :CPU`, both `*` curves time **OpenBLAS** on the host (CPU `*` and device `*` use the same host arrays and the same library).

## Answer (2.4.2)

1. **Kernel launch and synchronization** dominate: each device call pays a roughly fixed overhead before any element is moved. For tiny matrices the actual transpose work is negligible, so naive and tiled kernels sit on the same launch floor and the time barely tracks `N`. CPU `my_transpose_cpu!` avoids that launch cost and is often faster in this regime.
2. Once `N` is large enough, work and memory traffic grow (roughly like `N²`) and the curves rise above the floor; the GPU’s parallelism then beats the single-threaded CPU loop. The tiled kernel loads a block into shared memory and writes coalesced output, while the naive kernel does strided global reads and writes—so bandwidth waste shrinks with tiling and the tiled curve grows more slowly; the gap widens as `N` increases.
3. Small problems on the device still pay launch (and any setup) without enough parallel work to amortize it, so CPU `permutedims!` can win. For larger `N`, bulk data movement on the device favors the vendor library. At the largest sizes on the plot, a kernel tailored to this access pattern (shared-memory tile + coalesced write) can match or beat a generic `permutedims!` path because every global access is arranged for the transpose, not a general axis permutation.

## Answer (2.4.3)

1. The dot product for one output needs `O(N)` memory accesses but only `O(N)` multiply-adds, so performance is often **memory-bandwidth** limited long before compute is saturated. Work items that share a row or column load overlapping regions of `A` and `B` from **global** memory independently, so the same values are fetched many times across the grid.
2. `@localmem` is shared by the whole workgroup. Without a barrier after the load phase, a work item can multiply using `tileA`/`tileB` entries that a neighbor has not stored yet; without a barrier before the next load, a work item can overwrite a tile while others still read it — the same **race** pattern as in the GPU introduction, but in shared memory.
3. Small matrices pay mostly **launch and synchronization**; both custom kernels hit a similar floor. As `N` grows, the tiled kernel loads each block of `A` and `B` into shared memory once per step and reuses it across the workgroup, while the naive kernel still streams full rows and columns from global memory, so tiling wins by cutting redundant traffic. `DA * DB` stays ahead because the vendor library adds autotuned blocking, **register blocking**, vectorized or wide loads, and (on NVIDIA) **tensor cores** — see [`performant_matmul.jl`](https://github.com/JuliaGPU/KernelAbstractions.jl/blob/main/examples/performant_matmul.jl) for a more complete tiled example.
