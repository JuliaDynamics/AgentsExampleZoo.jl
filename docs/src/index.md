![Agents.jl](https://github.com/JuliaDynamics/JuliaDynamics/blob/master/videos/agents/agents3_logo.gif?raw=true)

!!! note "This is an examples-only repository!"
    Please notice that this repository holds _only examples_ of various models implemented in Agents.jl. To actually learn how to use Agents.jl please visit the [online documentation](https://juliadynamics.github.io/Agents.jl/stable/) first!


The examples here were built with versions

```@example MAIN
using Pkg
Pkg.status(["Agents", "InteractiveDynamics", "CairoMakie"];
    mode = PKGMODE_MANIFEST, io=stdout
)
```

# Overview of Examples

Our ever growing list of examples are designed to showcase what is possible with
Agents.jl. Here, we outline a number of topics that new and advanced users alike can
quickly reference to find exactly what they're looking for.

## Discrete spaces
Making a discrete grid is perhaps the easiest way to conceptualise space in a model.
That is why the main example of Agents.jl documentation is the Schelling model on a discrete space.
[Sugarscape](@ref) is one of our more complex examples, but gives you a good overview
of what is possible on a grid. If you're looking for something simpler, then the
[Forest fire](@ref) would be a good start, which is also an example of a cellular automaton.
[Daisyworld](@ref) is a famous ABM example which has both agent and model dynamics, similarly with [Sugarscape](@ref).
[Ants](@ref) is based on an ABM model from NetLogo that shows the behavior of colonies. 

## Continuous spaces
In this space, agents generally move with a given velocity
and interact in a far smoother manner than grid based models.
The [Flocking model](https://juliadynamics.github.io/Agents.jl/stable/examples/flock/)
is perhaps the most famous example of bottom-up emergent phenomena and is hosted in the main Agents.jl documentation. Something quite
topical at present is our
[Continuous space social distancing](@ref) example.
Finally, an excellent and complex example of what can be done in a continuous space:
[Bacterial Growth](@ref).

## Higher dimensional spaces

[Battle Royale](@ref) is an advanced example which leverages a 3-dimensional
grid space, but only uses 2 of those dimensions for space. The third represents an
agent **category**. Here, we can leverage Agents.jl's sophisticated neighbor searches
to find closely related agents not just in space, but also in property.

## Agent Path-finding
Besides the main (and most complex) example we have in the docs with [Rabbit, Fox, Hawk](https://juliadynamics.github.io/Agents.jl/stable/examples/rabbit_fox_hawk/), here are two more models showcasing the possibilities of pathfinding:
[Maze Solver](@ref) and [Mountain Runners](@ref).

## Synchronous agent updates

Most of the time, using the `agent_step!` loop then the `model_step!` is
sufficient to evolve a model. What if there's a more complicated set of dynamics you need
to employ? Take a look at the [Hegselmann-Krause opinion dynamics](@ref):
it shows us how to make a second agent loop within `model_step!` to synchronise changes
across all agents after `agent_step!` dynamics have completed.

## Agent sampling

The [Wright-Fisher model of evolution](@ref) shows us how we can sample a population of
agents based on certain model properties. This is quite helpful in genetic and biology
studies where agents are cell analogues.

## Cellular Automata

A subset of ABMs, these models have individual agents with a set of behaviors,
interacting with neighboring cells and the world around them, but never moving.
Some examples of this model type are [Conway's game of life](@ref), [Forest fire](@ref) and
[Daisyworld](@ref).

## Mixed Models

In the real world, groups of people interact differently with people they know vs people
they don't know. In ABM worlds, that's no different.
[Predator-prey dynamics](https://juliadynamics.github.io/Agents.jl/dev/examples/predator_prey/) (or more colloquially: Wolf-Sheep) implements
interactions between a pack of Wolves, a heard of Sheep and meadows of Grass.
[Daisyworld](@ref) is an example of how a model property (in this case temperature) can
be elevated to an agent type.

## Advanced visualization
The [Sugarscape](@ref) example shows how to animate, in parallel, one plot that shows the ABM evolution, and another plot that shows any quantity a user is interested in.

The [Bacterial Growth](@ref) example shows how to make customized shapes for your agents that change over time as the agents evolve.
