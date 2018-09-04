function generate_variable_v_Flow(m::Model)
    @variable(m, v_Flow[c in commodity(), n in node(), u in unit(), d in direction() , t = 1:number_of_timesteps(time="timer"); [c,n,u,d] in commodity_node_unit_direction()]>= 0)
end
