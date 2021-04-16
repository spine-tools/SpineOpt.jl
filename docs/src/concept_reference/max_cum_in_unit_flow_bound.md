To impose a limit on the cumulative in flows to a unit for the entire modelling horizon, e.g. to enforce limits on emissions,
the [max\_cum\_in\_unit\_flow\_bound](@ref) parameter can be used. Defining this parameter triggers the generation of the [constraint\_max\_cum\_in\_unit\_flow\_bound](@ref).

Assuming for instance that the total intake of a unit `u_A` should not exceed `10MWh` for the entire modelling horizon, then the [max\_cum\_in\_unit\_flow\_bound](@ref) would need to take the value `10`. (Assuming here that the [unit\_flow](@ref) variable is in `MW`, and the model [duration\_unit](@ref) is [hours](@ref duration_unit_list))
