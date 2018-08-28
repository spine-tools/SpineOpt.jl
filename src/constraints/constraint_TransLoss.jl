### t.b.d.
function constraint_TransLoss(m::Model, trans)
        @constraint(m, [ con in connection(), i in node(),j in node(), t=1:number_of_timesteps("timer"); [con,i,j] in generate_ConnectionNodePairs()], #for all simmetric connections
        + (trans[con,i,j,t])
                * p_TransLoss(con,i,j) ### to have a look at
        >=
        - (trans[c,j,i ,t]))
end
