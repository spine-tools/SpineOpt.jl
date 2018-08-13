### t.b.d.
function transloss(m::Model, trans,number_of_timesteps,jfo)
        @constraint(m, [ c in connection(), i in node(),j in node(), t=1:number_of_timesteps; [c,i,j] in get_all_connection_node_pairs(jfo,true)], #for all simmetric connections
        + (trans[c,i,j,t])* TranLoss_a("ElectricityLine1") ### to have a look at
        >= -(trans[c,j,i ,t]))
end

# for c in connection()
#     for n in connection(n) && m in connection(m) && m!=n
#         @constraint(m, [c in commodity(), t=1:number_of_timesteps, !isnull(TransLoss_[c,n])], #for all simmetric connections
#             + (trans[c, n, t]) * TransLoss_[c,n] ### to have a look at
#             >= (-trans[c, m, t])
#         )
#     end
# end


### t.b.d.
# function transloss(m::Model, trans,number_of_timesteps,jfo)
#         @constraint(m, [ c in connection(), i in node(),j in node(); [c,i,j] in get_all_connection_node_pairs(jfo,true), t=1:number_of_timesteps], #for all simmetric connections
#         + (trans[[c,i,j] ,t])# * TransLoss_[u,n] ### to have a look at
#         == (trans[[c,j,i] ,t]))
# end

# for c in connection()
#     for n in connection(n) && m in connection(m) && m!=n
#         @constraint(m, [c in commodity(), t=1:number_of_timesteps, !isnull(TransLoss_[c,n])], #for all simmetric connections
#             + (trans[c, n, t]) * TransLoss_[c,n] ### to have a look at
#             >= (-trans[c, m, t])
#         )
#     end
# end
