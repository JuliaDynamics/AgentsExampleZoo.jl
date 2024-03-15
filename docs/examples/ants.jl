# # Ants
# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../antworld.mp4" type="video/mp4">
# </video>
# ```
#
# Study this example to learn about:
# - Simple agent properties with complex model interactions
# - Diffusion of a quantity in a grid space
# - Including a "surface property" in the model
# - Counting time in the model and having time-dependent dynamics
# - Performing interactive scientific research
#
# ## Overview of Ants
#
# This model explores the behavior of ant colonies in collecting food and communicating using 
# chemicals that individual ants leave in the world. 
#
# AntWorld has one nest and three sources of food at varying distances from the nest.
# Each ant has the tendency to keep moving in the direction they are currently facing,
# with some randomness. They will follow pheromone trails to food. This pheromone trail dissipates (spreads)
# to surrounding areas. It also evaporates over time. 

# In addition, they have a chemical trail to follow back to the nest. This trail is static. 
#
# Ants set out from the nest in a random manner, seeking out sources of food. 
# When they find food, they pick up one unit of it, turn around, and head back to the nest while depositing
# pheromones for other ants to find and follow back to the food. 

# ## Defining the ant type

# `Ant` has three values (other than the required
# `id` and `pos` for any agent that lives on a [`GridSpaceSingle`](@ref)). 
# Each ant has a `has_food` attribute, showing if the ant is currently carrying food, 
# a `facing_direction` (a number between 1 and 8) describing the direction they are heading,
# and a `food_collected` which is the amount of food an individual ant has collected.
using Agents
using Random
using Logging

@agent struct Ant(GridAgent{2})
    has_food::Bool
    facing_direction::Int
    food_collected::Int
    food_collected_once::Bool
end

# `adjacent_dict` defines the adjacent positions to the current position, and is also
# associated with the direction the ant is facing.
const adjacent_dict = Dict(
    1 => (0, -1), # S
    2 => (1, -1), # SE
    3 => (1, 0), # E
    4 => (1, 1), # NE
    5 => (0, 1), # N
    6 => (-1, 1), # NW
    7 => (-1, 0), # W
    8 => (-1, -1), # SW
    )

const number_directions = length(adjacent_dict)

# ## Model Properties
#
# The `AntWorldProperties` structure defines the properties of the model. 
mutable struct AntWorldProperties
    pheromone_trails::Matrix
    food_amounts::Matrix
    nest_locations::Matrix 
    food_source_number::Matrix 
    food_collected::Int  
    diffusion_rate::Int 
    x_dimension::Int
    y_dimension::Int
    nest_size::Int
    evaporation_rate::Int
    pheromone_amount::Int
    spread_pheromone::Bool
    pheromone_floor::Int
    pheromone_ceiling::Int
end

# A convenience method to truncate a Float to an integer. 
int(x::Float64) = trunc(Int, x)

