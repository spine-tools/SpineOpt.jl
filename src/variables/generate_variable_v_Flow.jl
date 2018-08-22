function generate_variable_v_Flow(m::Model)
    # @variable(m, flow[commodity(), node(), unit(), ["in", "out"], t = 1:24
    # ] >= 0) #TO DO!!
    @variable(m, v_Flow[c in commodity(), n in node(), u in unit(), p in ["in","out"], t = 1:24; [c,n,u,p] in generate_CommoditiesNodesUnits()]>= 0)
end
