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

Preprocesses input data structure for SpineOpt.

Runs a number of other functions processing different aspecs of the input data in sequence.
"""
function preprocess_data_structure()
    # NOTE: expand groups first, so we don't need to expand them anywhere else
    expand_node__stochastic_structure()
    expand_units_on_resolution()
    add_connection_relationships()
    generate_network_components()
    generate_direction()
    generate_variable_indexing_support()
    generate_investment_relationships()
end

"""
    generate_investment_relationships()

Generates `Relationships` related to modelling investments.
"""
function generate_investment_relationships()
    generate_unit__investment_temporal_block()
    generate_unit__investment_stochastic_structure()
end
    
    

"""
    generate_unit_investment_temporal_block()

Process the `model__default_investment_temporal_block` relationship.

If a `unit__investment_temporal_block` relationship is not defined, 
then create one using `model__default_investment_temporal_block`
"""
function generate_unit__investment_temporal_block()   
    for u in indices(candidate_units)        
        if isempty(unit__investment_temporal_block(unit=u))         
            m = first(model())
            for tb in model__default_investment_temporal_block(model=m)
                add_relationships!(unit__investment_temporal_block, [(unit=u, temporal_block=tb)])                
            end
        end        
    end
end

"""
    generate_unit__investment_stochastic_structure()

Process the `model__default_investment_stochastic_structure` relationship.

If a `unit__investment_stochastic_structure` relationship is not defined, 
then create one using `model__default_investment_stochastic_structure`
"""
function generate_unit__investment_stochastic_structure()
    for u in indices(candidate_units)        
        if isempty(unit__investment_stochastic_structure(unit=u))         
            m = first(model()) #TODO: Handle multiple models
            for ss in model__default_investment_stochastic_structure(model=m)
                add_relationships!(unit__investment_stochastic_structure, [(unit=u, stochastic_structure=ss)])                
            end
        end        
    end
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
    new_connection__node__node_rels = collect(
        (connection=conn, node1=n1, node2=n2) for (conn, x, y) in conn_from_to for (n1, n2) in ((x, y), (y, x))
    )
    add_relationships!(connection__from_node, new_connection__from_node_rels)
    add_relationships!(connection__to_node, new_connection__to_node_rels)
    add_relationships!(connection__node__node, new_connection__node__node_rels)
    value_one = parameter_value(1.0)
    new_connection__from_node_parameter_values = Dict(
        (conn, n) => Dict(:connection_conv_cap_to_flow => value_one) for (conn, n) in new_connection__from_node_rels
    )
    new_connection__to_node_parameter_values = Dict(
        (conn, n) => Dict(:connection_conv_cap_to_flow => value_one) for (conn, n) in new_connection__to_node_rels
    )
    new_connection__node__node_parameter_values = Dict(
        (conn, n1, n2) => Dict(:fix_ratio_out_in_connection_flow => value_one)
        for (conn, n1, n2) in new_connection__node__node_rels
    )
    merge!(connection__from_node.parameter_values, new_connection__from_node_parameter_values)
    merge!(connection__to_node.parameter_values, new_connection__to_node_parameter_values)
    merge!(connection__node__node.parameter_values, new_connection__node__node_parameter_values)
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
            for c in node__commodity(node=n)
            if commodity_physics(commodity=c) in (:commodity_physics_lodf, :commodity_physics_ptdf)
        )
        node.parameter_values[n][:has_ptdf] = parameter_value(!isempty(ptdf_comms))
        node.parameter_values[n][:node_ptdf_threshold] = parameter_value(
            reduce(max, (commodity_ptdf_threshold(commodity=c) for c in ptdf_comms); init=0.0000001)
        )
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
        is_bidirectional = (
            length(connection__from_node(connection=conn)) == 2
            && Set(connection__from_node(connection=conn)) == Set(connection__to_node(connection=conn))
        )
        is_bidirectional_loseless = (
            is_bidirectional
            && fix_ratio_out_in_connection_flow(;
                connection=conn, zip((:node1, :node2), connection__from_node(connection=conn))..., _strict=false
            ) == 1
        )
        connection.parameter_values[conn][:has_ptdf] = parameter_value(
            is_bidirectional_loseless && all(has_ptdf(node=n) for n in connection__from_node(connection=conn))
        )
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
            for c in commodity(commodity_physics=:commodity_physics_lodf)
            if issubset(connection__from_node(connection=conn), node__commodity(commodity=c))
        )
        connection.parameter_values[conn][:has_lodf] = parameter_value(!isempty(lodf_comms))
        connection.parameter_values[conn][:connnection_lodf_tolerance] = parameter_value(
            reduce(max, (commodity_lodf_tolerance(commodity=c) for c in lodf_comms); init=0.05)
        )
    end
    has_lodf = Parameter(:has_lodf, [connection])
    connnection_lodf_tolerance = Parameter(:connnection_lodf_tolerance, [connection]) # TODO connnection with 3 `n`'s?
    @eval begin
        has_lodf = $has_lodf
        connnection_lodf_tolerance = $connnection_lodf_tolerance
    end
end

"""
    _ptdf_values()

