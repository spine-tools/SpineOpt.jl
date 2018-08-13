function absolutebounds(m::Model,flow)
     @constraint(m,
     + sum(flow[c, n, u, "in", t] for u in ["GasPlant","CHPPlant"],c in input_com(u),n in NodeUnitConnection(u), t in 1:number_of_timesteps)
     <= 10^8
     )
end
