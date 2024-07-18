# %% Example files
# Add new examples here (only compiles these examples)
NEW_EXAMPLES = [

]
# Once approved, move examples here:
EXISTING_EXAMPLES = [
    # The following are sorted ALPHABETICALLY
    # according to their title in their example file!
    "ants.jl",
    "battle.jl",
    "social_distancing.jl",
    "game_of_life_2D_CA.jl",
    "growing_bacteria.jl",
    "daisyworld.jl",
    "forest_fire.jl",
    "fractal_growth.jl",
    "hk.jl",
    "maze.jl",
    "runners.jl",
    "opinion_spread.jl",
    "sugarscape.jl",
    "taxsystem.jl",
    "wealth_distribution.jl",
    "wright-fisher.jl",
]


# Documentation building code (not to be touched)
# Load packages
cd(@__DIR__)
using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing
Pkg.instantiate()
println("Loading Packages")
println("Documenter...")
using Documenter
println("AgentsExampleZoo...")
using AgentsExampleZoo
println("Agents...")
using Agents
println("Literate...")
import Literate

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
println("Converting Examples...")
indir = joinpath(@__DIR__, "examples")
outdir = joinpath(@__DIR__, "src", "examples")
rm(outdir; force = true, recursive = true) # cleans up previous examples
mkpath(outdir)

examples = isempty(NEW_EXAMPLES) ? EXISTING_EXAMPLES : NEW_EXAMPLES
built_examples = String[]
for file in examples
    Literate.markdown(joinpath(indir, file), outdir; credit = false)
    push!(built_examples, "examples/"*file[1:end-3]*".md")
end


# %%
println("Documentation Build")
if !isempty(NEW_EXAMPLES)
    ENV["JULIA_DEBUG"] = "Documenter"
end

makedocs(
    modules = [Agents, AgentsExampleZoo],
    sitename = "Agents.jl Example Zoo",
    authors = "George Datseris and contributors.",
    doctest = false,
    warnonly = [:doctest, :missing_docs, :cross_references],
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
