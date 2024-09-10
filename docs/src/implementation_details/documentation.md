# Documentation

The documentation is build with [Documenter.jl](https://documenter.juliadocs.org/stable/), by running the `make.jl` script.
Note that `make.jl` calls some stuff from `docs_util.jl`.

## Build the documentation locally

The documentation is bundled in with the source code, so it is possible to build the documentation locally.

First, **navigate into the SpineOpt main folder** and activate the `docs` environment from the julia package manager:

```julia
(SpineOpt) pkg> activate docs
(docs) pkg>
```

Next, in order to make sure that the `docs` environment uses the same SpineOpt version it is contained within,
install the package locally into the `docs` environment:

```julia
(docs) pkg> develop .
Resolving package versions...
<lots of packages being checked>
(docs) pkg>
```

Now, you should be able to build the documentation by exiting the package manager and typing:

```julia
julia> include("docs/make.jl")
```

This should build the documentation on your computer, and you can access it in the `docs/build/` folder.

## Concept reference

Parameters.md is one of the files that is automatically generated. Each parameter has a description in the concept_reference folder and is further processed with the spineopt template. As such there is no point in attempting to make changes directly in Parameters.md.

## Documentation from docstring

The mathematical formulation of the constraints is also automatically generated: constraints.md contains tags to automatically pull a function's docstring to the file constraints\_automatically\_generated.md. An example of a tag:

```
@@add_constraint_nodal_balance!
```

An example for how the docstring looks:

```
@doc raw"""
    add_constraint_nodal_balance!(m::Model)

Balance equation for nodes.

In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
they are the glue that brings all components of the energy system together. An energy balance is created for each [node](@ref) for all `node_stochastic_time_indices`, unless the [balance\_type](@ref) parameter of the node takes the value [balance\_type\_none](@ref balance_type_list) or if the node in question is a member of a node group, for which the [balance\_type](@ref) is [balance\_type\_group](@ref balance_type_list). The parameter [nodal\_balance\_sense](@ref) defaults to equality, but can be changed to allow overproduction ([nodal\_balance\_sense](@ref) [`>=`](@ref constraint_sense_list)) or underproduction ([nodal\_balance\_sense](@ref) [`<=`](@ref constraint_sense_list)).
The energy balance is enforced by the following constraint:

```math
\begin{aligned}
& v_{node\_injection}(n,s,t) \\
& + \sum_{\substack{(conn,n',d_{in},s,t) \in connection\_flow\_indices: \\ d_{out} == :to\_node}}
v_{connection\_flow}(conn,n',d_{in},s,t)\\
& - \sum_{\substack{(conn,n',d_{out},s,t) \in connection\_flow\_indices: \\ d_{out} == :from\_node}}
v_{connection\_flow}(conn,n',d_{out},s,t)\\
& + v_{node\_slack\_pos}(n,s,t) \\
& - v_{node\_slack\_neg}(n,s,t) \\
& \{>=,==,<=\} \\
& 0 \\
& \forall (n,s,t) \in node\_stochastic\_time\_indices: \\
& p_{balance\_type}(n) != balance\_type\_none \\
& \nexists ng \in groups(n) : balance\_type\_group \\
\end{aligned}
```
"""
``` 

The reason for using the docstring is such that it is easier to update the documentation in the docstring when developing a certain constraint.

The feature is completely optional. To activate the functionality for another file (e.g. objective.md) add tags to that file and then add code similar to this to make.jl.

```julia
mathpath = joinpath(path, "src", "mathematical_formulation")
docstrings = all_docstrings(SpineOpt)

objective_function_lines = readlines(joinpath(mathpath, "objective_function.md"))
expand_tags!(objective_function_lines, docstrings)
open(joinpath(mathpath, "objective_function_automatically_generated.md"), "w") do file
    write(file, join(objective_function_lines, "\n"))
end
```

To deactivate the functionality, just remove the code and replace the tags in your .md file.

It is also possible to introduce this feature over time. Anytime you want to add the documentation of a constraint to the docstring you need to follow a few steps:
1. For the docstring
    1. add `@doc raw` before the docstring (that allows to write latex in the docstring)
2. For the .md file
    1. cut the description and mathematical formulation and paste them in the corresponding function's docstring
    2. add the tag to pull the above from the docstring

An example of both the docstring and the instruction file have already been shown above.


## Drag and drop

There is also a drag-and-drop feature for select chapters (e.g. the how to section). For those chapters you can simply add your markdown file to the folder of the chapter and it will be automatically added to the documentation. To allow both manually composed chapters and automatically generated chapter, the functionality is only activated for empty chapters (of the structure "chapter name" => []).

The drag-and-drop function assumes a specific structure for the documentation files.
+ All chapters and corresponding markdownfiles are in the docs/src folder.
+ Folder names need to be lowercase with underscores because the automated folder names are derived from the page names in make.jl. A new chapter (e.g. implementation details) needs to follow this structure.
+ Markdown file names can have uppercases and can have underscores but don't need to because the page names in make.jl are derived from the actual file names. In other words, your filename will become the page name in the documentation so make this descriptive.
