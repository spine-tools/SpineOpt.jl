"""
    constraint_trans_loss(m::Model, trans)

Enforce losses on transmissions depending on the obeserved direction if the parameter
`trans_loss(connection=con, node1=i, node2=j)` is specified.

#Examples
```julia
trans_loss(connection=con, node1=i, node2=j) != trans_loss(connection=con, node2=i, node1=j)
```
"""
function constraint_trans_loss(m::Model, trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            all([
                [i, j] in connection__node__node(connection=con),
                trans_loss(connection=con, node1=i, node2=j) != nothing
            ])
        ],
        + (trans[con, i, j, t])
            * trans_loss(connection=con, node1=i, node2=j)
        >=
        - (trans[con, j, i ,t]))
end
