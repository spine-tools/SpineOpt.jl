"""
generate_variable_trans:
This function generates transmission flows for each existing tuple of [con,n_i,n_j]
Note:
- For each connection between to nodes, two trans variables exist
- transmissions are by definition positively defined if existing a node
- the first indexed node corresponds to the origin of trans
- the second indexed node to the end point
- unlike the flow variable, trans can be negative
"""
function generate_variable_trans(m::Model)
    @variable(
        m,
        trans[
            c in connection(),
            i in node(),
            j in node(),
            t = 1:number_of_timesteps(time = "timer");
            [c, i, j] in connection__node__node()
        ]
    )
end
