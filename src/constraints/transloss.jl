### t.b.d.
function transloss(m::Model, trans)
        @constraint(m, [ c in connection(), i in node(),j in node(), t=1:number_of_timesteps("timer"); [c,i,j] in get_all_connection_node_pairs()], #for all simmetric connections
        + (trans[c,i,j,t])* TranLoss_a("ElectricityLine1") ### to have a look at
        >= -(trans[c,j,i ,t]))
end

