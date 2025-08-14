# [Modelling to generate alternatives](@id mga-advanced)

Through modelling to generate alternatives (short MGA), near-optimal solutions can be explored under certain conditions. Currently, SpineOpt supports two methods for MGA are available.

## Modelling to generate alternative: Maximally different portfolios
The idea is that an orginal problem is solved, and subsequently solved again under the condition that the realization of variables should be maximally different from the previous iteration(s), while keeping the objective function within a certain threshold (defined by [max\_mga\_slack](@ref)).

In SpineOpt, we choose [units\_invested\_available](@ref), [connections\_invested\_available](@ref), and [storages\_invested\_available](@ref) as variables that can be considered for the maximum-difference-problem. The implementation is based on [Modelling to generate alternatives: A technique to explore uncertainty in energy-environment-economy models](https://doi.org/10.1016/j.apenergy.2017.03.065).

## How to set up an MGA problem
- [model](@ref): In order to explore an MGA model, you will need one model of type [spineopt\_mga](@ref model_type_list). You should also define the number of iterations ([max\_mga\_iterations](@ref), and the maximum allowed deviation from the original objective function ([max\_mga\_slack](@ref)).
- at least one investment candidate of type [unit](@ref), [connection](@ref), or [node](@ref). For more details on how to set up an investment problem please see: [Investment Optimization](@ref).
- To include the investment decisions in the MGA difference maximization, the parameter [units\_invested\_mga](@ref), [connections\_invested\_mga](@ref), or [storages\_invested\_mga](@ref) need to be set to true, respectively.
- The original MGA formulation is non-convex (maximization problem of an absolute function), but has been linearized through big M method. For this purpose, one should always make sure that [units\_invested\_big\_m\_mga](@ref), [connections\_invested\_big\_m\_mga](@ref), or [storages\_invested\_big\_m\_mga](@ref), respectively, is sufficently large to always be larger the the maximum possible difference per MGA iteration. (Typically the number of candidates could suffice.)
- As [output](@ref)s are used to intermediately store solutions from different MGA runs, it is important that `units_invested`, `connections_invested`, or `storages_invested`, respectively, are defined as [output](@ref) objects in your database.

## Modelling to generate alternative: Trade-offs between technology investments
The idea of this approach is to explore near-optimal solutions that maximize/minimize investment in a certain technology (or multiple technologies simultanesously). 

## How to set up an MGA problem
- [model](@ref): In order to explore an MGA model, you will need one model of type [spineopt\_mga](@ref model_type_list). The maximum allowed deviation from the original objective function should be defined via [max\_mga\_slack](@ref). Note that for this method, we don't define an explicit number of iteration via the  [max\_mga\_iterations](@ref) parameter (see also below)
- at least one investment candidate of type [unit](@ref), [connection](@ref), or [node](@ref). For more details on how to set up an investment problem please see: [Investment Optimization](@ref).
- To include the investment decisions in the MGA min/maximization, the parameter [units\_invested\_mga](@ref), [connections\_invested\_mga](@ref), or [storages\_invested\_mga](@ref) need to be set to true, respectively.
- To explore near-optimal solutions using this methodology, the [units\_invested\_mga\_weight](@ref), [connections\_invested\_mga\_weight](@ref), and [storages\_invested\_mga\_weight](@ref) parameters are used to define near-optimal solutions. For this purpose, these parameters are defined as Arrays, defining the weight of the technology per iterations. Note that the length of these Arrays should be the same for all technologies, as this will correspond to the number of MGA iterations, i.e., the number of near-optimal solutions. To analyze the trade-off between two technology types, we can, e.g., define [units\_invested\_mga\_weight](@ref) for *unit group 1* as [-1,-0.5,0], whereas the use the weights [0,-0.5,-1] for the other technology *storage group 1* in question. Note that a negative sign will correspond to a minimization of investments in the corresponding technology type, while positive signs correspond to a maximization of the respective technology. In the given example, we would hence first minimize the investments in *unit group 1*, then minimize the two technologies simultaneuously, and finally only minimize investments in *storage group 2*.
- As [output](@ref)s are used to intermediately store solutions from different MGA runs, it is important that `units_invested`, `connections_invested`, or `storages_invested`, respectively, are defined as [output](@ref) objects in your database.

## Hop-Skip-Jump MGA
The idea is that an orginal problem is solved, and subsequently solved again under the condition that the realization of variables should be maximally different from the previous iteration(s), while keeping the objective function within a certain threshold (defined by [max\_mga\_slack](@ref)).
1. We solve the original problem 
$$x^* \gets \argmin_{x \in X} f(x)$$
where  
- X - set of feasible solutions
- f - goal function 
2. We are interested in finding diverse solutions with respect to variables from the set B. We achieve it by finding which variables were active in the original solution (with values greater than 0) and then activating their corresponding weights:
$$\forall k \in B: x^*_k > 0 \implies w_k = 1$$
3. We then optimize a new problem with a weighted sum objective and constraint guaranteeing that we are close (epsilon-close) to the optimal value:
$$\min_{x \in X} \quad \sum_{k \in B} w_k x_k$$
$$ f(x) \leq (1 + \varepsilon) f(x^*)$$
4. Update the weights to be also set to 1 when a variable was greater than 0 in the MGA problem solution
5. GOTO 3

## How to set up a HSJ MGA problem
- [model](@ref): In order to explore an MGA model, you will need an algorith of type [hsj_mga_algorithm](@ref model_type_list).
- Everything else can be set up like in the original case. We don't have to specify [units\_invested\_mga\_weight](@ref) or [units\_invested\_big\_m\_mga](@ref).

## RPM Fuzzy MGA
In fuzzy MGA [Modeling to generate alternatives: a fuzzy approach](https://doi.org/10.1016/S0165-0114(83)80014-1) 
reformulates the original MGA into an multiobjective problem with:
- objective(s) measuring heterogeneousness of solutions
- objective measuring how far away we are from optimal solution

Instead of the original fuzzy MGA formulation we utilize a similiar one using the Reference Point Method [Reference Point Approaches](https://doi.org/10.1007/978-1-4615-5025-9_9) which, unlike the original formulation,
guarantees Pareto-optimality.

## How to set up a RPM Fuzzy MGA problem
- [model](@ref): In order to explore an MGA model, you will need an algorith of type [fuzzy_mga_algorithm](@ref model_type_list).
- Everything else can be set up like in the original case. We don't have to specify [units\_invested\_mga\_weight](@ref) or [units\_invested\_big\_m\_mga](@ref).
