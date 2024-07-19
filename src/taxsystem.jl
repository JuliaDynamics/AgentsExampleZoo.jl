
using Agents, Random

@agent struct Payer(NoSpaceAgent)
    alive::Bool
    age::Int
    wage::Float64
    wealth::Float64
end

function taxsystem(; nagents = 100000)
    model = StandardABM(Payer; model_step!, container = Vector, rng = Xoshiro(42))
    for _ in 1:nagents
        add_agent!(model, true, rand(abmrng(model), 20:30), rand(abmrng(model), 500:5000), 0)
    end
    return model
end

function model_step!(model)
    Threads.@threads for agent in allagents(model)
        tax_agent!(agent)
    end
end

function tax_agent!(agent)
    !agent.alive && return
    agent.age += 1
    agent.wealth += agent.wage - (agent.wage < 1000 ? 0.0 : agent.wage * 0.2)
    agent.alive = rand(abmrng(model)) < 0.02 ? false : true
end
