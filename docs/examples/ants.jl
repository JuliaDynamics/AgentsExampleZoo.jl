# # Ants 

using Agents
using Random
using Logging

debuglogger = ConsoleLogger(stderr, Logging.Info)

function int(x::Float64)
    return trunc(Int, x)
end

@agent Ant GridAgent{2} begin
    has_food::Bool
    facing_direction::Int
    food_collected::Int
end

AntWorld = ABM{<:GridSpace, Ant}

direction_dict = Dict(
    1 => (0, -1), # S
    2 => (1, -1), # SE
    3 => (1, 0), # E
    4 => (1, 1), # NE
    5 => (0, 1), # N
    6 => (-1, 1), # NW
    7 => (-1, 0), # W
    8 => (-1, -1), # SW
    )

number_directions = 8

mutable struct AntWorldProperties
    nest_locations::Matrix 
    food_locations::Matrix 
    food_collected::Int 
    pheremone_trails::Matrix 
    diffusion_rate::Int 
    tick::Int
    x_dimension::Int
    y_dimension::Int
    nest_size::Int
    evaporation_rate::Int
    spread_pheremone::Bool
end

function initalize_model(;number_ants::Int = 125, dimensions::Tuple = (70, 70), diffusion_rate::Int = 50, food_size::Int = 7, random_seed::Int = 2954, nest_size::Int = 5, evaporation_rate::Int = 10, spread_pheremone::Bool = false)
    @info "Starting the model initialization \n  number_ants: $(number_ants)\n  dimensions: $(dimensions)\n  diffusion_rate: $(diffusion_rate)\n  food_size: $(food_size)\n  random_seed: $(random_seed)"
    rng = Random.Xoshiro(random_seed)

    furthest_distance = sqrt(dimensions[1] ^ 2 + dimensions[2] ^ 2)

    x_center = dimensions[1] / 2 
    y_center = dimensions[2] / 2
    @debug "x_center: $(x_center) y_center: $(y_center)"

    nest_locations = zeros(Float32, dimensions)
    pheremone_trails = zeros(Float32, dimensions)

    food_locations = falses(dimensions) 
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
            food_locations[x_val, y_val] = food_1 || food_2 || food_3    
        end
    end

    @debug "Nest Locations: \n $(nest_locations[100, 100]), $(nest_locations[100, 101])"
    #@debug "Food Locations: \n $(food_locations[180, 80]), $(food_locations[181, 79])"
    #@debug "Food Locations: \n $(food_locations[60, 100]), $(food_locations[61, 101])"
    #normalize!(nest_locations)

    properties = AntWorldProperties(
        nest_locations, 
        food_locations, 
        food_collected, 
        pheremone_trails, 
        diffusion_rate, 
        0, 
        dimensions[1], 
        dimensions[2], 
        nest_size, 
        evaporation_rate, 
        spread_pheremone
        ) 


    model = UnremovableABM(
        Ant, 
        GridSpace(dimensions, periodic = false); 
        properties,
        rng, 
        scheduler = Schedulers.Randomly()
    )

    for n in 1:number_ants
        agent = Ant(n, (x_center, y_center), false, rand(range(1, 8)), 0)
        @debug "Ant $(n) Details: \n Facing: $(agent.facing_direction)"
        add_agent_pos!(agent, model)
    end
    @info "Finished the model initialization"
    return model
end

function detect_change_direction(agent::Ant, model_layer::Matrix)
    x_dimension = size(model_layer)[1]
    y_dimension = size(model_layer)[2]
    left_pos = direction_dict[mod1(agent.facing_direction - 1, number_directions)]
    right_pos = direction_dict[mod1(agent.facing_direction + 1, number_directions)]

    scent_ahead = model_layer[mod1(agent.pos[1] + direction_dict[agent.facing_direction][1], x_dimension), 
        mod1(agent.pos[2] + direction_dict[agent.facing_direction][2], y_dimension)]
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

function wiggle(agent::Ant, model::AntWorld)
    direction = rand(model.rng, [0, rand(model.rng, [-1, 1])])
    agent.facing_direction = mod1(agent.facing_direction + direction, number_directions)
end

