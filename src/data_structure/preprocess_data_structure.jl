#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    preprocess_data_structure()

Preprocess input data structure for SpineOpt.

Runs a number of other functions processing different aspecs of the input data in sequence.
"""
function preprocess_data_structure(; log_level=3)
    generate_is_cadidate()
    expand_model_default_relationships()
    expand_node__stochastic_structure()
    expand_units_on__stochastic_structure()
    # NOTE: generate direction before calling `generate_network_components`,
    # so calls to `connection__from_node` don't corrupt lookup cache
    add_connection_relationships()
    generate_direction()
    process_loss_bidirectional_capacities()
    generate_network_components()
    generate_variable_indexing_support()
    generate_benders_structure()
end


"""
    generate_is_candidate()

Generate `is_candidate` for the `node`, `unit` and `connection` `ObjectClass`es.
"""
function generate_is_cadidate()
    is_candidate = Parameter(:is_candidate, [node, unit, connection])    
    for c in indices(candidate_connections)        
        connection.parameter_values[c][:is_candidate] = parameter_value(true)
    end
    for u in indices(candidate_units)        
        unit.parameter_values[u][:is_candidate] = parameter_value(true)
    end
    for n in indices(candidate_storages)        
        node.parameter_values[n][:is_candidate] = parameter_value(true)
    end
    
    @eval begin
        is_candidate = $is_candidate
    end
end


function preprocess_model_data_structure(m::Model; log_level=3)

end

"""
    expand_node__stochastic_structure()

Expand the `node__stochastic_structure` `RelationshipClass` for with individual `nodes` in `node_groups`.
"""
function expand_node__stochastic_structure()
    add_relationships!(
        node__stochastic_structure,
        [
            (node=n, stochastic_structure=stochastic_structure)
            for (ng, stochastic_structure) in node__stochastic_structure() for n in members(ng)
        ],
    )
end

"""
    expand_units_on__stochastic_structure()

Expand the `units_on__stochastic_structure` `RelationshipClass` for with individual `units` in `unit_groups`.
"""
function expand_units_on__stochastic_structure()
    add_relationships!(
        units_on__stochastic_structure,
        [
            (unit=u, stochastic_structure=stochastic_structure)
            for (ug, stochastic_structure) in units_on__stochastic_structure() for u in members(ug)
        ],
    )
end

"""
    add_connection_relationships()

Add connection relationships for connection_type=:connection_type_lossless_bidirectional.

For connections with this parameter set, only a connection__from_node and connection__to_node need be set
and this function creates the additional relationships on the fly.
"""
function add_connection_relationships()    
    conn_from_to = [
        (conn, first(connection__from_node(connection=conn)), first(connection__to_node(connection=conn)))
        for conn in connection(connection_type=:connection_type_lossless_bidirectional)
    ]
    isempty(conn_from_to) && return
    new_connection__from_node_rels = [(connection=conn, node=n) for (conn, _n, n) in conn_from_to]
    new_connection__to_node_rels = [(connection=conn, node=n) for (conn, n, _n) in conn_from_to]
    new_connection__node__node_rels =
        collect((connection=conn, node1=n1, node2=n2) for (conn, x, y) in conn_from_to for (n1, n2) in ((x, y), (y, x)))
    add_relationships!(connection__from_node, new_connection__from_node_rels)
    add_relationships!(connection__to_node, new_connection__to_node_rels)
    add_relationships!(connection__node__node, new_connection__node__node_rels)
    value_one = parameter_value(1.0)
    new_connection__from_node_parameter_values = Dict(
        (conn, n) => Dict(:connection_conv_cap_to_flow => value_one) for (conn, n) in new_connection__from_node_rels
    )    

    new_connection__to_node_parameter_values = Dict(
        (conn, n) => Dict(:connection_conv_cap_to_flow => value_one) for (conn, n) in new_connection__to_node_rels)

    new_connection__node__node_parameter_values = Dict(
        (conn, n1, n2) => Dict(:fix_ratio_out_in_connection_flow => value_one)
        for (conn, n1, n2) in new_connection__node__node_rels
    )
    merge!(connection__from_node.parameter_values, new_connection__from_node_parameter_values)
    merge!(connection__to_node.parameter_values, new_connection__to_node_parameter_values)
    merge!(connection__node__node.parameter_values, new_connection__node__node_parameter_values)
end

"""
    generate_direction()

