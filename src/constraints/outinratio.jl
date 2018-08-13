function outinratio(m::Model, flow,number_of_timesteps)
    @constraint(m, [u in unit(), n in node(), t=1:number_of_timesteps; !isnull(FixRatioOutputInputFlow_ElectricityGas(u))],
        + sum(flow["Electricity", n, u, "out", t] for c in output_com(u))
        == FixRatioOutputInputFlow_ElectricityGas(u) * sum(flow["Gas",n, u, "in", t] for c in input_com(u))
    )
    @constraint(m, [u in unit(), n in node(), t=1:number_of_timesteps; !isnull(FixRatioOutputInputFlow_ElectricityCoal(u))],
        + sum(flow["Electricity", n, u, "out", t] for c in output_com(u))
        == FixRatioOutputInputFlow_ElectricityCoal(u) * sum(flow["Coal",n, u, "in", t] for c in input_com(u))
    )
    @constraint(m, [u in unit(), n in node(), t=1:number_of_timesteps; !isnull(FixRatioOutputInputFlow_HeatGas(u))],
        + sum(flow["Heat", n, u, "out", t] for c in output_com(u))
        == FixRatioOutputInputFlow_HeatGas(u) * sum(flow["Gas",n, u, "in", t] for c in input_com(u))
    )

end