Calculates the values of the `ptdf` parameters?

TODO @JodyDillon: Check this docstring!
"""
function _ptdf_values()
    ps_busses_by_node = Dict(
        n => Bus(
            number=i,
            name=string(n.name),
            bustype=(node_opf_type(node=n) == :node_opf_type_reference) ? BusTypes.REF : BusTypes.PV,
            angle=0.0,
            voltage=0.0,
            voltagelimits=(min=0.0, max=0.0),
            basevoltage=nothing,
            area=nothing,
            load_zone=LoadZone(nothing),
            ext=Dict{String,Any}()
        )
        for (i, n) in enumerate(node(has_ptdf=true))
    )
    isempty(ps_busses_by_node) && return Dict()
    ps_busses = collect(values(ps_busses_by_node))
    PowerSystems.buscheck(ps_busses)
    PowerSystems.slack_bus_check(ps_busses)
    ps_lines_by_connection = Dict(
        conn => Line(;
            name=string(conn.name),
            available=true,
            activepower_flow=0.0,
            reactivepower_flow=0.0,
            arc=Arc((ps_busses_by_node[n] for n in connection__from_node(connection=conn))...),
            r=connection_resistance(connection=conn),
            x=max(connection_reactance(connection=conn), 0.00001),
            b=(from=0.0, to=0.0),
            rate=0.0,
            anglelimits=(min=0.0, max=0.0)
        )  # NOTE: always assume that the flow goes from the first to the second node in `connection__from_node`
        for conn in connection(has_ptdf=true)
    )
    ps_lines = collect(values(ps_lines_by_connection))
    ps_ptdf = PowerSystems.PTDF(ps_lines, ps_busses)
    Dict(
        (conn, n) => Dict(:ptdf => parameter_value(ps_ptdf[line.name, bus.number]))
        for (conn, line) in ps_lines_by_connection
        for (n, bus) in ps_busses_by_node
        if !isapprox(ps_ptdf[line.name, bus.number], 0; atol=node_ptdf_threshold(node=n))
    )
end

"""
    generate_ptdf()

Generates the `ptdf` parameter.
"""
function generate_ptdf()
    ptdf_values = _ptdf_values()
    ptdf_rel_cls = RelationshipClass(
        :ptdf_connection__node,
        [:connection, :node],
        [(connection=conn, node=n) for (conn, n) in keys(ptdf_values)],
        ptdf_values
    )
    ptdf = Parameter(:ptdf, [ptdf_rel_cls])
    @eval begin
        ptdf = $ptdf
    end
end

"""
    generate_lodf()

Generates the `lodf` parameter.
"""
function generate_lodf()

    """
    Given a contingency connection, return a function that given the monitored connection, return the lodf.
    """
    function make_lodf_fn(conn_cont)
        n_from, n_to = connection__from_node(connection=conn_cont)
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
        for (conn_cont, lodf_fn, tolerance) in (
            (conn_cont, make_lodf_fn(conn_cont), connnection_lodf_tolerance(connection=conn_cont))
            for conn_cont in connection(connection_contingency=:value_true, has_lodf=true)
        )
        for (conn_mon, lodf_trial) in (
            (conn_mon, lodf_fn(conn_mon))
            for conn_mon in connection(connection_monitored=:value_true, has_lodf=true)
        )
        if conn_cont !== conn_mon && !isapprox(lodf_trial, 0; atol=tolerance)
    )  # NOTE: in my machine, a Dict comprehension is ~4x faster than a Dict built incrementally
    lodf_rel_cls = RelationshipClass(
        :lodf_connection__connection,
        [:connection1, :connection2],
        [(connection1=conn_cont, connection2=conn_mon) for (conn_cont, conn_mon) in keys(lodf_values)],
        lodf_values
    )
    lodf = Parameter(:lodf, [lodf_rel_cls])
    @eval begin
        lodf = $lodf
    end
end

"""
    generate_network_components()