Generate the `direction` `ObjectClass` and its relationships.
"""
function generate_direction()
    from_node = Object(:from_node)
    to_node = Object(:to_node)
    direction = ObjectClass(:direction, [from_node, to_node])
    directions_by_class = Dict(
        unit__from_node => from_node,
        unit__to_node => to_node,
        connection__from_node => from_node,
        connection__to_node => to_node,
    )
    for cls in keys(directions_by_class)
        push!(cls.object_class_names, :direction)
    end
    for (cls, d) in directions_by_class
        map!(rel -> (; rel..., direction=d), cls.relationships, cls.relationships)
        key_map = Dict(rel => (rel..., d) for rel in keys(cls.parameter_values))
        for (key, new_key) in key_map
            cls.parameter_values[new_key] = pop!(cls.parameter_values, key)
        end
    end
    @eval begin
        direction = $direction
        export direction
    end
end

"""
    process_loss_bidirectional_capacities()

    For connections of type `:connection_type_lossless_bidirectional` if a `connection_capacity` is found
    we ensure that it appies to each of the four flow variables

"""

function process_loss_bidirectional_capacities()
    for c in connection(connection_type=:connection_type_lossless_bidirectional)
        conn_capacity_param = nothing
        found_from = false
        for (n, d) in connection__from_node(connection=c)
            found_value = get(connection__from_node.parameter_values[(c, n, d)], :connection_capacity, nothing)
            if found_value !== nothing
                conn_capacity_param = found_value
                found_from = true
                for n2 in connection__from_node(connection=c, direction=d)
                    if n2 != n
                        connection__from_node.parameter_values[(c, n2, d)][:connection_capacity] = conn_capacity_param
                    end
                end
            end
        end
        found_to = false
        for (n, d) in connection__to_node(connection=c)
            found_value = get(connection__to_node.parameter_values[(c, n, d)], :connection_capacity, nothing)
            if found_value !== nothing
                conn_capacity_param = found_value
                found_to = true
                for n2 in connection__to_node(connection=c, direction=d)
                    if n2 != n
                        connection__to_node.parameter_values[(c, n2, d)][:connection_capacity] = conn_capacity_param
                    end
                end
            end
        end
        if !found_from && conn_capacity_param !== nothing
            for (n, d) in connection__from_node(connection=c)                
                connection__from_node.parameter_values[(c, n, d)][:connection_capacity] = conn_capacity_param
            end            
        end
        if !found_to && conn_capacity_param !== nothing
            for (n, d) in connection__to_node(connection=c)                
                connection__to_node.parameter_values[(c, n, d)][:connection_capacity] = conn_capacity_param
            end            
        end        
    end
end

# Network stuff
"""
    generate_node_has_ptdf()

Generate `has_ptdf` and `node_ptdf_threshold` parameters associated to the `node` `ObjectClass`.
"""
function generate_node_has_ptdf()
    for n in node()
        ptdf_comms = Tuple(
            c
            for
            c in node__commodity(node=n) if
            commodity_physics(commodity=c) in (:commodity_physics_lodf, :commodity_physics_ptdf)
        )
        node.parameter_values[n][:has_ptdf] = parameter_value(!isempty(ptdf_comms))
        node.parameter_values[n][:node_ptdf_threshold] =
            parameter_value(reduce(max, (commodity_ptdf_threshold(commodity=c) for c in ptdf_comms); init=0.0000001))
    end
    has_ptdf = Parameter(:has_ptdf, [node])
    node_ptdf_threshold = Parameter(:node_ptdf_threshold, [node])
    @eval begin
        has_ptdf = $has_ptdf
        node_ptdf_threshold = $node_ptdf_threshold
    end
end

"""
    generate_connection_has_ptdf()

