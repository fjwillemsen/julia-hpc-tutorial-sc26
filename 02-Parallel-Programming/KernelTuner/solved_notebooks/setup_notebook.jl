# No need to touch this file, it's just used to set up the notebooks.

using Pkg
Pkg.activate(joinpath(@__DIR__))

Pkg.add(["BenchmarkTools", "ProgressMeter", "Plots", "ColorTypes", "KernelAbstractions", "PythonCall", "JSON", String(DEV)])
Pkg.develop(path="/Users/fjwillemsen/University/Research/Projects/Bayesian_Optimization_in_Kernel_Tuner/Code/KernelTuner.jl")

function is_system_dark_mode()
    if Sys.isapple()
        # Checks macOS global preferences
        return success(`defaults read -g AppleInterfaceStyle`)
    elseif Sys.iswindows()
        # Checks Windows registry key for Dark Mode
        try
            reg_val = read(global_theme_cmd, String)
            return occursin("0x1", read(`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme`, String)) == false
        catch
            return false
        end
    else
        return false # Fallback for Linux or unexpected environments
    end
end

dark_mode = is_system_dark_mode()

# Load required packages
using JSON
using PythonCall
using Statistics
using ProgressMeter
using BenchmarkTools
using Base64
using Plots
using ColorTypes
using KernelAbstractions
using KernelTuner

# Set the default theme based on system dark mode preference
if dark_mode
    theme(:dark)
else
    theme(:default)
end

# Define a lightweight text wrapper class to get live stdout to the cell
sys = pyimport("sys")
@pyexec """
class JuliaTextStdout:
    def __init__(self, jl_print):
        self.jl_print = jl_print
    def write(self, string):
        if string:
            self.jl_print(string)
        return len(string)
    def flush(self):
        pass
""" => JuliaTextStdout
sys.stdout = JuliaTextStdout(print)

# Define a function to get the source of a cell by tag
function get_cell_by_tag(tag_name)
    notebook = JSON.parsefile("gray-scott.ipynb")
    cell_idx = findfirst(notebook["cells"]) do cell
        tags = get(get(cell, "metadata", Dict()), "tags", [])
        return tag_name in tags
    end
    if isnothing(cell_idx)
        error("No cell found with tag: $tag_name")
    end
    source = notebook["cells"][cell_idx]["source"]
    return join(source)
end

# Define a function to plot heatmap of tuning results
function plot_heatmap_tuning_results(data, key_x_axis::String, key_y_axis::String, objective::String="time", higher_is_better=false)

    # Unique sorted values for axes
    data_x_axis = sort(unique([Int(d[key_x_axis]) for d in data]))
    data_y_axis = sort(unique([Int(d[key_y_axis]) for d in data]))

    # Create a matrix for the heatmap
    heatmap_data = Matrix{Float32}(undef, length(data_y_axis), length(data_x_axis))
    fill!(heatmap_data, NaN)  # Fill with NaN to indicate missing values

    for (i, yval) in enumerate(data_y_axis)
        for (j, xval) in enumerate(data_x_axis)
            # Find the entry with this combination
            entry = findfirst(d -> Int(d[key_x_axis]) == xval && Int(d[key_y_axis]) == yval, data)
            if entry !== nothing
                heatmap_data[i, j] = data[entry][objective]
            end
        end
    end

    # Create the heatmap
    pretty(name) = name == lowercase(name) ? titlecase(replace(name, "_" => " ")) : name   # keep names like "GB/s" as they are
    heatmap(data_x_axis, data_y_axis, heatmap_data,
        xlabel=pretty(key_x_axis),
        ylabel=pretty(key_y_axis),
        title="Tuning Heatmap: " * pretty(objective),
        color=higher_is_better ? cgrad(:RdYlGn) : reverse(cgrad(:RdYlGn)),
        colorbar_title=" \n" * pretty(objective) * (higher_is_better ? " (higher is better)" : " (lower is better)"),
        colorbar=true,
        right_margin=3Plots.mm,
        xticks=(data_x_axis, string.(data_x_axis)),
        yticks=(data_y_axis, string.(data_y_axis)),
        xscale=:log2,
        yscale=:log2,
        # aspect_ratio = 1,
        # size = (700, 600),
        dpi=300,
        grid=false,
    )

    # Annotate each cell with the value
    for (i, yval) in enumerate(data_y_axis)
        for (j, xval) in enumerate(data_x_axis)
            val = heatmap_data[i, j]
            # Swap text color - in this color scheme, the middle values are yellow, so we want to use black text for those and white text for the extremes
            min_val = minimum(skipmissing(vec(filter(!isnan, vec(heatmap_data)))))
            max_val = maximum(skipmissing(vec(filter(!isnan, vec(heatmap_data)))))
            range_val = max_val - min_val
            text_color = min_val + (range_val * 0.25) < val < min_val + (range_val * 0.75) ? :black : :white
            annotate!(xval, yval, text(round(val, digits=2), 10, text_color, :center))
        end
    end

    display(current())
