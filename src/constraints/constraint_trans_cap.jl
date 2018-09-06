"""
constraint_trans_cap:
Limits the flow capacity of a commodity transfered between to nodes in a
specific direction
"""
function constraint_trans_cap(m::Model, trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t = 1:number_of_timesteps(time = "timer");
            all([
            [i,j] in connection__node__node(connection = con),
            trans_cap_av_frac(connection = con, node1 = i, node2 = j, t = t) != nothing,
            trans_cap(connection = con) != nothing
            ])
        ],
        + (trans[con, i, j, t])
        <=
        + trans_cap_av_frac(connection = con, node1 = i, node2 = j, t = t)
            * trans_cap(connection = con)
    )
end
