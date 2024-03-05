For clustered units, defines how many members of that [unit](@ref) are out of service, generally, or at a particular time. This can be used to, for example, to model  maintenance outages.  Typically this parameter takes a binary (UC) or integer (clustered UC) value. Together with the [unit\_availability\_factor](@ref), and [number\_of\_units](@ref), this will determine the maximum number of members that can be online at any given time. (Thus restricting the [units\_on](@ref) variable). 

It is possible to allow the model to schedule maintenance outages using [outage\_variable\_type](@ref) and [scheduled\_outage\_duration](@ref).

The default value for this parameter is 0.
