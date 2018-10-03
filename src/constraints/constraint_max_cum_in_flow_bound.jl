"""
    constraint_max_cum_in_flow_bound(m::Model, flow)

Set upperbound `max_cum_in_flow_bound `to the cumulated inflow of
`commodity_group cg` into a `unit_group ug`
if `max_cum_in_flow_bound` exists for the combination of `cg` and `ug`.
"""
function constraint_max_cum_in_flow_bound(m::Model, flow)
    @constraint(
    m,
    [
        ug in unit_group(),
        cg in commodity_group();
        max_cum_in_flow_bound(unit_group=ug, commodity_group=cg) != nothing
    ],
        + sum(flow[c, n, u, "in", t]
            for u in unit_group__unit(unit_group=ug),
                c in commodity_group__commodity(commodity_group=cg),
                n in node(),
                t=1:number_of_timesteps(time="timer")
                if [c, n, u, "in"] in commodity__node__unit__direction()
            )
        <=
        + max_cum_in_flow_bound(unit_group=ug, commodity_group=cg)
    )
end
