### t.b.d.
function constraint_TransLoss(m::Model, trans)
        @constraint(m, [con in connection(), i in node(),j in node(), t=1:number_of_timesteps(time="timer"); all([[con,i,j] in connection_node_node(),!(p_TransLoss(connection=con,node1=i,node2=j) === nothing)])], #for all symmetric connections
        + (trans[connection = con, node1=i, node2=j, t=t])
                * p_TransLoss(connection=con,node1=i,node2=j) ### to have a look at
        >=
        - (trans[connection=con, node1=j, node2=i ,t=t]))
end
