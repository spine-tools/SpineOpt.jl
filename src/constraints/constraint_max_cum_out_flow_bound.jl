# function absolutebounds(m::Model,flow)
#      @constraint(m,
#      + sum(flow[c, n, u, "in", t] for u in ["GasPlant","CHPPlant"],c in input_com(u),n in NodeUnitConnection(u), t in 1:number_of_timesteps)
#      <= 10^8
#      )
# end

function constraint_max_cum_out_flow_bound(m::Model,flow)
    for ug in unitgroup()
        # Check that all units of unitgroup have the same input commodity
        if !foldl(==, [unit__input_commodity(unit=u) for u in unitgroup__unit(unitgroup=ug)])
            error("The input commodities within unitgroup '", ug, "' are not equal")
        end
        if max_cum_in_flow_bound(unitgroup=ug) == nothing
            continue
        end
        @constraint(m,
            + sum(flow[c, n, u, "in", t]
                for u in unitgroup__unit(unitgroup=ug),
                    c in commodity(),
                    n in node(),
                    t = 1:number_of_timesteps(time="timer")
                if ["in"] in commodity__node__unit__direction(
                    commodity=c,
                    node=n,
                    unit=u
                )
            )
            <=
            + max_cum_in_flow_bound(unitgroup=ug)
        )
    end
end
