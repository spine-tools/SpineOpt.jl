# Documentation

The documentation is mostly build with regular [Documenter.jl](https://documenter.juliadocs.org/stable/). `make.jl` is therefore the main file for building the documentation. However, there are a few convenience functions which automate some parts of the process. Some of these are located close to the documentation (e.g. `write_documentation_sets_and_variables.jl` in SPINEOPT.jl/docs/src/mathematical_formulation) while other functions are inherently part of the SpineOpt code (e.g. `docs_util.jl` in SPINEOPT.jl/src/util).

