"""
    generate_variable_state(m::Model)

A `state` variable for each tuple returned by `commodity__node()`,
attached to model `m`.
`state` represents the 'commodity' stored  inside a 'node'.
"""
function variable_nodal_state(m::Model)
    @butcher Dict{Tuple,JuMP.VariableRef}(
        (c, n, t) => @variable(
            m, base_name="nodal_state[$c, $n, $(t.JuMP_name)]"
        ) for (c, n) in commodity__node(), t=0:number_of_timesteps(time=:timer)
    )
end
