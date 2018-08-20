function flow(m::Model)
    # @variable(m, flow[commodity(), node(), unit(), ["in", "out"], t = 1:24
    # ] >= 0) #TO DO!!
    @variable(m, flow[c in commodity(), n in node(), u in unit(), p in ["in","out"], t = 1:24; [c,n,u,p] in get_com_node_unit()]>= 0)
end
