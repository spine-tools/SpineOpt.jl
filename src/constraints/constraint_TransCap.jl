function constraint_TransCap(m::Model,v_Trans)
    @constraint(m, [con in connection(), i in node(),j in node(), t=1:number_of_timesteps(time="timer"); [con,i,j] in connection_node_node()],
        + (v_Trans[connection=con,node1=i,node2=j,t=t])
        <=
        + p_TransCapAvFrac(connection=con,node1=i,node2=j,t=t)
            * p_TransCap(connection=con)
    )
end
