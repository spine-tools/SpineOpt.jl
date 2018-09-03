# FIXME: some names here don't respect the lower_case convention
# TODO: make the comment below more explicit
### t.b.d.
function constraint_TransLoss(m::Model, trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            [i, j] in connection_node_node(connection=con)
        ], #for all symmetric connections
        + (trans[con, i, j, t])
            * p_TransLoss(connection=con, node1=i, node2=j)  # To have a look at
        >=
        - (trans[con, j, i ,t]))
end
