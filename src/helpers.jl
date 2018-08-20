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


function get_units_of_unitgroup(unitgroup)
        eval(parse(:($unitgroup_unit_rel)))(unitgroup)
end

function get_com_node_unit()
    """
        return list of connection list of all unit node connections [Commodity, Node, Unit, in/out]
        e.g. [["Coal", "BelgiumCoal", "CoalPlant", "in"], ["Electricity", "LeuvenElectricity", "CoalPlant", "out"],...]
    """
    #
    list_of_connections = []
    for u in unit()
        for n in eval(parse(:($node_unit_rel)))(u)
            for c in eval(parse(:($node_commodity_rel)))(n)
                if c in eval(parse(:($unit_commidity_input_rel)))(u)
                    push!(list_of_connections, [c,n,u,"in"])
                end
                if c in eval(parse(:($unit_commidity_output_rel)))(u)
                    push!(list_of_connections, [c,n,u,"out"])
                end
            end
        end
    end
    return list_of_connections
end

function get_all_connection_node_pairs()
    list_of_con_node_pairs = []
    for k in connection()
        for i in eval(parse(:($node_connection_rel)))(k)
            for j in eval(parse(:($node_connection_rel)))(k)
                if all([i != j, eval(parse(:($node_commodity_rel)))(i) ==eval(parse(:($node_commodity_rel)))(j)])
                    list_of_con_node_pairs  = vcat(list_of_con_node_pairs, [vcat([k,i,j])])
                end
            end
        end
    end
    return list_of_con_node_pairs
end
