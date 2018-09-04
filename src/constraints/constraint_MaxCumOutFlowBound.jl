# function absolutebounds(m::Model,flow)
#      @constraint(m,
#      + sum(flow[c, n, u, "in", t] for u in ["GasPlant","CHPPlant"],c in input_com(u),n in NodeUnitConnection(u), t in 1:number_of_timesteps)
#      <= 10^8
#      )
# end

function constraint_MaxCumOutFlowBound(m::Model,flow)
     #
     # for ug in unitgroup() #test if all units of unitgroup have the some input commodity
     #      all([input_commodity(u) == input_commodity(generate_UnitGroups(ug)[1]) for u in generate_UnitGroups(ug)])?nothing:error("The input commodies within unit group", ug, "are not equal")
     # end
          @constraint(m,[ug in unitgroup(), cg in commoditygroup(); !(p_MaxCumInFlowBound(unitgroup = ug,commoditygroup = cg)===nothing)],
          + sum(flow[c, n, u, "in", t] for u in unitgroup_unit(unitgroup = ug), c in commoditygroup_commodity(commoditygroup = cg), n in node(), t in 1:number_of_timesteps(time = "timer") if [c,n,u,"in"] in commodity_node_unit_direction())
          <=
          + p_MaxCumInFlowBound(unitgroup = ug,commoditygroup = cg)
          )
end
