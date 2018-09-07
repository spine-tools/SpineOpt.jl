"""
    constraint_fix_ratio_out_in_flow(m::Model, flow)

Fix ratio between the output `flow` of a `commodity_group` to an input `flow` of a
`commodity_group` for each `unit` for which the parameter `fix_ratio_out_in_flow`
is specified.
"""
function constraint_fix_ratio_out_in_flow(m::Model, v_flow)
    @constraint(
        m,
        [
            u in unit(),
            cg_out in commoditygroup(),
            cg_in in commoditygroup(),
            t=1:number_of_timesteps(time="timer");
            fix_ratio_out_in_flow(unit=u, commoditygroup1=cg_out, commoditygroup2=cg_in) != nothing
        ],
        + sum(v_flow[c_out, n, u, "out", t] for c_out in commoditygroup__commodity(commoditygroup=cg_out), n in node()
            if [c_out, n, u] in commodity__node__unit__direction(direction="out"))
        ==
        + fix_ratio_out_in_flow(unit=u, commoditygroup1=cg_out, commoditygroup2=cg_in)
            * sum(v_flow[c_in, n, u, "in", t] for c_in in commoditygroup__commodity(commoditygroup=cg_in), n in node()
                if [c_in, n, u] in commodity__node__unit__direction(direction="in"))
    )
end
