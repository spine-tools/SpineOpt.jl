#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
    generate_is_candidate()
    expand_model_default_relationships()
    expand_node__stochastic_structure()
    expand_units_on__stochastic_structure()
    generate_report()
    generate_report__output()
    generate_model__report()
    add_required_outputs()
    process_lossless_bidirectional_connections()
    # NOTE: generate direction before doing anything that calls `connection__from_node` or `connection__to_node`,
    # so we don't corrupt the lookup cache
    generate_direction()
    generate_ptdf_lodf()
    generate_variable_indexing_support()
    generate_internal_fix_investments()
    generate_benders_structure()
    apply_forced_availability_factor()
    generate_is_boundary()
end

"""
    generate_is_candidate()

Generate `is_candidate` for the `node`, `unit` and `connection` `ObjectClass`es.
"""
function generate_is_candidate()
    is_candidate = Parameter(:is_candidate, [node, unit, connection])
    add_object_parameter_values!(
        connection, Dict(x => Dict(:is_candidate => parameter_value(true)) for x in indices(candidate_connections))
    )
    add_object_parameter_values!(
        unit, Dict(x => Dict(:is_candidate => parameter_value(true)) for x in indices(candidate_units))
    )
    add_object_parameter_values!(
        node, Dict(x => Dict(:is_candidate => parameter_value(true)) for x in indices(candidate_storages))
    )
    add_object_parameter_defaults!(connection, Dict(:is_candidate => parameter_value(false)))
    add_object_parameter_defaults!(unit, Dict(:is_candidate => parameter_value(false)))
    add_object_parameter_defaults!(node, Dict(:is_candidate => parameter_value(false)))
    @eval begin
        is_candidate = $is_candidate
    end
end

"""
    expand_node__stochastic_structure()

Expand the `node__stochastic_structure` `RelationshipClass` for with individual `nodes` in `node_groups`.
"""
function expand_node__stochastic_structure()
    add_relationships!(
        node__stochastic_structure,
        [
            (n, stochastic_structure)
            for (ng, stochastic_structure) in node__stochastic_structure()
            for n in members(ng)
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
            (u, stochastic_structure)
            for (ug, stochastic_structure) in units_on__stochastic_structure()
            for u in members(ug)
        ],
    )
end

"""
    process_lossless_bidirectional_connections()

Add connection relationships for connection_type=:connection_type_lossless_bidirectional.

For connections with this parameter set, only a connection__from_node and connection__to_node need be set
and this function creates the additional relationships on the fly.
"""
function process_lossless_bidirectional_connections()
    function _connection_pvals(conn, conn_cap_pvals, conn_emergency_cap_values)
        pvals = Dict{Symbol,Any}(:connection_conv_cap_to_flow => parameter_value(1.0))
        conn_cap = get(conn_cap_pvals, conn, nothing)
        conn_emergency_cap = get(conn_emergency_cap_values, conn, nothing)
        conn_cap !== nothing && (pvals[:connection_capacity] = parameter_value(conn_cap))
        conn_emergency_cap !== nothing && (pvals[:connection_emergency_capacity] = parameter_value(conn_emergency_cap))
        pvals
    end

    conn_from = (
        (conn, first(connection__from_node(connection=conn)))
        for conn in connection(connection_type=:connection_type_lossless_bidirectional)
    )
    conn_from_to = [
        (conn, from, first(x for x in connection__to_node(connection=conn) if x != from)) for (conn, from) in conn_from
    ]
    isempty(conn_from_to) && return
    # New rels
    new_connection__from_node_rels = [(conn, n) for (conn, x, y) in conn_from_to for n in (x, y)]
    new_connection__to_node_rels = [(conn, n) for (conn, x, y) in conn_from_to for n in (x, y)]
    new_connection__node__node_rels = collect(
        (conn, n1, n2) for (conn, x, y) in conn_from_to for (n1, n2) in ((x, y), (y, x))
    )
    # New pvals
    conn_caps = (
        (conn, connection_capacity(connection=conn, node=n, _strict=false, _raw=true))
        for (conn, n) in Iterators.flatten((new_connection__from_node_rels, new_connection__to_node_rels))
    )
    conn_emergency_caps = (
        (conn, connection_emergency_capacity(connection=conn, node=n, _strict=false, _raw=true))
        for (conn, n) in Iterators.flatten((new_connection__from_node_rels, new_connection__to_node_rels))
    )
    conn_cap_pvals = Dict(conn => val for (conn, val) in conn_caps if val !== nothing)
    conn_emergency_cap_values = Dict(conn => val for (conn, val) in conn_emergency_caps if val !== nothing)
    new_connection__from_node_parameter_values = Dict(
        (conn, n) => _connection_pvals(conn, conn_cap_pvals, conn_emergency_cap_values)
        for (conn, n) in new_connection__from_node_rels
    )
    new_connection__to_node_parameter_values = Dict(
        (conn, n) => _connection_pvals(conn, conn_cap_pvals, conn_emergency_cap_values)
        for (conn, n) in new_connection__to_node_rels
    )
    new_connection__node__node_parameter_values = Dict(
        (conn, n1, n2) => Dict(:fix_ratio_out_in_connection_flow => parameter_value(1.0))
        for (conn, n1, n2) in new_connection__node__node_rels
    )
    add_relationship_parameter_values!(connection__from_node, new_connection__from_node_parameter_values)
    add_relationship_parameter_values!(connection__to_node, new_connection__to_node_parameter_values)
    add_relationship_parameter_values!(connection__node__node, new_connection__node__node_parameter_values)
