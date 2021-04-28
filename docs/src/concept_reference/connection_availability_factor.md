To indicate that a connection is only available to a certain extent or at certain times of the optimization,
the [connection\_availability\_factor](@ref) can be used. A typical use case could be an availability timeseries
for connection with expected outage times. By default the availability factor is set to `1`.
The availability is, among others, used in the [constraint\_connection\_flow\_capacity](@ref).