# ## Initialize Model
#
# This method sets up the model and the agents for AntWorld.
# 
# It starts by setting the random number generator's seed. 
# Then, it calculates the furthest distance possible an agent could be from another point 
# in the world, for normalization purposes. 
# It then calculates the center of the grid. 
# 
# Then it initializes matrices for the nest location, pheromone trails, amounts of food, and food source numbers. 
# These are the same dimensions as AntWorld grid and are standard Julia arrays.
# 
# Next it establishes the center positions of each food source. 
# Now we iterate over all the positions in the grid and set values in the corresponding
# Julia array which is then sent to the model properties. 
# The model properties is then used to create the model and subsequently the Ants (agents) are 
# created. 
function initialize_model(;number_ants::Int = 125, dimensions::Tuple = (70, 70), diffusion_rate::Int = 50, food_size::Int = 7, random_seed::Int = 2954, nest_size::Int = 5, evaporation_rate::Int = 10, pheromone_amount::Int = 60, spread_pheromone::Bool = false, pheromone_floor::Int = 5, pheromone_ceiling::Int = 100)
    @info "Starting the model initialization \n  number_ants: $(number_ants)\n  dimensions: $(dimensions)\n  diffusion_rate: $(diffusion_rate)\n  food_size: $(food_size)\n  random_seed: $(random_seed)"
    rng = Random.Xoshiro(random_seed)

    furthest_distance = sqrt(dimensions[1] ^ 2 + dimensions[2] ^ 2)

    x_center = dimensions[1] / 2 
    y_center = dimensions[2] / 2
    @debug "x_center: $(x_center) y_center: $(y_center)"

    nest_locations = zeros(Float32, dimensions)
    pheromone_trails = zeros(Float32, dimensions)

    food_amounts = zeros(dimensions) 
    food_source_number = zeros(dimensions)

    food_center_1 = (int(x_center + 0.6 * x_center), int(y_center))
    food_center_2 = (int(0.4 * x_center), int(0.4 * y_center))
    food_center_3 = (int(0.2 * x_center), int(y_center + 0.8 * y_center))
    @debug "Food Center 1: $(food_center_1) Food Center 2: $(food_center_2) Food Center 3: $(food_center_3)"

    food_collected = 0

    for x_val in 1:dimensions[1]
        for y_val in 1:dimensions[2]
            nest_locations[x_val, y_val] = ((furthest_distance - sqrt((x_val - x_center) ^ 2 + (y_val - y_center) ^ 2)) / furthest_distance) * 100
            food_1 = (sqrt((x_val - food_center_1[1]) ^ 2 + (y_val - food_center_1[2]) ^ 2)) < food_size
            food_2 = (sqrt((x_val - food_center_2[1]) ^ 2 + (y_val - food_center_2[2]) ^ 2)) < food_size
            food_3 = (sqrt((x_val - food_center_3[1]) ^ 2 + (y_val - food_center_3[2]) ^ 2)) < food_size
            food_amounts[x_val, y_val] = food_1 || food_2 || food_3 ? rand(rng, [1, 2]) : 0
            if food_1
                food_source_number[x_val, y_val] = 1
            elseif food_2
                food_source_number[x_val, y_val] = 2
            elseif food_3
                food_source_number[x_val, y_val] = 3
            end  
        end
    end

    properties = AntWorldProperties(
        pheromone_trails,
        food_amounts,
        nest_locations, 
        food_source_number, 
        food_collected, 
        diffusion_rate, 
        dimensions[1], 
        dimensions[2], 
        nest_size, 
        evaporation_rate, 
        pheromone_amount,
        spread_pheromone, 
        pheromone_floor,
        pheromone_ceiling
        ) 

    model = StandardABM(
        Ant, 
        GridSpace(dimensions, periodic = false); 
        properties,
        rng, 
        agent_step! = ant_step!,
        model_step! = antworld_step!,
        scheduler = Schedulers.Randomly(),
        container = Vector
    )

    for n in 1:number_ants
        add_agent!((x_center, y_center), model, false, rand(abmrng(model), 1:8), 0, false)
    end
    @info "Finished the model initialization"
    return model
end

# ## Support Methods
#
# ### Change direction
#
# This method is used to detect chemical gradients for the ant to turn towards. By accepting
# a `Matrix`, we can generically use this for both following pheromone trails and the way home. 
function detect_change_direction(agent::Ant, model_layer::Matrix)
    x_dimension = size(model_layer)[1]
    y_dimension = size(model_layer)[2]
    left_pos = adjacent_dict[mod1(agent.facing_direction - 1, number_directions)]
    right_pos = adjacent_dict[mod1(agent.facing_direction + 1, number_directions)]

    scent_ahead = model_layer[mod1(agent.pos[1] + adjacent_dict[agent.facing_direction][1], x_dimension), 
        mod1(agent.pos[2] + adjacent_dict[agent.facing_direction][2], y_dimension)]
    scent_left = model_layer[mod1(agent.pos[1] + left_pos[1], x_dimension), 
        mod1(agent.pos[2] + left_pos[2], y_dimension)]
    scent_right = model_layer[mod1(agent.pos[1] + right_pos[1], x_dimension), 
        mod1(agent.pos[2] + right_pos[2], y_dimension)]
     
    if (scent_right > scent_ahead) || (scent_left > scent_ahead)
        if scent_right > scent_left
            agent.facing_direction = mod1(agent.facing_direction + 1, number_directions)
        else
            agent.facing_direction =  mod1(agent.facing_direction - 1, number_directions)
        end
    end
