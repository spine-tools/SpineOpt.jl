By setting the parameter [is\_reserve\_node](@ref) to `true`, a node is treated as a
reserve [node](@ref) in the model. Units that are linked through a [unit\_\_to\_node](@ref)
relationship will be able to provide balancing services to the reserve node, but
within their technical feasibility. The mathematical formulation holds a chapter on [Reserve constraints](@ref)
and the general concept of setting up a model with reserves is described in [Reserves](@ref).
