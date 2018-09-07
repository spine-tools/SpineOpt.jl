"""
    generate_variable_trans(m::Model)

Generates transmissions `trans` for each existing tuple of [connection,node_i,node_j].
For each `connection` between to `nodes`, two `trans` variables exist.
"""
function generate_variable_trans(m::Model)
    @variable(
        m,
        trans[
            c in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            [c, i, j] in connection__node__node()
        ]
    )
end
