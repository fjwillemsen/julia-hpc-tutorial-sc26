# HPC fundamentals — environment setup for GPU computing

Steps for the parallel-programming notebooks with GPU setup: there are two options.

## Local machine: if you have macbook or nvidia GPU

1. Install [Julia](https://julialang.org/downloads/).
2. Clone the repo and enter the KernelAbstractions project:

   ```bash
   git clone https://github.com/JuliaParallel/julia-hpc-tutorial-sc26.git
   cd julia-hpc-tutorial-sc26/02-Parallel-Programming/KernelAbstractions
   ```

3. Open Jupyter from that folder (installs the **GPU Julia** IJulia kernel and starts the notebook server):

   ```bash
   julia --project=. open_notebook.jl
   ```

4. In Jupyter, pick kernel **GPU Julia** and open a notebook. In each notebook, set `DEV` in the **second cell** (`:CUDA` (NVIDIA), `:AMDGPU`, `:Metal`, or `:CPU`) before running `Pkg.add`, to match your hardware.



## AMD HPC Cluster: if you do not have a macbook or NVIDIA GPU


1. Open a terminal and connect to the cluster as follows:
```bash
ssh username@hpcfund.amd.com
```


2. Install julia, clone the git repo, and navigate to the correct folder:

```bash
curl -fsSL https://install.julialang.org | sh
source ~/.bashrc
git clone https://github.com/JuliaParallel/julia-hpc-tutorial-sc26.git
cd julia-hpc-tutorial-sc26/02-Parallel-Programming/KernelAbstractions
 ```


3. Request a node with a jupyter notebook attached as follows (replace job-id), and look at its output: (If the out file does not exist, your job may be queued, check using `squeue --me`.) You will need to follow these steps for every new folder you are navigating too.

```bash
cp  /work1/proj_sc26julia/shared/job.notebook .
julia --project=. -e 'using Pkg; Pkg.instantiate(); using IJulia; IJulia.installkernel("GPU Julia", "--project=@.", "--threads=auto")'
sbatch job.notebook
cat job.<job-id>.out
```

4. Finally, follow the instructions in the job file and open the jupyter terminal from your terminal:

5. In Jupyter, pick kernel **GPU Julia** and open a notebook. In each notebook, set `DEV` in the **second cell** (`:CUDA` (NVIDIA), `:AMDGPU`, `:Metal`, or `:CPU`) before running `Pkg.add`, to match your hardware.

6. When do done, do not forget to close your allocation!

```bash
scancel --me
```