Generate `has_ptdf` parameter associated to the `connection` `ObjectClass`.
"""
function generate_connection_has_ptdf()
    for conn in connection()
        from_nodes = connection__from_node(connection=conn, direction=anything)
        to_nodes = connection__to_node(connection=conn, direction=anything)
        is_bidirectional = length(from_nodes) == 2 && isempty(symdiff(from_nodes, to_nodes))
        is_loseless =
            fix_ratio_out_in_connection_flow(; connection=conn, zip((:node1, :node2), from_nodes)..., _strict=false) ==
            1
        connection.parameter_values[conn][:has_ptdf] =
            parameter_value(is_bidirectional && is_loseless && all(has_ptdf(node=n) for n in from_nodes))
    end
    push!(has_ptdf.classes, connection)
end

"""
    generate_connection_has_lodf()

Generate `has_lodf` and `connnection_lodf_tolerance` parameters associated to the `connection` `ObjectClass`.
"""
function generate_connection_has_lodf()
    for conn in connection(has_ptdf=true)
        lodf_comms = Tuple(
            c
            for
            c in commodity(commodity_physics=:commodity_physics_lodf) if
            issubset(connection__from_node(connection=conn, direction=anything), node__commodity(commodity=c))
        )
        connection.parameter_values[conn][:has_lodf] = parameter_value(!isempty(lodf_comms))
        connection.parameter_values[conn][:connnection_lodf_tolerance] =
            parameter_value(reduce(max, (commodity_lodf_tolerance(commodity=c) for c in lodf_comms); init=0.05))
    end
    has_lodf = Parameter(:has_lodf, [connection])
    connnection_lodf_tolerance = Parameter(:connnection_lodf_tolerance, [connection]) # TODO connnection with 3 `n`'s?
    @eval begin
        has_lodf = $has_lodf
        connnection_lodf_tolerance = $connnection_lodf_tolerance
    end
end

function _build_ptdf(connections, nodes)
    nodecount = length(nodes)
    conncount = length(connections)
    node_numbers = Dict{Object,Int32}(n => ix for (ix, n) in enumerate(nodes))

    A = zeros(Float64, nodecount, conncount)  # incidence_matrix
    inv_X = zeros(Float64, conncount, conncount)

    for (ix, conn) in enumerate(connections)
        # NOTE: always assume that the flow goes from the first to the second node in `connection__from_node`
        from_n, to_n = connection__from_node(connection=conn, direction=anything)
        A[node_numbers[from_n], ix] = 1
        A[node_numbers[to_n], ix] = -1
        inv_X[ix, ix] = 1 / max(connection_reactance(connection=conn), 0.00001)
    end

    i = findfirst(n -> node_opf_type(node=n) == :node_opf_type_reference, nodes)
    if i === nothing
        error("slack node not found")
    end
    slack = nodes[i]
    slack_position = node_numbers[slack]
    B = gemm(
        'N',
        'T',
        gemm('N', 'N', A[setdiff(1:end, slack_position), 1:end], inv_X),
        A[setdiff(1:end, slack_position), 1:end],
    )
    B, bipiv, binfo = getrf!(B)
    if binfo < 0
        error("illegal argument in inputs")  # FIXME: come up with a better message
    elseif binfo > 0
        error("singular value in factorization, possibly there is an islanded bus")
    end
    S_ = gemm(
        'N',
        'N',
        gemm('N', 'T', inv_X, A[setdiff(1:end, slack_position), :]),
        getri!(B, bipiv),
    )
    hcat(S_[:, 1:(slack_position - 1)], zeros(conncount), S_[:, slack_position:end])
end

"""
    _ptdf_values()

