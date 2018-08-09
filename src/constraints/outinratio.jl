function constraint_outinratio(m::Model, flow)
    @constraint(m, [u in unit(), t=1:24; !isnull(ratio_output_input_flow(u))],
        + sum(flow[c, u, "out", t] for c in unit_output_commodity(u))
        == ratio_output_input_flow(u) * sum(flow[c, u, "in", t] for c in unit_input_commodity(u))
    )
end