end

# Convenience function to have the Ant turn around. 
turn_around(agent) = agent.facing_direction = mod1(agent.facing_direction + number_directions / 2, number_directions)

# ### Wiggle
#
# Introduces the ability for some randomness in the ants behavior. Even when following a trail,
# this will cause ants to Randomly() face somewhere in a 45 degree direction of what is ideal for them. 
function wiggle(agent::Ant, model)
    direction = rand(abmrng(model), [0, rand(abmrng(model), [-1, 1])])
    agent.facing_direction = mod1(agent.facing_direction + direction, number_directions)
end

# ### Apply pheromones
#
# Applies pheromone to the grid. Used by the `Ant` when carrying food back to the nest. By default it only applies
# pheromone to the grid the `Ant` is currently on, but there is an option to spread the pheromone to perpendicular
# spaces at the same time. 
function apply_pheromone(agent::Ant, model; pheromone_val::Int = 60, spread_pheromone::Bool = false)
    model.pheromone_trails[agent.pos...] += pheromone_val
    model.pheromone_trails[agent.pos...]  = model.pheromone_trails[agent.pos...] ≥ model.pheromone_floor ? model.pheromone_trails[agent.pos...] : 0

    if spread_pheromone
        left_pos = adjacent_dict[mod1(agent.facing_direction - 2, number_directions)]
        right_pos = adjacent_dict[mod1(agent.facing_direction + 2, number_directions)]

        model.pheromone_trails[mod1(agent.pos[1] + left_pos[1], model.x_dimension), 
            mod1(agent.pos[2] + left_pos[2], model.y_dimension)] += (pheromone_val / 2)
        model.pheromone_trails[mod1(agent.pos[1] + right_pos[1], model.x_dimension), 
            mod1(agent.pos[2] + right_pos[2], model.y_dimension)] += (pheromone_val / 2)
    end
end

# ### Diffuse
# 
# Diffuse is the method used by the world to spread the pheromone chemicals to adjacent cells. 
# The spread will place (the current amount on grid space * diffusion rate / number of directions) to each adjacent grid space.
# Then the current space is reduced by the amount that was spread to the surrounding areas. 
function diffuse(model_layer::Matrix, diffusion_rate::Int)
    x_dimension = size(model_layer)[1]
    y_dimension = size(model_layer)[2]

    for x_val in 1:x_dimension
        for y_val in 1:y_dimension
            sum_for_adjacent = model_layer[x_val, y_val] * (diffusion_rate / 100) / number_directions
            for (_, i) in adjacent_dict
                model_layer[mod1(x_val + i[1], x_dimension), mod1(y_val + i[2], y_dimension)] += sum_for_adjacent
            end
            model_layer[x_val, y_val] *= ((100 - diffusion_rate) / 100)
        end
    end
end 

# ## Agent Step
# 
# The function to perform the ant steps. It is split into two main branches - does the `Ant` have food or not. \
# If the `Ant` has food, then if it is at a nest location, it drops off the food and turns around. If not at a 
# nest location, then it determines the best way back to the nest. Finally it lays down some pheromone. \
# If the `Ant` doesn't have food, but it is at a food location, it picks up food and turns around. If it's not at a food
# location, it tries to follow a pheromone trail to food. \
# Then it applies a wiggle (random search if without food) and then moves the agent. 
function ant_step!(agent::Ant, model)
    @debug "Agent State: \n  pos: $(agent.pos)\n  pos_type:$(typeof(agent.pos)) facing_direction: $(agent.facing_direction)\n  has_food: $(agent.has_food)"
    if agent.has_food
        if model.nest_locations[agent.pos...] > 100 - model.nest_size
            @debug "$(agent.n) arrived at nest with food"
            agent.food_collected += 1
            agent.food_collected_once = true
            model.food_collected += 1
            agent.has_food = false
            turn_around(agent)
        else 
            detect_change_direction(agent, model.nest_locations)
        end
        apply_pheromone(agent, model, pheromone_val = model.pheromone_amount)
    else
        if model.food_amounts[agent.pos...] > 0
            @debug "$(agent.n) has found food."
            agent.has_food = true
            model.food_amounts[agent.pos...] -= 1
            apply_pheromone(agent, model, pheromone_val = model.pheromone_amount)
            turn_around(agent)
        elseif model.pheromone_trails[agent.pos...] > model.pheromone_floor
            detect_change_direction(agent, model.pheromone_trails)
        end
    end
    wiggle(agent, model)
    move_agent!(agent, (mod1(agent.pos[1] + adjacent_dict[agent.facing_direction][1], model.x_dimension), mod1(agent.pos[2] + adjacent_dict[agent.facing_direction][2], model.y_dimension)), model) 
