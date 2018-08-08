function variable_flow(m::Model)#,number_of_timesteps)
    @variable(m, flow[commodity(), node(), unit(), ["in", "out"], t = 1:number_of_timesteps] >= 0) #TO DO!!
end