Generates different network related `parameters`.

Runs a number of other functions dealing with different aspects of the network data in sequence.
"""
function generate_network_components()
    generate_node_has_ptdf()
    generate_connection_has_ptdf()
    generate_connection_has_lodf()
    generate_ptdf()
    generate_lodf()
    # the below needs the parameters write_ptdf_file and write_lodf_file - we can uncomment when we update the template perhaps?
    # write_ptdf_file(model=first(model())) == Symbol(:true) && write_ptdfs()
    # write_lodf_file(model=first(model())) == Symbol(:true) && write_lodfs()
end

"""
    generate_direction()

Generates the `direction` `ObjectClass` and its relationships.
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
        )
    )
    connection__node__direction__temporal_block = RelationshipClass(
        :connection__node__direction__temporal_block, 
        [:connection, :node, :direction, :temporal_block], 
        unique(
            (connection=conn, node=n, direction=d, temporal_block=tb)
            for (conn, n, d) in Iterators.flatten((connection__from_node(), connection__to_node()))
            for tb in node__temporal_block(node=n)
        )
    )
    node_with_state__temporal_block = RelationshipClass(
        :node_with_state__temporal_block, 
        [:node, :temporal_block], 
        unique((node=n, temporal_block=tb) for n in node(has_state=:value_true) for tb in node__temporal_block(node=n))
    )
    unit__temporal_block = RelationshipClass(
        :unit__temporal_block, 
        [:unit, :temporal_block], 
        unique(
            (unit=u, temporal_block=tb)
            for (u, n) in units_on_resolution()
            for tb in node__temporal_block(node=n)
        )
    )
    units_invested_available_indices = unique(
        (unit=u, temporal_block=tb)
        for ug in indices(candidate_units)
        for u in expand_unit_group(ug)            
        for tb in unit__investment_temporal_block(unit=u)                    
    )
    units_invested_available_indices_rc = RelationshipClass(
        :units_invested_available_indices_rc, [:unit, :temporal_block], units_invested_available_indices
    nonspin_ramp_up_unit_flow_indices = unique(
        (unit=u, node=n, direction=d,temporal_block=tb)
        for (u,ng,d) in indices(max_res_startup_ramp)
        for n in expand_node_group(ng)
        for tb in node__temporal_block(node=n)
    )
    )
    nonspin_ramp_up_unit_flow_indices_rc = RelationshipClass(
        :nonspin_ramp_up_unit_flow_indices_rc, [:unit, :node, :direction, :temporal_block], nonspin_ramp_up_unit_flow_indices
    )
    @eval begin
        node_with_slack_penalty = $node_with_slack_penalty
        unit__node__direction__temporal_block = $unit__node__direction__temporal_block
        connection__node__direction__temporal_block = $connection__node__direction__temporal_block
        node_with_state__temporal_block = $node_with_state__temporal_block
        unit__temporal_block = $unit__temporal_block
        units_invested_available_indices_rc = $units_invested_available_indices_rc
        nonspin_ramp_up_unit_flow_indices_rc = $nonspin_ramp_up_unit_flow_indices_rc
    end
end


"""
    expand_node__stochastic_structure()

Expands the `node__stochastic_structure` `RelationshipClass` for with individual `nodes` in `node_groups`.
"""
function expand_node__stochastic_structure()
    for (node, stochastic_structure) in node__stochastic_structure()
        expanded_node = expand_node_group(node)
        if collect(node) != collect(expanded_node)
            add_relationships!(
                node__stochastic_structure,
                [(node=n, stochastic_structure=stochastic_structure) for n in expanded_node]
            )
        end
    end
end


"""
    expand_units_on_resolution()

Expands `units_on_resolution` `RelationshipClass` with all individual `units` in `unit_groups`.
"""
function expand_units_on_resolution()
    for (unit, node) in units_on_resolution()
        expanded_unit = expand_unit_group(unit)
        if collect(unit) != collect(expanded_unit)
            add_relationships!(
                units_on_resolution,
                [(unit=u, node=node) for u in expanded_unit]
            )
        end
    end
end
