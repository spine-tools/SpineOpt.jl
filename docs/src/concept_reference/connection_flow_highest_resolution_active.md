Affects the temporal resolution of the
[connection flow ratio constraints](@ref constraint_ratio_out_in_connection_flow).
When set to `true`, imposes a strict "power equality" on the flows,
so that the powers between the input and output [connection\_flow](@ref var_connection_flow)s
match exactly for each time step.
When set to `false`, the constraint relaxes to an "energy equality",
only matching the delivered energy over the coarser time steps.
Effectively, the higher resolution [connection\_flow](@ref var_connection_flow)
is allowed to vary its instantaneous "power",
as long as the "delivered energy" obeys the ratio.