Calculate the values of the `ptdf` parameter.
"""
function _ptdf_values()
    nodes = node(has_ptdf=true)
    isempty(nodes) && return Dict()
    connections = connection(has_ptdf=true)
    ptdf = _build_ptdf(connections, nodes)
    Dict(
        (conn, n) => Dict(:ptdf => parameter_value(ptdf[i, j]))
        for (i, conn) in enumerate(connections) for (j, n) in enumerate(nodes)
    )
end

function _old_ptdf_values()
    ps_busses_by_node = Dict(
        n => Bus(
            number=i,
            name=string(n.name),
            bustype=(node_opf_type(node=n) == :node_opf_type_reference) ? BusTypes.REF : BusTypes.PV,
            angle=0.0,
            magnitude=0.0,
            voltage_limits=(min=0.0, max=0.0),
            base_voltage=nothing,
            area=nothing,
            load_zone=LoadZone(nothing),
            ext=Dict{String,Any}(),
        ) for (i, n) in enumerate(node(has_ptdf=true))
    )
    isempty(ps_busses_by_node) && return Dict()
    ps_busses = collect(values(ps_busses_by_node))
    PowerSystems.buscheck(ps_busses)
    PowerSystems.slack_bus_check(ps_busses)
    ps_lines_by_connection = Dict(
        conn => Line(;
            name=string(conn.name),
            available=true,
            active_power_flow=0.0,
            reactive_power_flow=0.0,
            arc=Arc((ps_busses_by_node[n] for n in connection__from_node(connection=conn, direction=anything))...),
            r=connection_resistance(connection=conn),
            x=max(connection_reactance(connection=conn), 0.00001),
            b=(from=0.0, to=0.0),
            rate=0.0,
            angle_limits=(min=0.0, max=0.0),
        )  # NOTE: always assume that the flow goes from the first to the second node in `connection__from_node`
        for
        conn in connection(has_ptdf=true)
    )
    ps_lines = collect(values(ps_lines_by_connection))
    ps_ptdf = PowerSystems.PTDF(ps_lines, ps_busses)
    Dict(
        (conn, n) => Dict(:ptdf => parameter_value(ps_ptdf[line.name, bus.number]))
        for (conn, line) in ps_lines_by_connection for (n, bus) in ps_busses_by_node
    )
end

"""
    generate_ptdf()

Generate the `ptdf` parameter.
"""
function generate_ptdf()
    ptdf_values = _ptdf_values()
    ptdf_rel_cls = RelationshipClass(
        :ptdf_connection__node,
        [:connection, :node],
        [(connection=conn, node=n) for (conn, n) in keys(ptdf_values)],
        ptdf_values,
    )
    ptdf = Parameter(:ptdf, [ptdf_rel_cls])
    @eval begin
        ptdf = $ptdf
    end
end

"""
    generate_lodf()

Generate the `lodf` parameter.
"""
function generate_lodf()
    """
    Given a contingency connection, return a function that given the monitored connection, return the lodf.
    """
    function make_lodf_fn(conn_cont)
        n_from, n_to = connection__from_node(connection=conn_cont, direction=anything)
        denom = 1 - (ptdf(connection=conn_cont, node=n_from) - ptdf(connection=conn_cont, node=n_to))
        is_tail = isapprox(denom, 0; atol=0.001)
        if is_tail
            conn_mon -> ptdf(connection=conn_mon, node=n_to)
        else
            conn_mon -> (ptdf(connection=conn_mon, node=n_from) - ptdf(connection=conn_mon, node=n_to)) / denom
        end
    end

    lodf_values = Dict(
        (conn_cont, conn_mon) => Dict(:lodf => parameter_value(lodf_trial))
        for
        (conn_cont, lodf_fn, tolerance) in (
            (conn_cont, make_lodf_fn(conn_cont), connnection_lodf_tolerance(connection=conn_cont)) for                        
            conn_cont in connection(has_ptdf=true)
        )        
        for
        (conn_mon, lodf_trial) in
        ((conn_mon, lodf_fn(conn_mon)) for conn_mon in connection(has_ptdf=true)) if
          conn_cont !== conn_mon #&& !isapprox(lodf_trial, 0; atol=tolerance)        
    )
    lodf_rel_cls = RelationshipClass(
        :lodf_connection__connection,
        [:connection1, :connection2],
        [(connection1=conn_cont, connection2=conn_mon) for (conn_cont, conn_mon) in keys(lodf_values)],
        lodf_values,
    )
    lodf = Parameter(:lodf, [lodf_rel_cls])
    @eval begin
        lodf = $lodf
    end
end

"""
    generate_network_components()

