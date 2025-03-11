# [(new) Modelling to generate alternatives](@id mga-advanced)

Modeling to generate alternatives (MGA) allows us to explore near-optimal solutions and to return heterogeneous portfolios, so as to reduce the structural uncertainty. Hop-Skip-Jump procedure was implemented, alongside proposed extensions for fuzzy MGA.

## Modelling to generate alternative: Maximally different portfolios
The idea is that an orginal problem is solved, and subsequently solved again under the condition that the realization of variables should be maximally different from the previous iteration(s), while keeping the objective function within a certain threshold (defined by [max\_mga\_slack](@ref)).

In SpineOpt, we choose [units\_invested\_available](@ref), [connections\_invested\_available](@ref), and [storages\_invested\_available](@ref) as variables that can be considered for the maximum-difference-problem.

## Hop-Skip-Jump MGA
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
## Fuzzy MGA
In fuzzy MGA [Modeling to generate alternatives: a fuzzy approach](https://doi.org/10.1016/S0165-0114(83)80014-1) 
reformulates the original MGA into an multiobjective problem with:
- objective(s) measuring heterogeneousness of solutions
- objective measuring how far away we are
We achieve it by defining sets:
$$
\begin{align*}
X_o &- \text{set of solutions that achieve satisfactory heterogeneity}\\
X_c &- \text{set of solutions that satisfy the optimality} \\
X = X_o  \cap X_c &- \text{set of satisfying solutions}
\end{align*}
\\
\begin{align*}
\mu_{X_o}(x),\mu_{X_c}(x),\mu_X(x) &\in [0,1] - \text{functions saying "how much" a solution belongs in a set} \\

\sum_{k \in B} w_k x_k = 0 &\implies \mu_{X_o}(x) = 1 \\
\sum_{k \in B} w_k x_k \in ( \sum_{k \in B} w_k x^*_k, 0) &\implies \mu_{X_o}(x) \in (0,1) \\
\sum_{k \in B} w_k x_k \geq \sum_{k \in B} w_k x^*_k &\implies \mu_{X_o}(x) = 0 \\
f(x) = f(x^*) &\implies \mu_{X_c}(x) = 1 \\
f(x) \in ((1 + \varepsilon) f(x^*), f(x^*)) &\implies \mu_{X_c}(x) \in (0,1)\\
f(x) \geq (1 + \varepsilon) f(x^*) &\implies \mu_{X_c}(x) = 0 \\
\mu_{X}(x) &= \min\{\mu_{X_o}(x),\mu_{X_c}(x)\} 
\end{align*}
$$

which leads to an optimization problem:
$$
\max_{x \in X} \min\{\mu_{X_o}(x),\mu_{X_c}(x)\}
$$
We might also want to create many sets $$X^1_o, X^2_o,...$$
corresponding to satisfactory heterogeneity on subsets of variables e.g., unit investments, connection investments, storage investments.

## RPM Fuzzy MGA
Instead of the original fuzzy MGA formulation we utilize a similiar one using the Reference Point Method [Reference Point Approaches](https://doi.org/10.1007/978-1-4615-5025-9_9) which, unlike the original formulation,
guarantees Pareto-optimality and works even with ill-defined sets of satisfying solutions.
$$
lex \max_{x \in X} (\min\{s_{o}(x),s_{c}(x)\}, \quad  s_{o}(x) + s_{c}(x))
$$
where
$$
\begin{align*}
s_o(x), s_c(x) &- \text{achievement functions similiar to } \mu \\
\sum_{k \in B} w_k x_k \leq 0 &\implies s_o(x) \geq 1 \\
\sum_{k \in B} w_k x_k \in ( \sum_{k \in B} w_k x^*_k, 0) &\implies s_o(x) \in (0,1) \\
\sum_{k \in B} w_k x_k \geq \sum_{k \in B} w_k x^*_k &\implies s_o(x) \leq 0 \\
f(x) \leq f(x^*) &\implies s_c(x) \geq 1 \\
f(x) \in ((1 + \varepsilon) f(x^*), f(x^*)) &\implies s_c(x) \in (0,1)\\
f(x) \geq (1 + \varepsilon) f(x^*) &\implies s_c(x) \leq 0 \\
\end{align*}
$$


## How to set up an MGA problem
- [model](@ref): In order to explore an MGA model, you will need an algorith of type [hsj_mga_algorithm](@ref model_algorithm_list) or [fuzzy_mga_algorithm](@ref model_algorithm_list). You should also define the number of iterations [max\_mga\_iterations](@ref), and the maximum allowed deviation from the original objective function ([max\_mga\_slack](@ref)).
- at least one investment candidate of type [unit](@ref), [connection](@ref), or [node](@ref). For more details on how to set up an investment problem please see: [Investment Optimization](@ref).
- To include the investment decisions in the MGA difference maximization, the parameter [units\_invested\_mga](@ref), [connections\_invested\_mga](@ref), or [storages\_invested\_mga](@ref) need to be set to true, respectively.
- As [output](@ref)s are used to intermediately store solutions from different MGA runs, it is important that `units_invested`, `connections_invested`, or `storages_invested`, respectively, are defined as [output](@ref) objects in your database.