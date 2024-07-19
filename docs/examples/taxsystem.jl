# !!! info "This model is predefined and can be accessed with `AgentsExampleZoo.taxsystem()`"
#
# # TaxSystem
#
# Study this example to learn about
# - Parallelizing a model where agents are simulated independently
#
# ## Overview of TaxSystem
#
# This model is a toy tax system simulation with the main purpose to explain how parallelization 
# of the agent step can be achieved when agents don't interact with each other, but only evolve 
# following a set of rules. A tax system is a good candidate to show that because taxes can have
# heterogeneous effects on the wealth of the agents depending on some of their characteristics, and
# at the same time there is no need for any interaction between agents to simulate such a system.

using Agents, Random

# the Payer agent contains the necessary characteristics to simulate its
# taxation in this toy model. In a real application, the properties can be
# much more than these
@agent struct Payer(NoSpaceAgent)
    alive::Bool
    age::Int
    wage::Float64
    wealth::Float64
end

# Here we create the model, which contains a certain number of agents with a random
# age and a random wage each. The accumulated wealth at the start of the simulation is
# zero.
function taxsystem(; nagents = 100000)
    model = StandardABM(Payer; model_step!, container = Vector, rng = Xoshiro(42))
    for _ in 1:nagents
        add_agent!(model, true, rand(abmrng(model), 20:30), rand(abmrng(model), 500:5000), 0)
    end
    return model
end

# To parallelize the stepping function we use a model step because it allows the loop
# updating the agents. Since the `tax_agent!` function evolves each agent without updating
# any other agent inside the function, it is thread-safe and so the simulation can be easily
# parallelized with `Threads.@threads`
function model_step!(model)
    Threads.@threads for agent in allagents(model)
        tax_agent!(agent)
    end
end

# In the simulation agents only get older (eventually dying) and accumulate their residual wage
# after paying taxes
function tax_agent!(agent)
    !agent.alive && return
    agent.age += 1
    agent.wealth += agent.wage - (agent.wage < 1000 ? 0.0 : agent.wage * 0.2)
    agent.alive = rand(abmrng(model)) < 0.02 ? false : true
end

# 
model = taxsystem()

# Run the example with a different number of threads to see the speed-up, on the tested machine
# the model with 6 threads was 3.4 times faster than with 1 thread
@time step!(model, 100);