Generate different network related `parameters`.

Runs a number of other functions dealing with different aspects of the network data in sequence.
"""
function generate_network_components()
    generate_node_has_ptdf()
    generate_connection_has_ptdf()
    generate_connection_has_lodf()
    generate_ptdf()
    generate_lodf()
    # the below needs the parameters write_ptdf_file and write_lodf_file - we can uncomment when we update the template perhaps?
    # write_ptdf_file(model=first(model(model_type=:spineopt_operations))) == Symbol(:true) && write_ptdfs()
    # write_lodf_file(model=first(model(model_type=:spineopt_operations))) == Symbol(:true) && write_lodfs()
end

"""
    generate_variable_indexing_support()

TODO What is the purpose of this function? It clearly generates a number of `RelationshipClasses`, but why?
"""
function generate_variable_indexing_support()
    node_with_slack_penalty = ObjectClass(:node_with_slack_penalty, collect(indices(node_slack_penalty)))
    unit__node__direction__temporal_block = RelationshipClass(
        :unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb)
            for (u, n, d) in Iterators.flatten((unit__from_node(), unit__to_node()))
            for tb in node__temporal_block(node=n)
        ),
    )
    connection__node__direction__temporal_block = RelationshipClass(
        :connection__node__direction__temporal_block,
        [:connection, :node, :direction, :temporal_block],
        unique(
            (connection=conn, node=n, direction=d, temporal_block=tb)
            for (conn, n, d) in Iterators.flatten((connection__from_node(), connection__to_node()))
            for tb in node__temporal_block(node=n)
        ),
    )
    node_with_state__temporal_block = RelationshipClass(
        :node_with_state__temporal_block,
        [:node, :temporal_block],
        unique((node=n, temporal_block=tb) for n in node(has_state=true) for tb in node__temporal_block(node=n)),
    )
    start_up_unit__node__direction__temporal_block = RelationshipClass(
        :start_up_unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb) for (u, ng, d) in indices(max_startup_ramp)
            for n in members(ng) for tb in node__temporal_block(node=n)
        ),
    )
    nonspin_ramp_up_unit__node__direction__temporal_block = RelationshipClass(
        :nonspin_ramp_up_unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb) for (u, ng, d) in indices(max_res_startup_ramp)
            for n in members(ng) for tb in node__temporal_block(node=n)
        ),
    )
    ramp_up_unit__node__direction__temporal_block = RelationshipClass(
        :ramp_up_unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb) for (u, ng, d) in indices(ramp_up_limit)
            for n in members(ng) for tb in node__temporal_block(node=n)
            for
            (u, n, d, tb) in #setdiff(
            unit__node__direction__temporal_block(unit=u, node=n, direction=d, temporal_block=tb, _compact=false)#,
            # nonspin_ramp_up_unit__node__direction__temporal_block(
            #     unit=u, node=n, direction=d, temporal_block=tb, _compact=false
            # )
            # )
        ),
    )
    shut_down_unit__node__direction__temporal_block = RelationshipClass(
        :shut_down_unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb) for (u, ng, d) in indices(max_shutdown_ramp)
            for n in members(ng) for tb in node__temporal_block(node=n)
        ),
    )
    nonspin_ramp_down_unit__node__direction__temporal_block = RelationshipClass(
        :nonspin_ramp_down_unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb) for (u, ng, d) in indices(max_res_shutdown_ramp)
            for n in members(ng) for tb in node__temporal_block(node=n)
        ),
    )
    ramp_down_unit__node__direction__temporal_block = RelationshipClass(
        :ramp_down_unit__node__direction__temporal_block,
        [:unit, :node, :direction, :temporal_block],
        unique(
            (unit=u, node=n, direction=d, temporal_block=tb) for (u, ng, d) in indices(ramp_down_limit)
            for n in members(ng) for tb in node__temporal_block(node=n)
            for
            (u, n, d, tb) in setdiff(unit__node__direction__temporal_block(
                unit=u,
                node=n,
                direction=d,
                temporal_block=tb,
                _compact=false,
            ))
        ),
    )
    @eval begin
        node_with_slack_penalty = $node_with_slack_penalty
        unit__node__direction__temporal_block = $unit__node__direction__temporal_block
        connection__node__direction__temporal_block = $connection__node__direction__temporal_block
        node_with_state__temporal_block = $node_with_state__temporal_block
        start_up_unit__node__direction__temporal_block = $start_up_unit__node__direction__temporal_block
        nonspin_ramp_up_unit__node__direction__temporal_block = $nonspin_ramp_up_unit__node__direction__temporal_block
        ramp_up_unit__node__direction__temporal_block = $ramp_up_unit__node__direction__temporal_block
        shut_down_unit__node__direction__temporal_block = $shut_down_unit__node__direction__temporal_block
        nonspin_ramp_down_unit__node__direction__temporal_block =
            $nonspin_ramp_down_unit__node__direction__temporal_block
        ramp_down_unit__node__direction__temporal_block = $ramp_down_unit__node__direction__temporal_block
    end
end

"""
    expand_model_default_relationships()

