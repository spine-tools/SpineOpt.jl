function constraint_capacity(m::Model, flow)
    @constraint(m, [u in unit(), t=1:24; !isnull(capacity(u))],
        + sum(flow[c, u, "out", t] for c in unit_capacity_defining_commodity(u) if c in unit_output_commodity(u))
        + sum(flow[c, u, "in", t] for c in unit_capacity_defining_commodity(u) if c in unit_input_commodity(u))
        <= availability_factor(u, t) * capacity_to_flow(u) * capacity(u)
    )
end
