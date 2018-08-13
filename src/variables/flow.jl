function flow(m::Model)
    @variable(m, flow[commodity(), node(), unit(), ["in", "out"], t = 1:24] >= 0) #TO DO!!
end