Generate model default `temporal_block` and `stochastic_structure` relationships for non-specified cases.
"""
function expand_model_default_relationships()
    expand_model__default_temporal_block()
    expand_model__default_stochastic_structure()
    expand_model__default_investment_temporal_block()
    expand_model__default_investment_stochastic_structure()
end



"""
    expand_model__default_investment_temporal_block()

Process the `model__default_investment_temporal_block` relationship.

If a `unit__investment_temporal_block` relationship is not defined, then create one using
`model__default_investment_temporal_block`. Similarly, add the corresponding `model__temporal_block` relationship
if it is not already defined.
"""
function expand_model__default_investment_temporal_block()
    add_relationships!(
        model__temporal_block,
        [(model=m, temporal_block=tb) for (m, tb) in model__default_investment_temporal_block()],
    )
    add_relationships!(
        unit__investment_temporal_block,
        [
            (unit=u, temporal_block=tb)
            for u in setdiff(indices(candidate_units), unit__investment_temporal_block(temporal_block=anything))
            for tb in model__default_investment_temporal_block(model=anything)
        ],
    )
    add_relationships!(
        connection__investment_temporal_block,
        [
            (connection=conn, temporal_block=tb)
            for conn in setdiff(indices(candidate_connections), connection__investment_temporal_block(temporal_block=anything))
            for tb in model__default_investment_temporal_block(model=anything)
        ],
    )
    add_relationships!(
        node__investment_temporal_block,
        [
            (node=n, temporal_block=tb)
            for n in setdiff(indices(candidate_storages), node__investment_temporal_block(temporal_block=anything))
            for tb in model__default_investment_temporal_block(model=anything)
        ],
    )
end


"""
    expand_model__default_investment_stochastic_structure()

Process the `model__default_investment_stochastic_structure` relationship.

