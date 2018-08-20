function transcapa(m::Model,trans,number_of_timesteps)
    @constraint(m, [c in connection(), i in node(),j in node(), t=1:number_of_timesteps; [c,i,j] in get_all_connection_node_pairs()],
        + (trans[c,i,j,t])
        <= TransCapacity_a("ElectricityLine1")
    )
end