function apply_pheremone(agent::Ant, model::AntWorld; pheremone_val::Int = 60, spread_pheremone::Bool = false)
    model.pheremone_trails[agent.pos...] += pheremone_val

    if spread_pheremone
        left_pos = direction_dict[mod1(agent.facing_direction - 2, number_directions)]
        right_pos = direction_dict[mod1(agent.facing_direction + 2, number_directions)]

        model.pheremone_trails[mod1(agent.pos[1] + left_pos[1], model.x_dimension), 
            mod1(agent.pos[2] + left_pos[2], model.y_dimension)] += (pheremone_val / 2)
        model.pheremone_trails[mod1(agent.pos[1] + right_pos[1], model.x_dimension), 
            mod1(agent.pos[2] + right_pos[2], model.y_dimension)] += (pheremone_val / 2)
    end
end

function diffuse(model_layer::Matrix, diffusion_rate::Int)
    x_dimension = size(model_layer)[1]
    y_dimension = size(model_layer)[2]

    for x_val in 1:size(model_layer)[1]
        for y_val in 1:size(model_layer)[2]
            for add_x in [-1, 0, 1]
                for add_y in [-1, 0, 1]
                    if add_x ≠ 0 && add_y ≠ 0
                        model_layer[mod1(x_val + add_x, x_dimension), mod1(y_val + add_y, y_dimension)] += (diffusion_rate / 100) * model_layer[x_val, y_val] / number_directions
                    end
                end
            end
            model_layer[x_val, y_val] *= 1 - (diffusion_rate / 100)
        end
    end
end

function ant_step!(agent::Ant, model::AntWorld)
    @debug "Agent State: \n  pos: $(agent.pos)\n  facing_direction: $(agent.facing_direction)\n  has_food: $(agent.has_food)"
    if agent.has_food
        if model.nest_locations[agent.pos...] > 100 - model.nest_size
            @debug "$(agent.n) arrived at nest with food"
            agent.food_collected += 1
            agent.has_food = false
            agent.facing_direction = mod1(agent.facing_direction + number_directions / 2, number_directions)
        else 
            detect_change_direction(agent, model.nest_locations)
            apply_pheremone(agent, model)
        end
    else
        if model.food_locations[agent.pos...]
            @debug "$(agent.n) has found food."
            agent.has_food = true
            model.food_locations[agent.pos...] = false
            agent.facing_direction = mod1(agent.facing_direction + number_directions / 2, number_directions)
        elseif model.pheremone_trails[agent.pos...] > 5
            detect_change_direction(agent, model.pheremone_trails)
        end
    end
    wiggle(agent, model)
    move_agent!(agent, (mod1(agent.pos[1] + direction_dict[agent.facing_direction][1], model.x_dimension), mod1(agent.pos[2] + direction_dict[agent.facing_direction][2], model.y_dimension)), model) 
end

function antworld_step!(model::AntWorld)
    diffuse(model.pheremone_trails, model.diffusion_rate)
    # Reduce the amount of pheremone_trails
    map((x) -> x >= 5 ? x * model.evaporation_rate / 100 : 0 , model.pheremone_trails)
    model.tick += 1
    if mod1(model.tick, 100) == 100
        @info "Step $(model.tick)"
    end
end

#agent_df, model_df =
#    run!(model, ant_step!, antworld_step!, 1000)

using InteractiveDynamics
using GLMakie

GLMakie.activate!()

function heatmap(model::AntWorld)
    heatmap = fill(NaN, (model.x_dimension, model.y_dimension))
    for x_val in 1:model.x_dimension
        for y_val in 1:model.y_dimension
            if model.nest_locations[x_val, y_val] > 100 - model.nest_size
                heatmap[x_val, y_val] = 150
            elseif model.food_locations[x_val, y_val]
                heatmap[x_val, y_val] = 200
            elseif model.pheremone_trails[x_val, y_val] > 5
                heatmap[x_val, y_val] = clamp(model.pheremone_trails[x_val, y_val], 5, 100)
            else
                heatmap[x_val, y_val] = NaN
            end
        end
    end
    return heatmap
end
 
ant_color(ant::Ant) = ant.has_food ? :red : :black

plotkwargs = (
    ac = ant_color, as = 20, am = '♦',
    heatarray = heatmap,
    heatkwargs = (colormap = Reverse(:viridis), colorrange = (0, 200),)
)

with_logger(debuglogger) do
    model = initalize_model(;number_ants = 125, random_seed = 6666)

    abmvideo(
        "antworld.mp4",
        model,
        ant_step!,
        antworld_step!;
        title = "Ant World",
        frames = 1000,
        plotkwargs...,
    )
end