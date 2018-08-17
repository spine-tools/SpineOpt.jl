function flow(m::Model)
    # @variable(m, flow[commodity(), node(), unit(), ["in", "out"], t = 1:24
    # ] >= 0) #TO DO!!
    @variable(m, flow[c in commodity(), n in node(), u in unit(), ["in","out"], t = 1:24; all([n in CommodityAffiliation(c), u in NodeUnitConnection(n)])]>= 0)
end
