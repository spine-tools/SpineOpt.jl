For investment models that are solved using the Benders algorithm (i.e., with [model\_type](@ref) set to `spineopt_benders`),
`mp_min_res_gen_to_demand_ratio` represents a lower bound on the fraction of the total system demand
that must be supplied by renewable generation sources (RES).

A [unit](@ref) can be marked as a renewable generation source by setting [is\_renewable](@ref) to `true`.