end

# ## Model Step
# 
# The model step for `AntWorld`. First, it diffuses the chemicals out across the grid. \
# Then it evaporates some of pheromone from every grid space. \
# The map! function reduces the amount of pheromone_trails.
function antworld_step!(model)
    diffuse(model.pheromone_trails, model.diffusion_rate)
    map!((x) -> x ≥ model.pheromone_floor ? x * (100 - model.evaporation_rate) / 100 : 0., model.pheromone_trails, model.pheromone_trails)

    if mod1(abmtime(model), 100) == 100
        @info "Step $(abmtime(model))"
    end
end

# ## Displaying and Running
using CairoMakie

# Establish a `ConsoleLogger` to follow what is happening in the model run. 
debuglogger = ConsoleLogger(stderr, Logging.Info)

# ### Displaying heatmap
#
# This function builds a heat map based on various map properties to display in the grid. \
# It shows the nest location, food locations, and pheromone trails. \
# Set the value of the heatmap to NaN so it displays as white
function heatmap(model)
    heatmap = zeros((model.x_dimension, model.y_dimension))
    for x_val in 1:model.x_dimension
        for y_val in 1:model.y_dimension
            if model.nest_locations[x_val, y_val] > 100 - model.nest_size
                heatmap[x_val, y_val] = 150
            elseif model.food_amounts[x_val, y_val] > 0
                heatmap[x_val, y_val] = 200
            elseif model.pheromone_trails[x_val, y_val] > model.pheromone_floor
                heatmap[x_val, y_val] = model.pheromone_trails[x_val, y_val] ≥ model.pheromone_floor ? clamp(model.pheromone_trails[x_val, y_val], model.pheromone_floor, model.pheromone_ceiling) : 0
            else
                heatmap[x_val, y_val] = NaN
            end
        end
    end
    return heatmap
end
 
# Turn the ant red when it has food. 
ant_color(ant::Ant) = ant.has_food ? :red : :black

# #### Keywords to use for plotting. 
# ac (agent color) = ant_color function \
# as (agent size) = the size of the agent \
# am (agent model) = the icon to use for the agent, here a diamond. 
plotkwargs = (
    agent_color = ant_color, agent_size = 20, agent_marker = '♦',
    heatarray = heatmap,
    heatkwargs = (colormap = Reverse(:viridis), colorrange = (0, 200),)
)

# #### Running the model. 
# There are two options, to explore or to simply get a video of the run. 
video = true
with_logger(debuglogger) do
    model = initialize_model(;number_ants = 125, random_seed = 6666, pheromone_amount = 60, evaporation_rate = 5)
    if !video    
        params = Dict(
            :evaporation_rate => 0:1:100,
            :diffusion_rate => 0:1:100,
        )

        has_food(agent) = agent.has_food

        adata = [(:food_collected_once, count)]
        mdata = [:food_collected]

        @info "Starting exploration"
        fig, ax, abmobs = abmplot(
            model;
            params,
            plotkwargs...,
            adata, alabels = ["Num Ants Collected"],
            mdata, mlabels = ["Total Food Collected"]
        )

        display(fig)
        @info "fig: $(fig)\n ax: $(ax)\n abmobs: $(abmobs)"
    else
        @info "Starting creating a video"
        abmvideo(
            "antworld.mp4",
            model;
            title = "Ant World",
            frames = 1000,
            plotkwargs...,
        )
    end
end
