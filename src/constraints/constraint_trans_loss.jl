# TODO: make the comment below more explicit
### t.b.d.
function constraint_trans_loss(m::Model, v_trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            all([
                [i, j] in connection__node__node(connection=con),
                p_trans_loss(connection=con,node1=i,node2=j) != nothing
            ])
        ], #for all symmetric connections
        + (v_trans[con, i, j, t])
            * p_trans_loss(connection=con, node1=i, node2=j)  # To have a look at
        >=
        - (v_trans[con, j, i ,t]))
end
