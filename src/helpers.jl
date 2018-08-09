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

function find_con_node(con, jfo)
    """"
    finds pairs of nodes with the same commodity for a given connection "con"
        con: string
        return: list of connection lists (per commidity) e.g. [[["n1", "n2"], ["n2", "n1"]],[["n3", "n4"], ["n4", "n3"]]]
    """
    nodes = jfo["NodeConnectionRelationship"][con]
    com_nodes = [jfo["CommodityAffiliation"][n][1] for n in nodes]
    function find_node_com(nodes, com_nodes, com)
        ind=find(com_nodes -> com_nodes == com,com_nodes)
        if length(ind) == 2
            return [[nodes[ind[1]],nodes[ind[2]]],[nodes[ind[2]],nodes[ind[1]]]]
        elseif length(ind) == 0
            return NaN
        else
            error("found more than two nodes with the same commodity")
        end
    end
    nodepairs=[]
    for c in commodity()
        np = find_node_com(nodes, com_nodes, c)
        if  np !== NaN
            push!(nodepairs,np)
        end    end
    return nodepairs
end
