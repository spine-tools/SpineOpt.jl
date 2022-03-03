# [Modelling to generate alternatives](@id mga-advanced)

Through modelling to generate alternatives (short MGA), near-optimal solutions can be explored under certain conditions.
The idea is that an orginal problem is solved, and subsequently solved again under the condition that the realization of variables should be maximally different from the previous iteration(s), while keeping the objective function within a certain threshold (defined by [max\_mga\_slack](@ref)).

In SpineOpt, we choose [units\_invested\_available](@ref), [connections\_invested\_available](@ref), and [storages\_invested\_available](@ref) as variables that can be considered for the maximum-difference-problem. The implementation is based on [Modelling to generate alternatives: A technique to explore uncertainty in energy-environment-economy models](https://doi.org/10.1016/j.apenergy.2017.03.065).

## How to set up an MGA problem
- [model](@ref): In order to explore an MGA model, you will need one model of type [spineopt\_mga](@ref model_type_list). You should also define the number of iterations ([max\_mga\_iterations](@ref), and the maximum allowed deviation from the original objective function ([max\_mga\_slack](@ref)).
- at least one investment candidate of type [unit](@ref), [connection](@ref), or [node](@ref). For more details on how to set up an investment problem please see: [Investment Optimization](@ref).
- To include the investment decisions in the MGA difference maximization, the parameter [units\_invested\_mga](@ref), [connections\_invested\_mga](@ref), or [storages\_invested\_mga](@ref) need to be set to true, respectively.
- The original MGA formulation is non-convex (maximization problem of an absolute function), but has been linearized through big M method. For this purpose, one should always make sure that [units\_invested\_big\_m\_mga](@ref), [connections\_invested\_big\_m\_mga](@ref), or [storages\_invested\_big\_m\_mga](@ref), respectively, is sufficently large to always be larger the the maximum possible difference per MGA iteration. (Typically the number of candidates could suffice.)
