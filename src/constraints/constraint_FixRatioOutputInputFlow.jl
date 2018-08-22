function constraint_FixRatioOutputInputFlow(m::Model, v_flow)
    @constraint(m, [u in unit(), t=1:number_of_timesteps("timer"); !isnull(FixRatioOutputInputFlow(u))],
        + sum(v_flow[c_out, n, u, "out", t] for c in commodity(), n in node() if [c_out,n,u,"out"] in generate_CommoditiesNodesUnits())
        == p_FixRatioOutputInputFlow(u,c_out,c_in) * sum(flow[c_in,n, u, "in", t] for c_in in commodity(), n in node() if [c_in,n,u,"in"] in generate_CommoditiesNodesUnits())
    )
end
