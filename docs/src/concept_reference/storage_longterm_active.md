Defines whether a storage is considered a "long-term storage"
when using representative periods.
If set to `true`, the storage state is represented using two variables:
The regular [node\_state](@ref var_node_state) will depict the storage
state deviations within representative periods,
while [node\_state\_longterm](@ref var_node_state_longterm) will be created
to track the storage state dynamics between the representatives.

See the [Representative periods tutorial](@ref).