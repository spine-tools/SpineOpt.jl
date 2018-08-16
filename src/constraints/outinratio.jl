function outinratio(m::Model, flow,number_of_timesteps)
    @constraint(m, [u in unit(), n in node(), t=1:number_of_timesteps; !isnull(FixRatioOutputInputFlow_ElectricityGas(u))],
        + sum(flow["Electricity", n, u, "out", t] for n in CommodityAffiliation("Electricity") if all([u in NodeUnitConnection(n), u in output_com("Electricity")]))
        == FixRatioOutputInputFlow_ElectricityGas(u) * sum(flow["Gas",n, u, "in", t] for n in CommodityAffiliation("Gas") if all([u in NodeUnitConnection(n), u in input_com("Gas")]))
    )
    @constraint(m, [u in unit(), n in node(), t=1:number_of_timesteps; !isnull(FixRatioOutputInputFlow_ElectricityCoal(u))],
        + sum(flow["Electricity", n, u, "out", t]  for n in CommodityAffiliation("Electricity") if all([u in NodeUnitConnection(n), u in output_com("Electricity")]))
        == FixRatioOutputInputFlow_ElectricityCoal(u) * sum(flow["Coal",n, u, "in", t] for n in CommodityAffiliation("Coal") if all([u in NodeUnitConnection(n), u in input_com("Coal")]))
    )
    @constraint(m, [u in unit(), n in node(), t=1:number_of_timesteps; !isnull(FixRatioOutputInputFlow_HeatGas(u))],
        + sum(flow["Heat", n, u, "out", t]   for n in CommodityAffiliation("Heat") if all([u in NodeUnitConnection(n), u in output_com("Heat")]))
        == FixRatioOutputInputFlow_HeatGas(u) * sum(flow["Gas",n, u, "in", t] for n in CommodityAffiliation("Gas") if all([u in NodeUnitConnection(n), u in input_com("Gas")]))
    )

end
