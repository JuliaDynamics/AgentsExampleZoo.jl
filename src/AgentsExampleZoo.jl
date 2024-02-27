
module AgentsExampleZoo

using Pkg
try
    using Pkg
    Pkg.develop(url="https://github.com/JuliaDynamics/Agents.jl.git")
    using AgentsExampleZoo
catch
    Pkg.develop(path=joinpath(DEPOT_PATH[1],"dev","Agents"))
    using AgentsExampleZoo
end

include("daisyworld.jl")
include("flocking.jl")
include("rabbit_fox_hawk.jl")
include("schelling.jl")
include("sir.jl")
include("zombies.jl")

end
