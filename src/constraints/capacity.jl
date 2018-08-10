function capacity(m::Model, flow,number_of_timesteps)
    @constraint(m, [u in unit(), t=1:number_of_timesteps; !isnull(capacity(u))],
        + sum(flow[c, u, "out", t] for c in capa_defining_com(u) if c in output_com(u))
        + sum(flow[c, u, "in", t] for c in capa_defining_com(u) if c in input_com(u))
        <= AF(u) * CapToFlow(u) * capacity(u)
    )
end
