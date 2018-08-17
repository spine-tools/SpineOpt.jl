# function absolutebounds(m::Model,flow)
#      @constraint(m,
#      + sum(flow[c, n, u, "in", t] for u in ["GasPlant","CHPPlant"],c in input_com(u),n in NodeUnitConnection(u), t in 1:number_of_timesteps)
#      <= 10^8
#      )
# end

function absolutebounds_UnitGroups(m::Model,flow, number_of_timesteps)

     for ug in unit_groups() #test if all units of unitgroup have the some input commodity
          all([input_com(u) == input_com(get_units_of_unitgroup(ug)[1]) for u in get_units_of_unitgroup(ug)])?nothing:error("The input commodies within unit group", ug, "are not equal")
     end


     for ug in unit_groups()
          @constraint(m,
          + sum(flow[c, n, u, "in", t] for u in get_units_of_unitgroup(ug),c in input_com(u),n in NodeUnitConnection(u), t in 1:number_of_timesteps)
          <= MaxCumInFlowBound(ug)
          )
     end
end
