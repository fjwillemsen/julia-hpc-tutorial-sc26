# if jupyer can not be found, set it directly or disable this environment variable to reinstall it in conda
# ENV["JUPYTER"] = ""

using Pkg

Pkg.add("IJulia")

# if necessary, rebuild IJulia
# Pkg.build("IJulia")

using IJulia

IJulia.installkernel("GPU Julia", "--project=@.", "--threads=auto")
notebook(dir=@__DIR__, verbose=true)

# # when running on a remote server, you can use the following command to start the notebook in detached mode and specify a port number
# run(ignorestatus(`fuser -k 8888/tcp`)) # kill any process already on port 8888
# notebook(dir=@__DIR__, port=8888, detached=true, verbose=true)

# on your local machine, create an ssh tunnel so your local client can connect to the remote notebook server:
# ssh -N -J user@jumpserver -L 8899:localhost:8888 user@node001

# finally, open the notebook in your browser at http://localhost:8899 (use the token provided in the terminal output when starting the notebook server)
