# # Forest fire

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../forest.mp4" type="video/mp4">
# </video>
# ```

# The forest fire model is defined as a cellular automaton on a grid.
# A position can be empty or occupied by a tree which is ok, burning or burnt.
# We implement a slightly different ruleset to that of
# [Drossel and Schwabl (1992)](https://en.wikipedia.org/wiki/Forest-fire_model),
# so that our implementation can be compared with other ABM frameworks
#
# 1. A burning position turns into a burnt position
# 1. A tree will burn if at least one neighbor is burning

# The forest has an innate `density`, which is the proportion of trees initialized as
# `green`, however all trees that reside on the left side of the grid are `burning`.
# The model is also available from the `Models` module as [`Models.forest_fire`](@ref).

# ## Defining the core structures

# Cellular automata don't necessarily require an agent-like structure. Here we will
# demonstrate how a model focused solution is possible.
using Agents, Random
using CairoMakie

@agent struct Automata(GridAgent{2}) end

# The agent type `Automata` is effectively a dummy agent, for which we will invoke
# [`dummystep`](@ref) when stepping the model.

# We then make a setup function that initializes the model.
function forest_fire(; density = 0.7, griddims = (100, 100), seed = 2)
    space = GridSpaceSingle(griddims; periodic = false, metric = :manhattan)
    rng = Random.MersenneTwister(seed)
    ## The `trees` field is coded such that
    ## Empty = 0, Green = 1, Burning = 2, Burnt = 3
    forest = StandardABM(Automata, space; rng, model_step! = tree_step!,
                 properties = (trees = zeros(Int, griddims),), container = Vector)
    for I in CartesianIndices(forest.trees)
        if rand(abmrng(forest)) < density
            ## Set the trees at the left edge on fire
            forest.trees[I] = I[1] == 1 ? 2 : 1
        end
    end
    return forest
end

# ## Defining the step!

function tree_step!(forest)
    ## Find trees that are burning (coded as 2)
    for I in findall(isequal(2), forest.trees)
        for idx in nearby_positions(I.I, forest)
            ## If a neighbor is Green (1), set it on fire (2)
            if forest.trees[idx...] == 1
                forest.trees[idx...] = 2
            end
        end
        ## Finally, any burning tree is burnt out (2)
        forest.trees[I] = 3
    end
    return forest.trees
end

# ## Running the model
forest = forest_fire()

step!(forest, 1)
count(t == 3 for t in forest.trees) # Number of burnt trees on step 1

#

step!(forest, 10)
count(t == 3 for t in forest.trees) # Number of burnt trees on step 11

# Now we can do some data collection as well using an aggregate function `percentage`:

forest = forest_fire(griddims = (20, 20))
burnt_percentage(f) = count(t == 3 for t in f.trees) / prod(size(f.trees))
mdata = [burnt_percentage]

_, data = run!(forest, 10; mdata)
data

# Now let's plot the model. We use green for unburnt trees, red for burning and a
# dark red for burnt.
forest = forest_fire()
step!(forest, 1)

plotkwargs = (
    add_colorbar = false,
    heatarray = :trees,
    heatkwargs = (
        colorrange = (0, 3),
        colormap = cgrad([:white, :green, :red, :darkred]; categorical = true),
    ),
)
fig, _ = abmplot(forest; plotkwargs...)
fig

# or animate it
forest = forest_fire(density = 0.7, seed = 10)
abmvideo(
    "forest.mp4",
    forest;
    framerate = 5,
    frames = 20,
    spf = 5,
    title = "Forest Fire",
    plotkwargs...,
)

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../forest.mp4" type="video/mp4">
# </video>
# ```