end

# Live scatterplot of a running tuning session, read from Kernel Tuner's cache file.
# Don't worry about the implementation details: wrap `tune_kernel` in `with_live_tuning_plot(cachefile) do ... end`.
using Base64, JSON, Plots

# While tuning, the cache file is not valid JSON yet (it is only closed at the end), but Kernel Tuner writes
# a header followed by one line per evaluated configuration, so we parse those parts separately.
function read_tuning_cache(cachefile::AbstractString)
    text = isfile(cachefile) ? read(cachefile, String) : ""
    r = findfirst("\"cache\": {", text)
    isnothing(r) && return String[], Any[]
    param_keys = try
        String.(JSON.parse(text[1:last(r)] * "}}")["tune_params_keys"])
    catch
        String[]
    end
    configs = Any[]
    for line in eachsplit(text[(last(r)+1):end], '\n')
        m = match(r"^\"[^\"]*\":\s*(\{.*\}),?\s*$", line)
        isnothing(m) && continue
        entry = m.captures[1]
        try
            push!(configs, JSON.parse(entry))
        catch
            try   # once tuning is done, the last line also closes the cache: `{...}}`
                endswith(entry, "}}") && push!(configs, JSON.parse(chop(entry)))
            catch   # a half-written line, it will be complete on the next poll
            end
        end
    end
    return param_keys, configs
end

# Live scatterplot of a running tuning session, read from Kernel Tuner's cache file.
function plot_live_tuning_results(param_keys, configs; objective::String="time", higher_is_better=false)
    values = [get(c, objective, nothing) for c in configs]
    valid = findall(v -> v isa Real && isfinite(v), values)   # failed configurations store an error string instead
    y = Float64.(values[valid])
    label = objective == "time" ? "Time (ms)" : objective == lowercase(objective) ? titlecase(replace(objective, "_" => " ")) : objective
    title = "$(length(configs)) configurations evaluated ($(length(configs) - length(valid)) failed)"
    if !isempty(y)
        i = higher_is_better ? argmax(y) : argmin(y)
        best_params = join(["$k=$(configs[valid[i]][k])" for k in param_keys], ", ")
        title *= "\nbest: $(round(y[i], sigdigits=4))$(objective == "time" ? " ms" : "") with $best_params"
    end
    log_scale = !isempty(y) && minimum(y) > 0 && maximum(y) > 10 * minimum(y)   # log scale for wide ranges
    # same colors as the heatmaps (green is good, red is bad), following the y-axis scale so outliers don't wash out the rest
    p = scatter(valid, y; label="configuration", markersize=5, markerstrokewidth=0.3, markerstrokecolor=:gray40, alpha=0.8,
        marker_z=isempty(y) ? nothing : (log_scale ? log10.(y) : y), color=higher_is_better ? cgrad(:RdYlGn) : reverse(cgrad(:RdYlGn)), colorbar=false,
        xlabel="Configuration (in order of evaluation)", ylabel=label * (higher_is_better ? ", higher is better" : ", lower is better"),
        yscale=log_scale ? :log10 : :identity,
        xlims=(0, max(length(configs), 1) + 1), title=title, titlefontsize=10,
        size=(800, 600), left_margin=3Plots.mm, bottom_margin=3Plots.mm, legend=:topright, dpi=200)
    if !isempty(y)
        plot!(p, valid, higher_is_better ? accumulate(max, y) : accumulate(min, y); seriestype=:steppost, linewidth=2, color=:black, label="best so far")
    end
    return p
end

# Indices of the Pareto-optimal points: those for which no other point has both a lower `a` and a lower `b`, ordered by `a`.
function pareto_front(a, b)
    front, lowest_b = Int[], Inf
    for i in sortperm(a)
        if b[i] < lowest_b
            push!(front, i)
            lowest_b = b[i]
        end
    end
    return front
end