If a `unit__investment_stochastic_structure` relationship is not defined, then create one using
`model__default_investment_stochastic_structure`. Similarly, add the corresponding `model__stochastic_structure`
relationship if it is not already defined.
"""
function expand_model__default_investment_stochastic_structure()
    add_relationships!(
        model__stochastic_structure,
        [(model=m, stochastic_structure=ss) for (m, ss) in model__default_investment_stochastic_structure()],
    )
    add_relationships!(
        unit__investment_stochastic_structure,
        [
            (unit=u, stochastic_structure=ss)
            for
            u in setdiff(indices(candidate_units), unit__investment_stochastic_structure(stochastic_structure=anything))
            for ss in model__default_investment_stochastic_structure(model=anything)
        ],
    )
    add_relationships!(
        connection__investment_stochastic_structure,
        [
            (connection=conn, stochastic_structure=ss)
            for
            conn in setdiff(indices(candidate_connections), connection__investment_stochastic_structure(stochastic_structure=anything))
            for ss in model__default_investment_stochastic_structure(model=anything)
        ],
    )
    add_relationships!(
        node__investment_stochastic_structure,
        [
            (node=n, stochastic_structure=ss)
            for
            n in setdiff(indices(candidate_storages), node__investment_stochastic_structure(stochastic_structure=anything))
            for ss in model__default_investment_stochastic_structure(model=anything)
        ],
    )
end


"""
    expand_model__default_stochastic_structure()

Expand the `model__default_stochastic_structure` relationship to all `nodes` without `node__stochastic_structure`
and `units_on` without `units_on__stochastic_structure`. Similarly, add the corresponding `model__stochastic_structure`
relationship if it not already defined.
"""
function expand_model__default_stochastic_structure()
    add_relationships!(
        model__stochastic_structure,
        [(model=m, stochastic_structure=ss) for (m, ss) in model__default_stochastic_structure()],
    )
    add_relationships!(
        node__stochastic_structure,
        unique(
            (node=n, stochastic_structure=ss)
            for n in setdiff(node(), node__stochastic_structure(stochastic_structure=anything))
            for ss in model__default_stochastic_structure(model=anything)
        ),
    )
    add_relationships!(
        units_on__stochastic_structure,
        unique(
            (unit=u, stochastic_structure=ss)
            for u in setdiff(unit(), units_on__stochastic_structure(stochastic_structure=anything))
            for ss in model__default_stochastic_structure(model=anything)
        ),
    )
end


"""
    expand_model__default_temporal_block()

Expand the `model__default_temporal_block` relationship to all `nodes` without `node__temporal_block`
and `units_on` without `units_on_temporal_block`.
"""
function expand_model__default_temporal_block()
    add_relationships!(
        model__temporal_block,
        [(model=m, temporal_block=tb) for (m, tb) in model__default_temporal_block()],
    )
    add_relationships!(
        node__temporal_block,
        unique(
            (node=n, temporal_block=tb) for n in setdiff(node(), node__temporal_block(temporal_block=anything))
            for tb in model__default_temporal_block(model=anything)
        ),
    )
    add_relationships!(
        units_on__temporal_block,
        unique(
            (unit=u, temporal_block=tb) for u in setdiff(unit(), units_on__temporal_block(temporal_block=anything))
            for tb in model__default_temporal_block(model=anything)
        ),
    )
end


"""
generate_subproblem_marginals()

