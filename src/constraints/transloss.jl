### t.b.d.
function constraint_translosse(m::Model, trans)
    @constraint(m, [c in commodity(), t=1:number_of_timesteps, !isnull(TransLoss_[u,n])], #for all simmetric connections
        + (trans[u, n, t] for u in unit_output_commodity(c)) * TransLoss_[u,n] ### to have a look at
        >= (-trans[u, n, t] for u in unit_output_commodity(c))
    )
end

for c in connection()
    for n in connection(n) && m in connection(m) && m!=n
        @constraint(m, [c in commodity(), t=1:number_of_timesteps, !isnull(TransLoss_[c,n])], #for all simmetric connections
            + (trans[c, n, t]) * TransLoss_[c,n] ### to have a look at
            >= (-trans[c, m, t])
        )
    end
end
