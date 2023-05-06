# # Ants 

using Agents
using Random

@agent Ant GridAgent{2} begin
    has_food::Bool
end

function initalize_model(;number_ants = 50, dimensions = (200, 200), diffusion_rate = 10, food_size = 5, random_seed = 2954)
    x_center = dimensions[1] / 2
    y_center = dimensions[2] / 2

    nest_locations = zeros(Float32, dimensions)
    pheremone_trails = zeros(Float32, dimensions)

    food_locations = falses(dimensions)
    food_center_1 = (0.6 * x_center, y_center)
    food_center_2 = (x_center + 0.6 * x_center, y_center + 0.6 * y_center)
    food_center_3 = (x_center + 0.8 * x_center, 0.8 * y_center)

    food_collected = 0

    for x_val in 1:dimensions[1]
        for y_val in 1:dimensions[2]
            nest_locations[x_val, y_val] = 200 - sqrt((x_val - x_center) ^ 2 + (y_val - y_center) ^ 2)
            food_locations[x_val, y_val] = sqrt((x_val - food_center_1[1]) ^ 2 + (y_val - food_center_1[2]) ^ 2) < food_size ? true : false
            food_locations[x_val, y_val] = sqrt((x_val - food_center_2[1]) ^ 2 + (y_val - food_center_2[2]) ^ 2) < food_size ? true : false
            food_locations[x_val, y_val] = sqrt((x_val - food_center_3[1]) ^ 2 + (y_val - food_center_3[2]) ^ 2) < food_size ? true : false
        end
    end

    properties = (nest_locations = nest_locations, food_locations = food_locations, 
        food_collected = food_collected, pheremone_trails = pheremone_trails, diffusion_rate = diffusion_rate) 

    model = UnremoveableABM(
        Ant, 
        GridSpace(dimensions, periodic = false); 
        properties,
        rng = Random.Xoshiro(random_seed), 
        scheduler = Schedulers.Randomly()
    )

    for n in 1:number_ants
        agent = Ant(n, (x_center, y_center), false)
        add_agent_pos!(agent, model)
    end

    return model
end

