Defines how many members a certain [unit](@ref) object represents. Typically this parameter takes a binary (UC) or integer (clustered UC) value. Together with the [unit\_availability\_factor](@ref), this will determine the maximum number of members that can be online at any given time. (Thus restricting the [units_on](@ref Variables) variable). It is possible to allow the model to increase the `number_of_units` itself, through [Investment Optimization](@ref)

The default value for this parameter is 1.
