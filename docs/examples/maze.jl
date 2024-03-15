# # Maze Solver
# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../maze.mp4" type="video/mp4">
# </video>
# ```
# Consider a scenario where a walker agent is stuck in a maze. Finding the shortest path through an
# arbitrary maze or map is simulated using a [`Pathfinding.AStar`](@ref) and its `walkmap` map property.

# ## Setup
using Agents, Agents.Pathfinding
using FileIO # To load images you also need ImageMagick available to your project

# The `Walker` agent needs no special property, just the `id` and `position` from [`@agent`](@ref).
@agent struct Walker(GridAgent{2}) end

# The maze is stored as a simple .bmp image, where each pixel corresponds to a position on the grid.
# White pixels correspond to walkable regions of the maze.
function initialize_model(maze_map)
    ## Load the maze from the image file. White values can be identified by a
    ## non-zero red component
    maze = BitArray(map(x -> x.r > 0, maze_map))
    ## The size of the space is the size of the maze
    space = GridSpace(size(maze); periodic = false)
    ## Create a pathfinder using the AStar algorithm by providing the space and specifying
    ## the `walkmap` parameter for the pathfinder.
    ## Since we are interested in the most direct path to the end, the default
    ## `DirectDistance` is appropriate.
    ## `diagonal_movement` is set to false to prevent cutting corners by going along
    ## diagonals.
    pathfinder = AStar(space; walkmap=maze, diagonal_movement=false)
    model = StandardABM(Walker, space; agent_step!)
    ## Place a walker at the start of the maze
    add_agent!((1, 4), model)
    ## The walker's movement target is the end of the maze.
    plan_route!(model[1], (41, 32), pathfinder)

    return model, pathfinder
end

# ## Dynamics
# Stepping the agent is a trivial matter of calling [`move_along_route!`](@ref) to move it along it's path to
# the target.
agent_step!(agent, model) = move_along_route!(agent, model, pathfinder)

## Our sample walkmap
map_url =
    "https://raw.githubusercontent.com/JuliaDynamics/" *
    "JuliaDynamics/master/videos/agents/maze.bmp"
maze_map = load(download(map_url));
model, pathfinder = initialize_model(maze_map)

# ## Visualization
# Visualizing the `Walker` move through the maze is handled through [`InteractiveDynamics.abmplot`](@ref).
using CairoMakie

# The `heatarray` keyword argument allows plotting the maze as a heatmap behind the agent.
abmvideo(
    "maze.mp4",
    model;
    figurekwargs = (size =(700,700),),
    frames=60,
    framerate=30,
    agent_color=:red,
    agent_size=11,
    heatarray = _ -> pathfinder.walkmap,
    add_colorbar = false,
)

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../maze.mp4" type="video/mp4">
# </video>
# ```
