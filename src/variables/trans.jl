function trans(m::Model)#, number_of_timesteps)
    for connection(),node(),node() in get_all_connection_node_pairs(jfo, true)
    @variable(m, trans[connection(),node(),node()  t=1:number_of_timesteps]) ####TO DO
end
end
