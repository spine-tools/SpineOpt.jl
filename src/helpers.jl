"""
    @suppress_err expr
Suppress the STDERR stream for the given expression.
"""
# NOTE: Borrowed from Suppressor.jl
macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end
    end
end




function find_nodes(con, jfo, add_permutation=true,rel_node_connection = "NodeConnectionRelationship", rel_commodity = "CommodityAffiliation")
    """"
    finds pairs of nodes with the same commodity for a given connection "con"
        con: string
        jfo:
        rel_node_connection: string, relationship class name
        rel_commodity: string, relationship class name
        return: list of connection lists (per commidity) e.g. [[["n1", "n2"], ["n2", "n1"]],[["n3", "n4"], ["n4", "n3"]]]
    """
    function find_node_com(nodes, com_nodes, com, add_permutation=false)
        """
        helperfunction
        """
        ind=find(com_nodes -> com_nodes == com,com_nodes)
        if length(ind) == 2
            if add_permutation
                return [[nodes[ind[1]],nodes[ind[2]]],[nodes[ind[2]],nodes[ind[1]]]]
            else
                return [[nodes[ind[1]],nodes[ind[2]]]]
            end
        elseif length(ind) == 0
            return NaN
        else
            error("found more than two nodes with the same commodity")
        end
    end
    nodes = jfo[rel_node_connection][con]
    com_nodes = [jfo[rel_commodity][n][1] for n in nodes]
    nodepairs=[]
    for c in commodity()
        np = find_node_com(nodes, com_nodes, c, add_permutation)
        if  np !== NaN
            nodepairs=vcat(nodepairs,np)
        end
    end
    return nodepairs
end

function find_connections(node, jfo, add_permutation = false, rel_node_connection = "NodeConnectionRelationship")
    """
    find all connection objects connected to the given node "node"
        node: string
        jfo:
        rel_node_connection: string, relationship class name
        return: list of connections list of connection lists [["con1","n1", "n2"], ["con2","n1", "n4"],...]
    """
    rels = jfo[rel_node_connection]
    nodecons=[p for p in rels if p[1] == node]
    list_of_pairs=[]
    if add_permutation
        for p in nodecons
            for con in p.second
                push!(list_of_pairs, [con, rels[con][1],rels[con][2]])
                push!(list_of_pairs, [con, rels[con][2],rels[con][1]])
            end
        end
    else
        for p in nodecons
            for con in p.second
                push!(list_of_pairs, [con, rels[con][1],rels[con][2]])
            end
        end
    end
    return list_of_pairs
end

function get_all_connection_node_pairs(jfo, add_permutation=false)
    """"
    returns all pairs of nodes which are connected through a connections
        jfo:
        add_permutation: add an additional entry with permuted nodes e.g. ["con1","n1", "n2"], ["con1","n2", "n1"]
        return: list of connection lists [["con1","n1", "n2"], ["con2","n3", "n4"],...]
    """
    list_of_pairs=[]
    for c in connection()
        list_of_pairs=vcat(list_of_pairs, [vcat(c,p) for p in find_nodes(c, jfo, add_permutation)])
    end
    return list_of_pairs
end
