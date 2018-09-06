"""
constraint_trans_loss:
This function enforces losses on transmissions depending on the obeserved direction
    e.g. trans_loss(con,n_i,n_j) != trans_loss(con,n_j,n_i)
"""
function constraint_trans_loss(m::Model, trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t = 1:number_of_timesteps(time = "timer");
            all([
                [i, j] in connection__node__node(connection = con),
                trans_loss(connection = con, node1 = i, node2 = j) != nothing
            ])
        ],
        + (trans[con, i, j, t])
            * trans_loss(connection = con, node1 = i, node2 = j)
        >=
        - (trans[con, j, i ,t]))
end
