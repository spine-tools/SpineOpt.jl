function transcapa(m::Model,trans)
    @constraint(m, [c in connection(), i in node(),j in node(), t=1:number_of_timesteps("timer"); [c,i,j] in get_all_connection_node_pairs(true)],
        + (trans[c,i,j,t])
        <= TransCapacity_a("ElectricityLine1") 
    )
end
