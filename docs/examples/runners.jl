# # Mountain Runners
# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../runners.mp4" type="video/mp4">
# </video>
# ```
#
# Let's consider a race to the top of a mountain. Runners have been scattered about
# a map in some low lying areas and need to find the best path up to the peak.
#
# We'll use [`Pathfinding.AStar`](@ref) and a [`Pathfinding.PenaltyMap`](@ref) to simulate this.

# ## Setup
using Agents, Agents.Pathfinding
using Random
using FileIO # To load images you also need ImageMagick available to your project

@agent struct Runner(GridAgent{2}) end

# Our agent, as you can see, is very simple. Just an `id` and `pos`ition provided by
# [`@agent`](@ref). The rest of the dynamics of this example will be provided by the model.

function initialize(map_url; goal = (128, 409), seed = 88)
    ## Load an image file and convert it do a simple representation of height
    heightmap = floor.(Int, convert.(Float64, load(download(map_url))) * 255)
    ## The space of the model can be obtained directly from the image.
    ## Our example file is (400, 500).
    space = GridSpace(size(heightmap); periodic = false)
    ## The pathfinder. We use the `MaxDistance` metric since we want the runners
    ## to look for the easiest path to run, not just the most direct.
    pathfinder = AStar(space; cost_metric = PenaltyMap(heightmap, MaxDistance{2}()))
    model = StandardABM(
        Runner,
        space;
        agent_step!,
        rng = MersenneTwister(seed),
        properties = Dict(:goal => goal, :pathfinder => pathfinder)
    )
    for _ in 1:10
        ## Place runners in the low-lying space in the map.
        runner = add_agent!((rand(abmrng(model), 100:350), rand(abmrng(model), 50:200)), model)
        ## Everyone wants to get to the same place.
        plan_route!(runner, goal, model.pathfinder)
    end
    return model
end

# The example heightmap we use here is a small region of countryside in Sweden, obtained
# with the [Tangram heightmapper](https://github.com/tangrams/heightmapper).

# ## Dynamics
# With the pathfinder in place, and all our runners having a goal position set, stepping
# is now trivial.

agent_step!(agent, model) = move_along_route!(agent, model, model.pathfinder)

# ## Let's Race
# %% #src
# Plotting is simple enough. We just need to use the [`InteractiveDynamics.abmplot`](@ref)
# for our runners, and display the heightmap for our reference. A better interface to do
# this is currently a work in progress.
using CairoMakie

# We load the sample heightmap
map_url =
    "https://raw.githubusercontent.com/JuliaDynamics/" *
    "JuliaDynamics/master/videos/agents/runners_heightmap.jpg"
model = initialize(map_url)

# and plot
const ABMPlot = Agents.get_ABMPlot_type()
function Agents.static_preplot!(ax::Axis3, p::ABMPlot)
    return scatter!(ax, model.goal; color = (:red, 50), marker = 'x')
end

abmvideo(
    "runners.mp4",
    model;
    figurekwargs = (size = (700, 700),),
    frames = 200,
    framerate = 45,
    agent_color = :black,
    agent_size = 8,
    agentsplotkwargs = (strokecolor = :white, strokewidth = 2),
    heatarray = model -> penaltymap(model.pathfinder),
    heatkwargs = (colormap = :terrain,),
)

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../runners.mp4" type="video/mp4">
# </video>
# ```
