# Documentation

The documentation is mostly build with regular [Documenter.jl](https://documenter.juliadocs.org/stable/). `make.jl` is therefore the main file for building the documentation. However, there are a few convenience functions which automate some parts of the process. Some of these are located close to the documentation (e.g. SPINEOPT.jl/docs/src/mathematical\_formulation/write\_documentation\_sets\_and\_variables.jl) while other functions are inherently part of the SpineOpt code (e.g. SPINEOPT.jl/src/util/docs\_util.jl).

## Concept reference

Parameters.md is one of the files that is automatically generated. Each parameter has a description in the concept_reference folder and is further processed with the spineopt template. As such there is no point in attempting to make changes directly in Parameters.md.

## Documentation from docstring

The mathematical formulation of the constraints is also automatically generated: constraints.md contains the list of instructions to automatically pull text from docstrings to the file constraints\_automatically\_generated\_file.md. An example of an instruction:

```
### Nodal balance
#region instruction
add_constraint_nodal_balance!
description
formulation
#endregion instruction
```

Anything within `#region instruction` and `#endregion instruction` will be interpreted as an instruction. Anything outside that structure will be interpreted as regular markdown text to be copied directly to the file (e.g. `### Nodal balance`). The first line of the instruction is the function from which you want to pull the docstring. The other arguments are the fields in the docstring that you want to include.

The current list of fields for constraints:
+ description: describes the formulation of the constraint in words
+ formulation: describes the formulation of the constraints in latex formulas

There is also a special instruction specifically for getting the same field (or fields) from all constraint functions; instead of specifying the function name you can write `alldocstrings`. It will also automatically generate titles in between corresponding to the constraint.

An example for how the docstring looks:

```
@doc raw"""
    add_constraint_nodal_balance!(m::Model)

Balance equation for nodes.

    #region description
    In **SpineOpt**, [node](@ref) is the place where an energy balance is enforced. As universal aggregators,
    they are the glue that brings all components of the energy system together. An energy balance is created for each [node](@ref) for all `node_stochastic_time_indices`, unless the [balance\_type](@ref) parameter of the node takes the value [balance\_type\_none](@ref balance_type_list) or if the node in question is a member of a node group, for which the [balance\_type](@ref) is [balance\_type\_group](@ref balance_type_list). The parameter [nodal\_balance\_sense](@ref) defaults to equality, but can be changed to allow overproduction ([nodal\_balance\_sense](@ref) [`>=`](@ref constraint_sense_list)) or underproduction ([nodal\_balance\_sense](@ref) [`<=`](@ref constraint_sense_list)).
    The energy balance is enforced by the following constraint:
    #endregion description

    #region formulation
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
    #endregion formulation
"""
``` 

The reason for using the docstring is such that it is easier to update the documentation in the docstring when developing a certain constraint.

The feature is completely optional. To activate the functionality for another file (e.g. objective) add the code similar to this to make.jl, make the instruction file and point to the generated file.

```julia
mathpath = joinpath(path, "src", "mathematical_formulation")
alldocs = SpineOpt.alldocstrings(SpineOpt)
instructionlist = readlines(joinpath(mathpath, "constraints.md"))
markdownstring = SpineOpt.docs_from_instructionlist(alldocs, instructionlist)
open(joinpath(mathpath, "constraints_automatically_generated_file.md"), "w") do file
    write(file, markdownstring)
end
instructionlist = readlines(joinpath(mathpath, "objective_function.md"))
markdownstring = SpineOpt.docs_from_instructionlist(alldocs, instructionlist)
open(joinpath(mathpath, "objective_function_automatically_generated_file.md"), "w") do file
    write(file, markdownstring)
end
```

To deactivate the functionality, remove the code and rename the generated file (such that it is clearer that you now need to change things manually again).

It is also possible to introduce this feature over time. Anytime you want to add the documentation of a constraint to the docstring you need to follow a few steps:
1. For the docstring
    1. add `@doc raw` before the docstring (that allows to copy paste the latex already in the current documentation)
    2. add the necessary fields somewhere in the docstring, e.g. `#region formulation` and `#endregion formulation` on different lines
2. For the instructionfile
    1. cut the description and formulation and paste it in the fields of the docstring
    2. write the instruction to point to the correct function and corresponding fields

An example of both the docstring and the instructionfile have already been shown above.



## Drag and drop

There is also a drag-and-drop feature for select chapters (e.g. the how to section). For those chapters you can simply add your markdown file to the folder of the chapter and it will be automatically added to the documentation. To allow both manually composed chapters and automatically generated chapter, the functionality is only activated for empty chapters (of the structure "chapter name" => []).

The drag-and-drop function assumes a specific structure for the documentation files.
+ All chapters and corresponding markdownfiles are in the docs/src folder.
+ Folder names need to be lowercase with underscores because the automated folder names are derived from the page names in make.jl. A new chapter (e.g. implementation details) needs to follow this structure.
+ Markdown file names can have uppercases and can have underscores but don't need to because the page names in make.jl are derived from the actual file names. In other words, your filename will become the page name in the documentation so make this descriptive.