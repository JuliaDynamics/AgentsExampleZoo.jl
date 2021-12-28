# Agents.jl Example Zoo
This repository hosts built and run examples of models written in Agents.jl.
It contains most run examples that are not hosted on the main documentation of Agents.jl to make that documentation more concise and faster to build.

* Agents.jl docs: https://juliadynamics.github.io/Agents.jl/stable/
* Zoo of Examples: https://juliadynamics.github.io/Agents.jl_Example_Zoo/dev/

### Contributing a new example
The setup of the repository uses Literate.jl. If you are unfamiliar with it, it is worth taking a look at its documentation. Alternatively, have a look at existing examples source code in `docs/examples`.

The process of adding a new example is simple:

1. Fork this repository and in your own version add a new `.jl` example file in `docs/examples`. As per Literate.jl, the example must be a valid, runnable Julia file.
2. In the file `docs/make.jl` add your new example in the variable `NEW_EXAMPLES` in the very first line of the file. You need to add a `Pair` of `String` to `String` such as `"My example title" => "example_file.jl"`.  This happens so that when you open a Pull Request only your example is compiled (saves a looot of time!).
3. Also mention your example in the `docs/src/index.md` file, which provides an overview of the examples and where they are useful.
4. Open a Pull Request with a summary of your example. 
5. After the PR has been reviewed and accepted, simply move your example from the `NEW_EXAMPLES` variable to the `EXISTING_EXAMPLES` one (and please respect alphabetical sorting!).
