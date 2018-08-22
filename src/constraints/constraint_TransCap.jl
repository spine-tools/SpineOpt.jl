function constraint_TransCap(m::Model,v_trans)
    @constraint(m, [con in connection(), i in node(),j in node(), t=1:number_of_timesteps("timer"); [con,i,j] in generate_ConnectionNodePairs()],
        + (v_Trans[con,i,j,t])
        <=
        + p_TransCapAvFrac(con,i,j,t)
            * p_TransCap(con)
    )
end
