# # Spatial Rock-Paper-Scissors 

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../Rock_Paper_Scissors.mp4" type="video/mp4">
# </video>
# ```

# The simulation implements the model described in [Reichenbach, T., Mobilia, M. & Frey, E. (2007). Mobility promotes and jeopardizes biodiversity in rock-paper-scissors game.](https://www.nature.com/articles/nature06095)

# The agent-based model simulation describes the evolution of 3 competing strategies ("Rock", "Paper" and "Scissors") that interact through cyclic, nonhierarchical interactions.
# To be more precise, the interactions follow a Rock-Paper-Scissors construction:
# * Rock + Scissors --> Rock
# * Scissors + Paper --> Scissors
# * Paper + Rock --> Paper

# Agents interact with their nearest 4 neighbours through selection or reproduction, both of which reactions occur as Poisson processes at rates $\sigma$ and $\mu$.
# In addition, the model explores the effect of mobility on the diversity of the population via the exchange rate $\epsilon$.

# * Selection reflects cyclic dominance: Rock --> Scissors --> Paper --> Rock
# * Reproduction of strategies is only allowed on empty neighbouring sites, to mimic a finite carrying capacity of the system
# * Mobility is represented via $\epsilon$, this exchange rate represent the likelihood of agents to swap position with a neighbouring individual or hop onto an empty neighbouring site.

# Whether selection, reproduction or mobility occurs is computed according to the reaction rates using the [Gillespie algorithm](https://en.wikipedia.org/wiki/Gillespie_algorithm).

# The spatial rock-paper-scissors model shows that for low mobility the diversity of the population is maintained, and complex spatio-temporal patterns arise that exhibit coexistence of strategies. 
# On the other hand, for high mobility a single strategy dominates the population eliminating diversity.

# # Choose the space
# The 3 subpopulations are arranged in a two-dimensional square lattice with periodic boundary conditions. An agent can only interact with its 4 nearest neighbours, therefore we use `metric = :manhattan`.
using Agents, Random

dims = (100, 100)
space = GridSpace(dims, periodic = true, metric = :manhattan)

# # Define the agent type

@agent Strategy GridAgent{2} begin
    type::Symbol #:rock, :paper or :scissors
end

# We define the functions to create the specific types of agents

Rock(id, pos) = Strategy(id, pos, :rock)
Paper(id, pos) = Strategy(id, pos, :paper)
Scissors(id, pos) = Strategy(id, pos, :scissors)

# # Define the model

# We define the model with a seeded random number generator to make our simulation reproducible.
# The agents will be activated randomly.

seed = 23182
rng = MersenneTwister(seed)

model = AgentBasedModel(Strategy, space; rng, scheduler = Schedulers.randomly)

# # Model instantiation

# We have created the model but it is not populated with agents. Therefore, we will create an `initialize_model` function to populate the model.

# The parameters of our model will be the number of agents of each type and the reaction rates.

function initialize_model(;
    #agents
    n_rock = 3300,
    n_paper = 3300,
    n_scissors = 3300,
    #space
    dims = (100, 100),
    #reaction rates
    selection_rate = 1.0,
    reproduction_rate = 1.0,
    exchange_rate = 0.7, 
    #prng
    seed = 23182,
    )
    
    rng = MersenneTwister(seed)
    
    #space
    space = GridSpace(dims, periodic = true, metric = :manhattan)
    
    #model properties
    properties = (
        n_rock = n_rock,
        n_paper = n_paper,
        n_scissors = n_scissors,
        selection_rate = selection_rate,
        reproduction_rate = reproduction_rate,
        exchange_rate = exchange_rate,
    )
    
    #model
    model = AgentBasedModel(Strategy, space; properties, rng, scheduler = Schedulers.randomly)
    
    #Add agents to the model to a random position
    for _ in 1:n_rock
        add_agent_pos!(Rock(nextid(model), random_position(model)), model)
    end

    for _ in 1:n_paper
        add_agent_pos!(Paper(nextid(model), random_position(model)), model)
    end
    
    for _ in 1:n_scissors
        add_agent_pos!(Scissors(nextid(model), random_position(model)), model)
    end
    
    return model
end

rockpaperscissors = initialize_model()

# # Define step functions

# Agents interact with their nearest neighbours through selection or reproduction, both of which reactions occur as Poisson processes at rates $\sigma$ and $\mu$.
# Agents can also swap positions with a nighbouring individual or hop onto an empty neighbouring site at a rate $\epsilon$.

