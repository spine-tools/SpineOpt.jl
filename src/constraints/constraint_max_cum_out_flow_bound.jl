function constraint_max_cum_out_flow_bound(m::Model,flow)
    @constraint(
    m,
    [
        ug in unitgroup(),
        cg in commoditygroup();
        p_MaxCumInFlowBound(unitgroup = ug,commoditygroup = cg)!=nothing
    ],
        + sum(flow[c, n, u, "in", t]
            for u in unitgroup__unit(unitgroup=ug),
                c in commoditygroup__commodity(commoditygroup = cg),
                n in node(),
                t = 1:number_of_timesteps(time="timer")
                if [c,n,u,"in"] in commodity_node_unit_direction()
            )
        <=
        + p_max_cum_in_flow_bound(unitgroup=ug,commoditygroup = cg)
    )
end
