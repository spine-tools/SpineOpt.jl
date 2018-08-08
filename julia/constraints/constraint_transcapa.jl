function constraint_outinratio(m::Model, flow)
    @constraint(m, [con in connection() t=1:number_of_timestept,  !isnull(ratio_output_input_flow(u))],
        + trans[u, n, t] *
        == ratio_output_input_flow(u) * sum(flow[c, u, "in", t] for c in unit_input_commodity(u))
    )
end