# Live scatterplot of time versus energy of a running tuning session, read from Kernel Tuner's cache file.
function plot_live_time_energy(param_keys, configs; energy_key::String="energy")
    measured(c, k) = get(c, k, nothing) isa Real && isfinite(c[k]) && c[k] > 0
    valid = findall(c -> measured(c, "time") && measured(c, energy_key), configs)   # failed configurations store an error string instead
    t = Float64[configs[i]["time"] for i in valid]
    e = Float64[configs[i][energy_key] for i in valid]
    title = "$(length(configs)) configurations evaluated ($(length(configs) - length(valid)) failed)"
    wide(v) = !isempty(v) && maximum(v) > 10 * minimum(v)   # log scale for wide ranges
    p = scatter(t, e; label="configuration", markersize=5, markerstrokewidth=0.3, markerstrokecolor=:gray40, alpha=0.8,
        marker_z=isempty(e) ? nothing : (wide(e) ? log10.(e) : e), color=reverse(cgrad(:RdYlGn)), colorbar=false,
        xlabel="Time (ms), lower is better", ylabel="Energy (J), lower is better",
        xscale=wide(t) ? :log10 : :identity, yscale=wide(e) ? :log10 : :identity,
        size=(800, 600), left_margin=3Plots.mm, bottom_margin=3Plots.mm, legend=:topleft, dpi=200, titlefontsize=10)
    if !isempty(t)
        config_string(c) = join(["$k=$(c[k])" for k in param_keys], ", ")
        fastest, lowest = argmin(t), argmin(e)
        title *= "\nfastest: $(round(t[fastest], sigdigits=3)) ms, $(round(e[fastest], sigdigits=3)) J with $(config_string(configs[valid[fastest]]))"
        title *= "\nlowest energy: $(round(t[lowest], sigdigits=3)) ms, $(round(e[lowest], sigdigits=3)) J with $(config_string(configs[valid[lowest]]))"
        front = pareto_front(t, e)
        plot!(p, t[front], e[front]; seriestype=:steppost, linewidth=2, color=:black, label="Pareto front")
        scatter!(p, [t[fastest]], [e[fastest]]; marker=:star5, markersize=10, color=:dodgerblue, label="fastest")
        scatter!(p, [t[lowest]], [e[lowest]]; marker=:diamond, markersize=8, color=:magenta, label="lowest energy")
    end
    plot!(p; title=title)
    return p
end

# Runs `f` (the tuning) while a background thread polls `cachefile` and redraws the plot in place every `interval` seconds.
# `plotter` draws the plot from the cache contents, the other keyword arguments are passed on to it.
function with_live_tuning_plot(f, cachefile::AbstractString; interval=0.5, plotter=plot_live_tuning_results, kwargs...)
    render() = plotter(read_tuning_cache(cachefile)...; kwargs...)
    other_threads = Threads.nthreads(:default) - (Threads.threadpool() == :default ? 1 : 0)
    kernel = isdefined(Main, :IJulia) ? Main.IJulia._default_kernel : nothing
    if other_threads < 1 || isnothing(kernel)
        @warn "Live plotting needs Jupyter and Julia started with more than one thread (e.g. `--threads=auto`); plotting once tuning is done."
        result = f()
        display(render())
        return result
    end

    # Jupyter replaces an output in place when it receives `update_display_data` with the same `display_id`
    IJ, parent, display_id = Main.IJulia, kernel.execute_msg, string(rand(UInt64), base=16)
    function send(msg_type)
        png = base64encode(io -> show(io, MIME("image/png"), render()))
        content = Dict("data" => Dict("image/png" => png, "text/plain" => "Live tuning plot"),
            "metadata" => Dict(), "transient" => Dict("display_id" => display_id))
        IJ.send_ipython(kernel.publish[], kernel, IJ.msg_pub(parent, msg_type, content))
    end
    send("display_data")    # on the main thread, so the plotting code is compiled before the poller starts

    done = Threads.Atomic{Bool}(false)
    poller = Threads.@spawn begin   # runs on another thread while the main thread is busy inside Kernel Tuner
        last_size = -1
        while !done[]
            if filesize(cachefile) != last_size
                last_size = filesize(cachefile)
                try send("update_display_data") catch e; @error "Live plot update failed" exception = e end
            end
            sleep(interval)
        end
    end
    try
        return f()
    finally
        done[] = true
        wait(poller)
        send("update_display_data")   # final state, including the last configurations
    end
end
