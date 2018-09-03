# FIXME: some names here don't respect the lower_case convention
# function absolutebounds(m::Model,flow)
#      @constraint(m,
#      + sum(flow[c, n, u, "in", t] for u in ["GasPlant","CHPPlant"],c in input_com(u),n in NodeUnitConnection(u), t in 1:number_of_timesteps)
#      <= 10^8
#      )
# end

function constraint_MaxCumOutFlowBound(m::Model,flow)
    for ug in unitgroup()
        # Check that all units of unitgroup have the same input commodity
        if !foldl(==, [input_commodity(unit=u) for u in unitgroup_unit(unitgroup=ug)])
            error("The input commodities within unitgroup '", ug, "' are not equal")
        end
        if p_MaxCumInFlowBound(unitgroup=ug) == nothing
            continue
        end
        @constraint(m,
            + sum(flow[c, n, u, "in", t]
                for u in unitgroup_unit(unitgroup=ug),
                    c in commodity(),
                    n in node(),
                    t = 1:number_of_timesteps(time="timer")
                if ["in"] in commodity_node_unit_direction(
                    commodity=c,
                    node=n,
                    unit=u
                )
            )
            <=
            + p_MaxCumInFlowBound(unitgroup=ug)
        )
    end
end
