# if jupyer can not be found, set it directly or disable this environment variable to reinstall it in conda
# ENV["JUPYTER"] = ""

# if you're running on a remote server, please run this from a compute node, set the port below and use the ssh tunnel
remote_server_port = nothing

# check if we're running on the AMD HPC fund cluster (requires additional steps)
amd_hpc_fund = false
job_filename = "job.notebook"
job_path = job_filename
if contains(gethostname(), "hpcfund")
    try
        run(`git rev-parse --show-toplevel`)
        root_path = strip(read(`git rev-parse --show-toplevel`, String))
        global job_path = "$root_path/amdhpcfund.job.notebook"
    catch e
        @warn "Could not determine the root of the repository. Please make sure you are running this notebook from a git repository."
    end
    if isfile(job_path) && job_path != job_filename
        run(`cp $job_path $job_filename`)
    else
        @warn "Could not find job.notebook in the root of the repository. Copying it from shared."
        run(`cp /work1/proj_sc26julia/shared/job.notebook .`)
        global job_path = "job.notebook"
    end
    remote_server_port = nothing    # set by job.notebook
    amd_hpc_fund = true
end

function wait_for_file_contents(filepath::String, substring::String=nothing, timeout::Real=Inf, poll_interval::Real=0.5)
    start_time = time()
    while !isfile(filepath)
        if time() - start_time > timeout
            error("Timed out waiting for file: $filepath")
        end
        sleep(poll_interval)
    end
    if !isnothing(substring)
        while !contains(read(filepath, String), substring)
            if time() - start_time > timeout
                error("Timed out waiting for file $filepath to contain substring: $substring")
            end
            sleep(poll_interval)
        end
    end
    return read(filepath, String)
end

using Pkg

Pkg.instantiate()
Pkg.add("IJulia")

# if necessary, rebuild IJulia
# Pkg.build("IJulia")

using IJulia

IJulia.installkernel("GPU Julia", "--project=@.", "--threads=auto")

if !amd_hpc_fund && isnothing(remote_server_port)
    notebook(dir=@__DIR__, verbose=true)
elseif amd_hpc_fund
    launch_output = strip(read(`sbatch job.notebook`, String))
    @info launch_output
    jobid = strip(read(`squeue --me -t PENDING,RUNNING --noheader --format="%A"`, String))
    length(collect(eachmatch(r"\b\d+\b", jobid))) == 1 || error("Could not determine job ID from squeue output: $jobid")
    filename = "job.$jobid.out"
    println("Waiting for job $jobid to create $filename")
    outfile = strip(wait_for_file_contents(filename, "http://localhost:8888"))
    ssh_tunnel_command = filter(contains("ssh -t"), split(outfile, '\n'))[1]
    port_number = match(Regex("-L (.*?):"), ssh_tunnel_command).captures[1]
    server_token = split(filter(contains("http://localhost:8888/tree?token="), split(outfile, '\n'))[1], "token=")[2]
    @info "On your local machine, create an ssh tunnel by running the following command: \n$(ssh_tunnel_command)"
    @info "Then go to: http://localhost:$port_number/tree?token=$server_token"
    @warn "When done, please run `scancel --me && rm $filename`"
    rm("job.notebook")
else
    # when running on a remote server, you can use the following command to start the notebook in detached mode and specify a port number
    run(ignorestatus(`fuser -k $remote_server_port/tcp`)) # kill any process already on the port
    notebook(dir=@__DIR__, port=remote_server_port, detached=true, verbose=true)
    ssh_tunnel_command = "ssh -N -J <username>@<jumpserver> -L <local_port>:localhost:$remote_server_port <username>@<computenode>"
    @info "On your local machine, create an ssh tunnel by running the following command (leave out the jump if not needed): \n$(ssh_tunnel_command)"
    @info "Then, open the notebook in your browser at http://localhost:<local_port> (use the token provided in the terminal output when starting the notebook server)"
end
