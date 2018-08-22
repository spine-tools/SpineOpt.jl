function generate_ConnectionNodePairs()
    ConnectionNodePairs = []
    for k in connection()
        for i in eval(parse(:($node_connection_rel)))(k)
            for j in eval(parse(:($node_connection_rel)))(k)
                if all([i != j, eval(parse(:($node_commodity_rel)))(i) ==eval(parse(:($node_commodity_rel)))(j)])
                    ConnectionNodePairs  = vcat(ConnectionNodePairs, [vcat([k,i,j])])
                end
            end
        end
    end
    return ConnectionNodePairs
end
