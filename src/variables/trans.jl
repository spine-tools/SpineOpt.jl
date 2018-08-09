function variable_trans(m::Model)#, number_of_timesteps)
    for c in connection()
        for n in jfo["NodeConnectionRelationship"][c]
    @variable(m, trans[connection(),node(), t=1:number_of_timesteps] >= 0) ####TO DO
end