end

"""
    generate_direction()

Generate the `direction` `ObjectClass` and its relationships.
"""
function generate_direction()
    from_node = Object(:from_node, :direction)
    to_node = Object(:to_node, :direction)
    direction = ObjectClass(:direction, [from_node, to_node])
    directions_by_class = Dict(
        unit__from_node => from_node,
        unit__to_node => to_node,
        connection__from_node => from_node,
        connection__to_node => to_node,
        unit__from_node__user_constraint => from_node,
        unit__to_node__user_constraint => to_node,        
        connection__from_node__user_constraint => from_node,
        connection__to_node__user_constraint => to_node,        
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
    generate_node_has_ptdf()

Generate `has_ptdf`, `ptdf_duration` and `node_ptdf_threshold` parameters associated to the `node` `ObjectClass`.
"""
function generate_node_has_ptdf()
    function _new_node_pvals(n)
        ptdf_comms = Tuple(
            c
            for c in node__commodity(node=n)
            if commodity_physics(commodity=c) in (:commodity_physics_lodf, :commodity_physics_ptdf)
        )
        ptdf_durations = [commodity_physics_duration(commodity=c, _default=nothing) for c in ptdf_comms]
        filter!(!isnothing, ptdf_durations)
        ptdf_duration = isempty(ptdf_durations) ? nothing : minimum(ptdf_durations)
        ptdf_threshold = maximum(commodity_ptdf_threshold(commodity=c) for c in ptdf_comms; init=0.001)
        Dict(
            :has_ptdf => parameter_value(!isempty(ptdf_comms)),
            :ptdf_duration => parameter_value(ptdf_duration),
            :node_ptdf_threshold => parameter_value(ptdf_threshold),
        )
    end

    add_object_parameter_values!(node, Dict(n => _new_node_pvals(n) for n in node()))
    has_ptdf = Parameter(:has_ptdf, [node])
    ptdf_duration = Parameter(:ptdf_duration, [node])
    node_ptdf_threshold = Parameter(:node_ptdf_threshold, [node])
    @eval begin
        has_ptdf = $has_ptdf
        ptdf_duration = $ptdf_duration
        node_ptdf_threshold = $node_ptdf_threshold
    end
end

"""
    generate_connection_has_ptdf()

Generate `has_ptdf` and `ptdf_duration` parameter associated to the `connection` `ObjectClass`.
"""
function generate_connection_has_ptdf()
    function _new_connection_pvals(conn)
        from_nodes = connection__from_node(connection=conn, direction=anything)
        to_nodes = connection__to_node(connection=conn, direction=anything)
        is_bidirectional = length(from_nodes) == 2 && isempty(symdiff(from_nodes, to_nodes))
        is_loseless = length(from_nodes) == 2 && fix_ratio_out_in_connection_flow(;
            connection=conn, zip((:node1, :node2), from_nodes)..., _strict=false
        ) == 1
        has_ptdf_ = is_bidirectional && is_loseless && all(has_ptdf(node=n) for n in from_nodes)
        ptdf_durations = [ptdf_duration(node=n, _default=nothing) for n in from_nodes]
        filter!(!isnothing, ptdf_durations)
        ptdf_duration_ = isempty(ptdf_durations) ? nothing : minimum(ptdf_durations)
        Dict(:has_ptdf => parameter_value(has_ptdf_), :ptdf_duration => parameter_value(ptdf_duration_))
    end

    add_object_parameter_values!(connection, Dict(conn => _new_connection_pvals(conn) for conn in connection()))
    push!(has_ptdf.classes, connection)
    push!(ptdf_duration.classes, connection)
end

"""
    generate_connection_has_lodf()

Generate `has_lodf` and `connnection_lodf_tolerance` parameters associated to the `connection` `ObjectClass`.
"""
function generate_connection_has_lodf()
    function _new_connection_pvals(conn)
        lodf_comms = Tuple(
            c
            for c in commodity(commodity_physics=:commodity_physics_lodf)
            if issubset(connection__from_node(connection=conn, direction=anything), node__commodity(commodity=c))
        )
        Dict(
            :has_lodf => parameter_value(!isempty(lodf_comms)),
            :connnection_lodf_tolerance => parameter_value(
                reduce(max, (commodity_lodf_tolerance(commodity=c) for c in lodf_comms); init=0.05),
            )
        )
    end

    add_object_parameter_values!(
        connection, Dict(conn => _new_connection_pvals(conn) for conn in connection(has_ptdf=true))
    )
    has_lodf = Parameter(:has_lodf, [connection])
    connnection_lodf_tolerance = Parameter(:connnection_lodf_tolerance, [connection])  # TODO connnection with 3 `n`'s?
    @eval begin
        has_lodf = $has_lodf
        connnection_lodf_tolerance = $connnection_lodf_tolerance
    end
end

function _build_ptdf(connections, nodes, unavailable_connections=Set())
    nodecount = length(nodes)
    conncount = length(connections)
    node_numbers = Dict{Object,Int32}(n => ix for (ix, n) in enumerate(nodes))
    A = zeros(Float64, nodecount, conncount)  # incidence_matrix
    inv_X = zeros(Float64, conncount, conncount)
    for (ix, conn) in enumerate(connections)
        # NOTE: always assume that the flow goes from the first to the second node in `connection__from_node`
        n_from, n_to = connection__from_node(connection=conn, direction=anything)
        A[node_numbers[n_from], ix] = 1
        A[node_numbers[n_to], ix] = -1
        reactance = max(connection_reactance(connection=conn, _default=0), 1e-6)
        if conn in unavailable_connections
            reactance *= 1e3
        end
        inv_X[ix, ix] = connection_reactance_base(connection=conn) / reactance
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
        error("illegal argument in inputs")
    elseif binfo > 0
        error("singular value in factorization, possibly there is an islanded bus")
    end
    S_ = gemm('N', 'N', gemm('N', 'T', inv_X, A[setdiff(1:end, slack_position), :]), getri!(B, bipiv))
    hcat(S_[:, 1:(slack_position - 1)], zeros(conncount), S_[:, slack_position:end])
end

"""
    _ptdf_unfiltered_values()

Calculate the raw values of the `ptdf_unfiltered` parameter (will contain very small values).
"""
function _ptdf_unfiltered_values()
    nodes = node(has_ptdf=true)
    isempty(nodes) && return Dict()
    connections = connection(has_ptdf=true)
    unavailable_connections_by_ind = Dict{Any,Set}(:nothing => Set())
    for conn in connections
        for (ind, val) in indexed_values(connection_availability_factor(connection=conn))
            if iszero(val)
                push!(get!(unavailable_connections_by_ind, ind, Set()), conn)
            end
        end
    end
    ptdf_by_ind = Dict(
        ind => _build_ptdf(connections, nodes, unavailable_connections)
        for (ind, unavailable_connections) in unavailable_connections_by_ind
    )
    Dict(
        (conn, n) => Dict(
            :ptdf_unfiltered => parameter_value(
                collect_indexed_values(
                    Dict(
                        ind => get(ptdf_by_ind, ind, ptdf_by_ind[:nothing])[i, j]
                        for (ind, val) in indexed_values(connection_availability_factor(connection=conn))
                    )
                )
            )
        )
        for (i, conn) in enumerate(connections)
        for (j, n) in enumerate(nodes)
    )
end

"""
    _filter_ptdf_values(ptdf_values)

Filter the values of the `ptdf` parameter including only those with an absolute value
greater than commodity_ptdf_threshold.
"""
function _filter_ptdf_values(ptdf_values)
    comms = filter(
        c -> commodity_physics(commodity=c) in (:commodity_physics_lodf, :commodity_physics_ptdf), commodity()
    )
    ptdf_threshold = if !isempty(comms)
        c = first(comms)
        threshold = commodity_ptdf_threshold(commodity=c, _strict=false)
        if threshold !== nothing && !iszero(threshold)
            threshold
        else
            1e-3
        end
    else
        1e-3
    end
    Dict(
        (conn, n) => Dict(:ptdf => vals[:ptdf_unfiltered])
        for ((conn, n), vals) in ptdf_values
        if !isapprox(vals[:ptdf_unfiltered](), 0; atol=ptdf_threshold)
    )
end

"""
    generate_ptdf()

Generate the `ptdf` parameter.
"""
function generate_ptdf()
    ptdf_unfiltered_values = _ptdf_unfiltered_values()    
    ptdf_values = _filter_ptdf_values(ptdf_unfiltered_values)
    ptdf_connection__node = RelationshipClass(
        :ptdf_connection__node, [:connection, :node], keys(ptdf_values), ptdf_values
    )
    ptdf_unfiltered_connection__node = RelationshipClass(
        :ptdf_unfiltered_connection__node, [:connection, :node], keys(ptdf_unfiltered_values), ptdf_unfiltered_values
    )
    ptdf = Parameter(:ptdf, [ptdf_connection__node])
    ptdf_unfiltered = Parameter(:ptdf_unfiltered, [ptdf_unfiltered_connection__node])
    @eval begin
        ptdf_connection__node = $ptdf_connection__node
        ptdf_unfiltered_connection__node = $ptdf_unfiltered_connection__node
        ptdf = $ptdf
        ptdf_unfiltered = $ptdf_unfiltered
        export ptdf
        export ptdf_unfiltered
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
    function _lodf_fn(conn_cont)
        n_from, n_to = connection__from_node(connection=conn_cont, direction=anything)
        denom = 1 - (
            ptdf_unfiltered(connection=conn_cont, node=n_from) - ptdf_unfiltered(connection=conn_cont, node=n_to)
        )
        is_tail = isapprox(denom, 0; atol=0.001)
        if is_tail
            conn_mon -> nothing
        else
            conn_mon -> (
                ptdf_unfiltered(connection=conn_mon, node=n_from) - ptdf_unfiltered(connection=conn_mon, node=n_to)
            ) / denom
        end
    end

    lodf_values = Dict(
        (conn_cont, conn_mon) => Dict(:lodf => parameter_value(lodf_trial))
        for (conn_cont, lodf_fn, tolerance) in (
            (conn_cont, _lodf_fn(conn_cont), connnection_lodf_tolerance(connection=conn_cont))
            for conn_cont in connection(has_ptdf=true)
        )
        for (conn_mon, lodf_trial) in ((conn_mon, lodf_fn(conn_mon)) for conn_mon in connection(has_ptdf=true))
        if conn_cont !== conn_mon && lodf_trial !== nothing && !isapprox(lodf_trial, 0; atol=tolerance)
    )
    lodf_connection__connection = RelationshipClass(
        :lodf_connection__connection, [:connection, :connection], keys(lodf_values), lodf_values
    )
    lodf = Parameter(:lodf, [lodf_connection__connection])
    @eval begin
        lodf = $lodf
        lodf_connection__connection = $lodf_connection__connection
    end
end

"""
    generate_ptdf_lodf()

Generate ptdf and lodf parameters-
"""
function generate_ptdf_lodf()
    generate_node_has_ptdf()
    generate_connection_has_ptdf()
    generate_connection_has_lodf()
    generate_ptdf()
    generate_lodf()
    # the below needs the parameters write_ptdf_file and write_lodf_file - we can uncomment when we update the template perhaps?
    # write_ptdf_file(model=first(model(model_type=:spineopt_standard))) == Symbol(:true) && write_ptdfs()
    # write_lodf_file(model=first(model(model_type=:spineopt_standard))) == Symbol(:true) && write_lodfs()
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
            (u, n, d, tb)
            for (u, n, d) in Iterators.flatten((unit__from_node(), unit__to_node()))
            for tb in node__temporal_block(node=n)
        ),
    )
    connection__node__direction__temporal_block = RelationshipClass(
        :connection__node__direction__temporal_block,
        [:connection, :node, :direction, :temporal_block],
        unique(
            (conn, n, d, tb)
            for (conn, n, d) in Iterators.flatten((connection__from_node(), connection__to_node()))
            for tb in node__temporal_block(node=n)
        ),
    )
    node_with_state__temporal_block = RelationshipClass(
        :node_with_state__temporal_block,
        [:node, :temporal_block],
        unique((node=n, temporal_block=tb)
        for n in node(has_state=true) for tb in node__temporal_block(node=n)),
    )
    @eval begin
        node_with_slack_penalty = $node_with_slack_penalty
        unit__node__direction__temporal_block = $unit__node__direction__temporal_block
        connection__node__direction__temporal_block = $connection__node__direction__temporal_block
        node_with_state__temporal_block = $node_with_state__temporal_block
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
`model__default_investment_temporal_block`.
"""
function expand_model__default_investment_temporal_block()
    add_relationships!(
        unit__investment_temporal_block,
        [
            (u, tb)
            for u in setdiff(indices(candidate_units), unit__investment_temporal_block(temporal_block=anything))
            for tb in model__default_investment_temporal_block(model=anything)
        ],
    )
    add_relationships!(
        connection__investment_temporal_block,
        [
            (conn, tb)
            for conn in setdiff(
                indices(candidate_connections), connection__investment_temporal_block(temporal_block=anything)
            )
            for tb in model__default_investment_temporal_block(model=anything)
        ],
    )
    add_relationships!(
        node__investment_temporal_block,
        [
            (n, tb)
            for n in setdiff(indices(candidate_storages), node__investment_temporal_block(temporal_block=anything))
            for tb in model__default_investment_temporal_block(model=anything)
        ],
    )
end

"""
    expand_model__default_investment_stochastic_structure()

Process the `model__default_investment_stochastic_structure` relationship.

If a `unit__investment_stochastic_structure` relationship is not defined, then create one using
`model__default_investment_stochastic_structure`.
"""
function expand_model__default_investment_stochastic_structure()
    add_relationships!(
        unit__investment_stochastic_structure,
        [
            (u, ss)
            for u in setdiff(
                indices(candidate_units), unit__investment_stochastic_structure(stochastic_structure=anything)
            )
            for ss in model__default_investment_stochastic_structure(model=anything)
        ],
    )
    add_relationships!(
        connection__investment_stochastic_structure,
        [
            (conn, ss)
            for conn in setdiff(
                indices(candidate_connections),
                connection__investment_stochastic_structure(stochastic_structure=anything)
            )
            for ss in model__default_investment_stochastic_structure(model=anything)
        ],
    )
    add_relationships!(
        node__investment_stochastic_structure,
        [
            (n, ss)
            for n in setdiff(
                indices(candidate_storages), node__investment_stochastic_structure(stochastic_structure=anything)
            )
            for ss in model__default_investment_stochastic_structure(model=anything)
        ],
    )
end

"""
    expand_model__default_stochastic_structure()

Expand the `model__default_stochastic_structure` relationship to all `nodes` without `node__stochastic_structure`
and `units_on` without `units_on__stochastic_structure`.
"""
function expand_model__default_stochastic_structure()
    add_relationships!(
        node__stochastic_structure,
        unique(
            (n, ss)
            for n in setdiff(node(), node__stochastic_structure(stochastic_structure=anything))
            for ss in model__default_stochastic_structure(model=anything)
        ),
    )
    add_relationships!(
        units_on__stochastic_structure,
        unique(
            (u, ss)
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
        node__temporal_block,
        unique(
            (n, tb)
            for n in setdiff(node(), node__temporal_block(temporal_block=anything))
            for tb in model__default_temporal_block(model=anything)
        ),
    )
    add_relationships!(
        units_on__temporal_block,
        unique(
            (u, tb)
            for u in setdiff(unit(), units_on__temporal_block(temporal_block=anything))
            for tb in model__default_temporal_block(model=anything)
        ),
    )
end

"""
    generate_report__output()

Generate the `report__output` relationship for all possible combinations of outputs and reports, only if no
relationship between report and output exists.
"""
function generate_report__output()
    isempty(report__output()) || return
    add_relationships!(report__output, [(r, out) for r in report() for out in output()])
end

"""
    generate_model__report()

Generate the `report__output` relationship for all possible combinations of outputs and reports, only if no
relationship between report and output exists.
"""
function generate_model__report()
    isempty(model__report()) || return
    add_relationships!(model__report, [(m, r) for m in model() for r in report()])
end

"""
    generate_report()

Generate a default `report` object, only if no report objects exist.
"""
function generate_report()
    isempty(report()) || return
    add_objects!(report, [Object(:default_report, :report)])
end

"""
    add_required_outputs()

Add outputs that are required for calculating other outputs.
"""
function add_required_outputs()
    required_output_names = Dict(
        :connection_avg_throughflow => :connection_flow,
        :connection_avg_intact_throughflow => :connection_intact_flow,
    )
    for r in report()
        new_output_names = (get(required_output_names, out.name, nothing) for out in report__output(report=r))
        new_output_names = [n for n in new_output_names if n !== nothing]
        isempty(new_output_names) && continue
        add_objects!(output, [Object(n, :output) for n in new_output_names])
        add_relationships!(report__output, [(r, output(n)) for n in new_output_names])
    end
end

"""
    generate_benders_structure()

Creates the `benders_iteration` object class. Benders cuts have the Benders iteration as an index. A new
benders iteration object is pushed on each master problem iteration.
"""
function generate_benders_structure()
    bi_name = :benders_iteration
    current_bi = Object(:bi_1, bi_name)
    benders_iteration = ObjectClass(
        bi_name, [current_bi], Dict(current_bi => Dict(:sp_objective_value_bi => parameter_value(0)))
    )
    sp_objective_value_bi = Parameter(:sp_objective_value_bi, [benders_iteration])
    units_invested_available_mv = Parameter(:units_invested_available_mv, [unit])
    connections_invested_available_mv = Parameter(:connections_invested_available_mv, [connection])
    storages_invested_available_mv = Parameter(:storages_invested_available_mv, [node])
    sp_unit_flow = Parameter(:sp_unit_flow, [unit__to_node, unit__from_node])
    @eval begin
        benders_iteration = $benders_iteration
        current_bi = $current_bi
        sp_objective_value_bi = $sp_objective_value_bi
        units_invested_available_mv = $units_invested_available_mv
        connections_invested_available_mv = $connections_invested_available_mv
        storages_invested_available_mv = $storages_invested_available_mv
        sp_unit_flow = $sp_unit_flow
        export benders_iteration
        export current_bi
        export sp_objective_value_bi
        export units_invested_available_mv
        export connections_invested_available_mv
        export storages_invested_available_mv
        export sp_unit_flow
    end
end

"""
    generate_internal_fix_investments()

Creates parameters to be used as `internal_fix_value` for investment variables.
The value is set to zero for one hour before the model starts, so the model doesn't create free investments
during the history.

The benders algorithm also uses these parameters to fix the subproblem investment variables to the master problem
solution.
"""
function generate_internal_fix_investments()
    models = model()
    isempty(models) && return
    starts = [model_start(model=m) for m in models]
    instance = models[argmin(starts)]
    t = model_start(model=instance)
    dur_unit = _model_duration_unit(instance)
    scens = stochastic_scenario()
    for (pname, class, candidates) in (
            (:internal_fix_units_invested_available, unit, candidate_units),
            (:internal_fix_connections_invested_available, connection, candidate_connections),
            (:internal_fix_storages_invested_available, node, candidate_storages),
        )
        parameter = Parameter(pname, [class])
        pvals = Dict(
            obj => Dict(
                pname => parameter_value(Map(scens, [TimeSeries([t - dur_unit(1), t], [0.0, NaN]) for _s in scens]))
            )
            for obj in indices(candidates)
        )
        add_object_parameter_values!(class, pvals)
        @eval $pname = $parameter
    end
end

function apply_forced_availability_factor()
    function _apply_forced_availability_factor(m_start, m_end, class, availability_factor)
        _product_or_nothing(x::TimeSeries, y::Nothing) = x
        _product_or_nothing(x::TimeSeries, y) = x * y

        function _new_pvals(class, x)
            forced_af = forced_availability_factor(; (class.name => x,)..., _strict=false)
            forced_af === nothing && return Dict()
            af = availability_factor(; (class.name => x,)..., _strict=false)
            Dict(availability_factor.name => parameter_value(_product_or_nothing(forced_af, af)))
        end

        add_object_parameter_values!(class, Dict(x => _new_pvals(class, x) for x in class()))
    end

    isempty(model()) && return
    m_start = minimum(model_start(model=m) for m in model())
    m_end = maximum(model_end(model=m) for m in model())
    _apply_forced_availability_factor(m_start, m_end, unit, unit_availability_factor)
    _apply_forced_availability_factor(m_start, m_end, connection, connection_availability_factor)
end

"""
    generate_is_boundary()

Generate `is_boundary_node` and `is_boundary_connection` parameters
associated with the `node` and `connection` `ObjectClass`es respectively.
"""
function generate_is_boundary()
    is_boundary_node = Parameter(:is_boundary_node, [node])
    is_boundary_connection = Parameter(:is_boundary_connection, [connection])
    add_object_parameter_defaults!(node, Dict(:is_boundary_node => parameter_value(false)))
    add_object_parameter_defaults!(connection, Dict(:is_boundary_connection => parameter_value(false)))
    for (n, c) in node__commodity()
        commodity_physics(commodity=c) in (:commodity_physics_lodf, :commodity_physics_ptdf) || continue
        has_boundary_conn = false
        for (conn, _d) in connection__from_node(node=n)
            remote_commodities = unique(
                c 
                for (remote_n, _d) in connection__to_node(connection=conn)
                if remote_n != n
                for c in node__commodity(node=remote_n)
            )
            if !(c in remote_commodities)
                has_boundary_conn = true
                add_object_parameter_values!(
                    connection, Dict(conn => Dict(:is_boundary_connection => parameter_value(true)))
                )
            end
        end
        if has_boundary_conn
            add_object_parameter_values!(node, Dict(n => Dict(:is_boundary_node => parameter_value(true))))
        end
    end
    @eval begin
        is_boundary_node = $is_boundary_node
        is_boundary_connection = $is_boundary_connection
        export is_boundary_node
        export is_boundary_connection
    end
end
