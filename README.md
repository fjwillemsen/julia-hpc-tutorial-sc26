# The Julia for HPC Tutorial at SC26

- **When** Monday, 16 November 2026, 8:30am - 5:00pm CST, full day
- **Where** SC26 venue: McCormick Place, Chicago, IL, **Room W185d**
- **Conference info**  [SC26 event webpage](https://sc26.conference-program.com/presentation/?id=tut134&sess=sess169)
- **Handouts slides**  [Julia for HPC SC26 Handouts](https://drive.google.com/file/d/1aSHfJ3gi_FW_oQfeNJW-yE_Q4PiTQUfh/view?usp=sharing) 

Welcome to the Julia for High-performance Computing (HPC) Tutorial at SC26 in Chicago, IL! This **full-day, 6-hour hands-on** tutorial introduces participants to using the Julia programming language effectively on HPC environments, from first principles to end-to-end deployment on a leadership-class system.
Registered participants: please look at the end of this file for access to the Oak Ridge National Laboratory [Odo system](https://docs.olcf.ornl.gov/systems/odo_user_guide.html) (32 nodes of Frontier, each node has 8 AMD MI250X GPUs). 

## Audience Target

- Those familiar with a programming language that want to learn more about Julia.
- Those without previous HPC familiarity. In fact, Julia is a great introductory language for HPC.
- Those interested in how Julia can help them go from idea to deploy at large scale on HPC systems - all in one language.

## Topics Covered

- Introduction to the Julia language and ecosystem for high-productivity
- Vendor-neutral parallel computing in Julia, intra-node: [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl), [JACC.jl](https://github.com/JuliaGPU/JACC.jl), inter-node: [MPI.jl](https://github.com/JuliaParallel/MPI.jl), [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl)
- Running and profiling a Julia application, the Gray-Scott diffusion-reaction partial differential equation solver on a HPC Cluster (CPU and GPU).

## Agenda

**Julia for HPC Tutorial**

- **Date** Monday, 16 November 2026
- **Time** 8:30am - 5:00pm CST
- **Location** W185d

**8:30 AM - 12:00 PM: Intro to the language, ecosystem, and CPU/GPU programming in Julia**

*8:30 AM - 10:00 AM  - Intro to Julia* 
- Welcome and setup up - 15 minutes
- Intro to the Julia language and ecosystem  - 75 minutes
    - Packaging, package, type system w/ exercises.
    - Julia features: inspect low-level IR `@code_llvm`, macro system `@time`, performance pitfalls `@inbounds`

**10:00 AM - 10:30 AM Conference Morning Break**

*10:30 - 12:00 PM - Parallel code with Julia - Part I*
- Intro to kernel programming in Julia - 15 minutes
- CPU/GPU portable programming: [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl) - 30 minutes
- CPU/GPU portable programming: [JACC.jl, Julia for Accelerators](https://github.com/JuliaGPU/JACC.jl) - 45 minutes

**12:00 PM - 1:30 PM Conference Lunch Break**

**1:30 PM - 5:00 PM Julia on HPC systems**

*1:30 AM - 3:00 PM  - Parallel code with Julia - Part II*
- Recap of morning contents - 15 minutes
- Auto-tuning with [KernelTuner.jl](https://github.com/KernelTuner/KernelTuner.jl) - 30 minutes
- Out-of-core parallel execution with [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl) - 45 minutes

**3:00 PM - 3:30 PM Conference Morning Break**

*3:30 PM - 5:00 PM  - Deploying a Julia Application on HPC systems*

- [Running Gray-Scott on Odo, Frontier's training system](https://docs.olcf.ornl.gov/systems/odo_user_guide.html) - 75 minutes
  - Deploying Gray-Scott: Julia packaging and HPC module system interaction
  - CPU/GPU kernels with JACC.jl + KernelAbstractions.jl (interoperabily) +  [MPI.jl](https://github.com/JuliaParallel/MPI.jl)  + parallel I/O code with [ADIOS2.jl](https://github.com/eschnett/ADIOS2.jl)
  - HPC performance measurements, weak and strong scaling exercises
  - Visualization of the simulation results on [OLCF JupyterHub-open](https://jupyter-open.olcf.ornl.gov/hub/login?next=%2Fhub%2F)
  - Profiling GPU kernels with rocprof
  - Gray-Scott code organization and description

## Resources
- [Julia Language](https://julialang.org/)
- [Julia for HPC Tutorial](https://juliaornl.github.io/TutorialJuliaHPC/)

## Contributors

The "Julia for HPC" Tutorial series has been an international multi-institutional and multi-disciplinary collaboration through the years:

[Massachusetts Institute of Technology (MIT), JuliaLab](https://julia.mit.edu/):
- [Evelyne Ringoot](https://math.mit.edu/directory/profile.html?pid=2682)
- [Felipe de Alcântara Tomé](https://github.com/fda-tome)
- [Julian Samaroo](https://github.com/jpsamaroo)
- [Raye Kimmerer](https://github.com/rayegun), now a PhD Student at [Princeton University](https://www.princeton.edu/)
- [Alan Edelman](https://math.mit.edu/~edelman/)

[King Abdullah University of Science and Technology (KAUST)](https://www.kaust.edu.sa/en/) 
- [Rabab Alomairy](https://cemse.kaust.edu.sa/profiles/rabab-alomairy), also with MIT
  
[University College London](https://www.ucl.ac.uk/)
- [Mosè Giordano](https://giordano.github.io/aboutme/)

[Leiden University](https://www.universiteitleiden.nl/en)
- [Floris-Jan Willemsen](https://fjwillemsen.com/) 

[Lawrence Berkeley National Laboratory, National Energy Research Scientific Computing Center](https://www.nersc.gov/)
- [Johannes P. Blaschke](https://www.linkedin.com/in/johannes-blaschke/), now at [Ellison Institute of Technology Oxford](https://eit.org/)

[Oak Ridge National Laboratory, Advanced Computing Systems Research Section](https://www.ornl.gov/section/advanced-computing-systems-research)
- [William F Godoy](https://www.ornl.gov/staff-profile/william-f-godoy) 
- [Philip Fackler](https://www.ornl.gov/staff-profile/philip-w-fackler)
- [Pedro Valero-Lara](https://www.ornl.gov/staff-profile/pedro-valero-lara)


## ORNL's Odo, Training system access
Participants are encourage to sign up for access to the Oak Ridge National Laboratory (ORNL) Leadership Computing Facility (OLCF) [Odo Training system](https://docs.olcf.ornl.gov/systems/odo_user_guide.html) (32 nodes of Frontier, 8 AMD MI250X nodes).

- Please use a verified institutional email (no gmail or other similar service)
- Please make sure you registered for the SC26 Tutorials
- Deadline to register: **November 6, 2026**
- To register: [https://my.olcf.ornl.gov/](https://my.olcf.ornl.gov/), follow instructions and use ProjectID: **TRN047**, and account type: **Open**.
  **NOTE**: "Funding source" means simply "who pays you?" (exact precision is not necessary as this is a training account)
- Questions about Odo access? Please reach out to [William F Godoy](https://www.ornl.gov/staff-profile/william-f-godoy), godoywf@ornl.gov 

Once you have received the email confirmation your ORNL resource account was created, you have access to Odo. (If you are a new user, your account will be created and an email will be sent asking you to set up a password. ) You do not need to use an RSA token to log in to Odo. Please use your XCAMS/UCAMS username and password (which is different from the username and PIN + RSA token code used to log in to other OLCF systems such as Frontier). To log in to Odo, please use your XCAMS/UCAMS username and password:

``` ssh USERNAME@login1.odo.olcf.ornl.gov ```


Please follow these steps to setup access to Julia and this repo:

```
cd /gpfs/wolf2/olcf/trn047/scratch/$USER
git clone https://github.com/JuliaParallel/julia-hpc-tutorial-sc26.git
cd julia-hpc-tutorial-sc26
source setenv-odo.sh
```

Each instructor will provide content-specific steps after that.

## AMD HPC & AI Cluster

We thank Advanced Micro Devices for their generous contribution of compute resources for participants who cannot obtain access to Odo. Instructions to follow.
