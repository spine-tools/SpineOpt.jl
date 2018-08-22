function generate_CommoditiesNodesUnits()
    """
        return list of connection list of all unit node connections [Commodity, Node, Unit, in/out]
        e.g. [["Coal", "BelgiumCoal", "CoalPlant", "in"], ["Electricity", "LeuvenElectricity", "CoalPlant", "out"],...]
    """
    #
    CommoditiesNodesUnits = []
    for u in unit()
        for n in eval(parse(:($node_unit_rel)))(u)
            for c in eval(parse(:($node_commodity_rel)))(n)
                if c in eval(parse(:($unit_commidity_input_rel)))(u)
                    push!(CommoditiesNodesUnits, [c,n,u,"in"])
                end
                if c in eval(parse(:($unit_commidity_output_rel)))(u)
                    push!(CommoditiesNodesUnits, [c,n,u,"out"])
                end
            end
        end
    end
    return CommoditiesNodesUnits
end
