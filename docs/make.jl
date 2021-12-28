# %% Example files
NEW_EXAMPLES = [
    "Hegselmann-Krause opinion dynamics" => "hk.jl",
]
### TEETETETE
EXISTING_EXAMPLES = [
    # The following are sorted ALPHABETICALLY!!!
    "Bacteria Growth" => "growing_bacteria.jl",
    "Battle Royale" => "battle.jl",
    "Continuous space social distancing" => "social_distancing.jl",
    "Conway's game of life" => "game_of_life_2D_CA.jl",
    "Daisyworld" => "daisyworld.jl",
    "Forest fire" => "forest_fire.jl",
    "Fractal Growth" => "fractal_growth.jl",
    "Hegselmann-Krause opinion dynamics" => "hk.jl",
    "Maze Solver" => "maze.jl",
    "Mountain Runners" => "runners.jl",
    "Opinion spread" => "opinion_spread.jl",
    "Predator-Prey" => "predator_prey_fast.jl",
    "Sugarscape" => "sugarscape.jl",
    "Wealth distribution" => "wealth_distribution.jl",
    "Wright-Fisher model of evolution" => "wright-fisher.jl",
]


# %% Documentation building code (not to be touched)
# Load packages
cd(@__DIR__)
using Pkg;
Pkg.activate(@__DIR__);
const CI = get(ENV, "CI", nothing) == "true"
println("Loading Packages")
println("Documenter...")
using Documenter
println("Agents...")
using Agents
println("Literate...")
import Literate
println("InteractiveDynamics...")
using InteractiveDynamics

ENV["GKS_ENCODING"] = "utf-8"
println("Converting Examples...")


# %%
# download the themes
println("Theme-ing")
using DocumenterTools:Themes
import Downloads
for file in (
    "juliadynamics-lightdefs.scss",
    "juliadynamics-darkdefs.scss",
    "juliadynamics-style.scss",
)
    Downloads.download(
        "https://raw.githubusercontent.com/JuliaDynamics/doctheme/master/$file",
        joinpath(@__DIR__, file),
    )
end
# create the themes
for w in ("light", "dark")
    header = read(joinpath(@__DIR__, "juliadynamics-style.scss"), String)
    theme = read(joinpath(@__DIR__, "juliadynamics-$(w)defs.scss"), String)
    write(joinpath(@__DIR__, "juliadynamics-$(w).scss"), header * "\n" * theme)
end
# compile the themes
Themes.compile(
    joinpath(@__DIR__, "juliadynamics-light.scss"),
    joinpath(@__DIR__, "src/assets/themes/documenter-light.css"),
)
Themes.compile(
    joinpath(@__DIR__, "juliadynamics-dark.scss"),
    joinpath(@__DIR__, "src/assets/themes/documenter-dark.css"),
)

# %% Build examples with Literate.jl
indir = joinpath(@__DIR__, "examples")
outdir = joinpath(@__DIR__, "src", "examples")
rm(outdir; force = true, recursive = true) # cleans up previous examples
mkpath(outdir)

examples = isempty(NEW_EXAMPLES) ? EXISTING_EXAMPLES : NEW_EXAMPLES
built_examples = String[]
for (title, file) in examples
    Literate.markdown(joinpath(indir, file), outdir; credit = false)
    push!(built_examples, "examples/"*file[1:end-3]*".md")
end


# %%
println("Documentation Build")
ENV["JULIA_DEBUG"] = "Documenter"
makedocs(
    modules = [Agents, InteractiveDynamics],
    sitename = "Agents.jl Example Zoo",
    authors = "George Datseris and contributors.",
    doctest = false,
    format = Documenter.HTML(
        prettyurls = CI,
        assets = [
            asset(
                "https://fonts.googleapis.com/css?family=Montserrat|Source+Code+Pro&display=swap",
                class = :css,
            ),
        ],
        collapselevel = 2,
    ),
    pages = [
        "Introduction" => "index.md",
        "Examples" => built_examples,
    ],
)

@info "Deploying Documentation"
if CI
    deploydocs(
        repo = "github.com/JuliaDynamics/AgentsExampleZoo.jl.git",
        target = "build",
        push_preview = true,
        devbranch = "main",
    )
end

println("Finished boulding and deploying docs.")