# Overall, the agent step is defined via the Gillespie algorithm.

function strategy_step!(strategy, model)
    #propensities
    a1 = model.selection_rate * nagents(model)
    a2 = model.reproduction_rate * nagents(model)
    a3 = model.exchange_rate * nagents(model)
    
    #total propensities
    a0 = a1 + a2 + a3
    
    p = rand(model.rng)
    if 0 <= p < a1/a0
        selection_RPS!(strategy, model)
    elseif a1/a0 <= p < (a1+a2)/a0
        reproduce!(strategy, model)
    elseif (a1+a2)/a0 <= p < 1
        swap!(strategy, model)
    end
end

# Selection reflects cyclic dominance: Rock --> Scissors --> Paper --> Rock

function selection_RPS!(strategy, model)
    contender = random_nearby_agent(strategy, model) 
    if !isnothing(contender)
        pos_contender = contender.pos
        if strategy.type == :rock && contender.type == :scissors
            kill_agent!(contender, model)
        elseif strategy.type == :scissors && contender.type == :paper
            kill_agent!(contender, model)
        elseif strategy.type == :paper && contender.type == :rock
            kill_agent!(contender, model)
        end
    end 
    return
end

# Reproduction of strategies is only allowed on empty neighbouring sites

# The function `positions_empty_neighbours` returns an array with the positions of empty neighbouring sites.
# If all the neighbouring sites are occupied, it returns `nothing`.

function reproduce!(strategy, model)
    pos_offspring = positions_empty_neighbours(strategy.pos, model)
    if !isnothing(pos_offspring)
        id = nextid(model)
        offspring =  Strategy(id, pos_offspring[1], strategy.type)
        add_agent_pos!(offspring, model)
    end
    return
end

function positions_empty_neighbours(pos, model)
    array_empty_neighbours = Tuple{Int64, Int64}[]
    for i in nearby_positions(pos, model)
        if isempty(i, model)
            push!(array_empty_neighbours, i)  
        end
    end
    
    isempty(array_empty_neighbours) ?  nothing : array_empty_neighbours
end

# Mobility is represented via $\epsilon$, this exchange rate represent the likelihood of agents to swap position with a neighbouring individual or hop onto an empty neighbouring site.
# Note: the `swap!` function is not implemented for `GridSpaceSingle`.

# The function `random_nearby_position` returns a random neighbouring position.

function swap!(strategy, model)
    rand_pos = random_nearby_position(strategy.pos, model)
    
    if isempty(rand_pos, model)
        move_agent!(strategy, rand_pos, model)
    else
        strategy_pos = strategy.pos
        id = ids_in_position(rand_pos, model)[1]
        other_agent = model[id]
        move_agent!(strategy, rand_pos, model)
        move_agent!(other_agent, strategy_pos, model)   
    end
    return
end

function random_nearby_position(pos, model)
    array_nearby_positions = collect(nearby_positions(pos, model))
    
    num_neighbours = length(array_nearby_positions)
    rand_num = rand(model.rng, 1:num_neighbours)
    
    return array_nearby_positions[rand_num]
end

# # Animate the evolution

# The spatial rock-paper-scissors simulation generates a complex spatio-temporal patterns, therefore we want to animate the evolution of the system.

using InteractiveDynamics, CairoMakie

# We first define the plot arguments we want to modify.

function strategycolor(a)
    if a.type == :rock
        :blue
    elseif a.type == :paper
        :yellow
    else
        :red
    end
end

plotkwargs = (;
    ac = strategycolor,
    am = :rect,
)

# A static plot is useful as an initial visualiation of the model

fig, _ = abmplot(rockpaperscissors;
plotkwargs...)
fig

# Then, we animate the evolution of the system.

abmvideo(
    "Rock_Paper_Scissors.mp4",
    rockpaperscissors,
    strategy_step!;
    frames = 500,
    framerate = 8,
    title = "Spatial Rock-Paper-Scissors game",
    plotkwargs...,
)

# ```@raw html
# <video width="auto" controls autoplay loop>
# <source src="../Rock_Paper_Scissors.mp4" type="video/mp4">
# </video>
# ```

# In Reichenbach et al. (2007), the authors explain that low mobility (described by a low exchange rate $\epsilon$) allows a coexistence of types,
# this means that diversity is kept in the population. However, for high mobility (high exchange rate $\epsilon$) a single type dominates the population. Therefore, the population becomes uniform and diversity is lost.