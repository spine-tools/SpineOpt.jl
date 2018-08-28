function generate_ConnectionNodePairs()
    ConnectionNodePairs = []
    for k in connection()
        for i in eval(parse(:($node_connection_rel)))(connection=k)
            for j in eval(parse(:($node_connection_rel)))(connection=k)
                if all([i != j, eval(parse(:($node_commodity_rel)))(node=i[1]) ==eval(parse(:($node_commodity_rel)))(node=j[1])])
                    ConnectionNodePairs  = vcat(ConnectionNodePairs, [vcat([k,i[1],j[1]])])
                end
            end
        end
    end
    return ConnectionNodePairs
end
