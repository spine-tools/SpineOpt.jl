"""
    constraint_max_cum_in_flow_bound(m::Model, flow)

Set upperbound `max_cum_in_flow_bound `to the cumulated inflow of
`commoditygroup cg` into a `unitgroup ug`
if `max_cum_in_flow_bound` exists for the combination of `cg` and `ug`.
"""
function constraint_max_cum_in_flow_bound(m::Model, flow)
    @constraint(
    m,
    [
        ug in unitgroup(),
        cg in commoditygroup();
        max_cum_in_flow_bound(unitgroup=ug, commoditygroup=cg) != nothing
    ],
        + sum(flow[c, n, u, "in", t]
            for u in unitgroup__unit(unitgroup=ug),
                c in commoditygroup__commodity(commoditygroup=cg),
                n in node(),
                t=1:number_of_timesteps(time="timer")
                if [c, n, u, "in"] in commodity__node__unit__direction()
            )
        <=
        + max_cum_in_flow_bound(unitgroup=ug, commoditygroup=cg)
    )
end
