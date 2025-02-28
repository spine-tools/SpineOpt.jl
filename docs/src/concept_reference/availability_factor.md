Connection: To indicate that a connection is only available to a certain extent or at certain times of the optimization,
the [availability\_factor](@ref) can be used. A typical use case could be an availability timeseries
for connection with expected outage times. By default the availability factor is set to `1`.
The availability is, among others, used in the [constraint\_connection\_flow\_capacity](@ref).

Unit: To indicate that a unit is only available to a certain extent or at certain times of the optimization,
the [availability\_factor](@ref) can be used. A typical use case could be an availability timeseries
for a variable renewable energy source. By default the availability factor is set to `1`.
The availability is, among others, used in the [constraint\_units\_available](@ref).