Creates the `benders_iteration` object class. Master problem variables have the Benders iteration as an index. A new 
benders iteration object is pushed on each master problem iteration.
"""
function generate_benders_structure()

    # check that units_invested_available exists as an output and add it if not       
    #add_object!(output, Object(Symbol("units_invested_available")))

    current_bi = Object(Symbol(string("bi_1")))
    benders_iteration = ObjectClass(:benders_iteration, [current_bi])
    sp_objective_value_bi = Parameter(:sp_objective_value_bi, [benders_iteration])
    benders_iteration.parameter_values[current_bi] = Dict()
    benders_iteration.parameter_values[current_bi][:sp_objective_value_bi] = parameter_value(0)

    unit__benders_iteration = RelationshipClass(:unit__benders_iteration, [:unit, :benders_iteration], [])   
    units_available_mv = Parameter(:units_available_mv, [unit__benders_iteration])    
    units_invested_available_bi = Parameter(:units_invested_available_bi, [unit__benders_iteration])    
    starting_fix_units_invested_available = Parameter(:starting_fix_units_invested_available, [unit])

    for u in indices(candidate_units)
        unit__benders_iteration.parameter_values[(u, current_bi)] = Dict()
        unit__benders_iteration.parameter_values[(u, current_bi)][:units_invested_available_bi] = parameter_value(0)
        unit__benders_iteration.parameter_values[(u, current_bi)][:units_available_mv] = parameter_value(0)
        if haskey(unit.parameter_values[u], :fix_units_invested_available)
            unit.parameter_values[u][:starting_fix_units_invested_available] =
                unit.parameter_values[u][:fix_units_invested_available]
        end
    end

    connection__benders_iteration = RelationshipClass(:connection__benders_iteration, [:connection, :benders_iteration], [])
    connections_invested_available_mv = Parameter(:connections_invested_available_mv, [connection__benders_iteration])
    connections_invested_available_bi = Parameter(:connections_invested_available_bi, [connection__benders_iteration])
    connections_invested_available_mp = Parameter(:connections_invested_available_mp, [connection])
    starting_fix_connections_invested_available = Parameter(:starting_fix_connections_invested_available, [connection])

    for c in indices(candidate_connections)
        connection__benders_iteration.parameter_values[(c, current_bi)] = Dict()
        connection__benders_iteration.parameter_values[(c, current_bi)][:connections_invested_available_bi] = parameter_value(0)
        connection__benders_iteration.parameter_values[(c, current_bi)][:connections_invested_available_mv] = parameter_value(0)
        connection.parameter_values[c][:connections_invested_available_mp] = parameter_value(0)
        if haskey(connection.parameter_values[c], :fix_connections_invested_available)
            connection.parameter_values[c][:starting_fix_connections_invested_available] =
                connection.parameter_values[c][:fix_connections_invested_available]
        end
    end

    node__benders_iteration = RelationshipClass(:node__benders_iteration, [:node, :benders_iteration], [])
    storages_invested_available_mv = Parameter(:storages_invested_available_mv, [node__benders_iteration])
    storages_invested_available_bi = Parameter(:storages_invested_available_bi, [node__benders_iteration])
    starting_fix_storages_invested_available = Parameter(:starting_fix_storages_invested_available, [node])

    for n in indices(candidate_storages)
        node__benders_iteration.parameter_values[(n, current_bi)] = Dict()
        node__benders_iteration.parameter_values[(n, current_bi)][:storages_invested_available_bi] = parameter_value(0)
        node__benders_iteration.parameter_values[(n, current_bi)][:storages_invested_available_mv] = parameter_value(0)
        if haskey(node.parameter_values[n], :fix_storages_invested_available)
            node.parameter_values[n][:starting_fix_storages_invested_available] =
                node.parameter_values[n][:fix_storages_invested_available]
        end
    end

    @eval begin
        benders_iteration = $benders_iteration
        current_bi = $current_bi
        sp_objective_value_bi = $sp_objective_value_bi
        unit__benders_iteration = $unit__benders_iteration
        units_available_mv = $units_available_mv
        units_invested_available_bi = $units_invested_available_bi
        starting_fix_units_invested_available = $starting_fix_units_invested_available
        connection__benders_iteration = $connection__benders_iteration
        connections_invested_available_mv = $connections_invested_available_mv
        connections_invested_available_bi = $connections_invested_available_bi
        connections_invested_available_mp = $connections_invested_available_mp
        starting_fix_connections_invested_available = $starting_fix_connections_invested_available
        node__benders_iteration = $node__benders_iteration
        storages_invested_available_mv = $storages_invested_available_mv
        storages_invested_available_bi = $storages_invested_available_bi               
        starting_fix_storages_invested_available = $starting_fix_storages_invested_available
        export current_bi
        export benders_iteration
        export sp_objective_value_bi
        export unit__benders_iteration
        export units_available_mv
        export units_invested_available_bi
        export starting_fix_units_invested_available
        export connection__benders_iteration
        export connections_invested_available_mv
        export connections_invested_available_bi
        export connections_invested_available_mp
        export starting_fix_connections_invested_available
        export node__benders_iteration
        export storages_invested_available_mv
        export storages_invested_available_bi
        export starting_fix_storages_invested_available
    end
end
