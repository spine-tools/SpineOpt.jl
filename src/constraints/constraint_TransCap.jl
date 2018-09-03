# FIXME: some names here don't respect the lower_case convention
function constraint_TransCap(m::Model,v_Trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            [i,j] in connection_node_node(connection=con)
        ],
        + (v_Trans[con, i, j, t])
        <=
        + p_TransCapAvFrac(connection=con, node1=i, node2=j, t=t)
            * p_TransCap(connection=con)
    )
end
