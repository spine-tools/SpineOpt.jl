#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

function generate_special_handlers()
    generate_direction()
    generate_unit__node__direction()
    generate_connection__node__direction()
    generate_variable_indices()
end


function generate_direction()
    from_node = Object(:from_node, 1)
    to_node = Object(:to_node, 2)
    direction = ObjectClass(:direction, [from_node, to_node], Dict())
    @eval begin
        direction = $direction
        export direction
    end
end

function generate_unit__node__direction()
    from_node = direction(:from_node)
    to_node = direction(:to_node)
    relationships = [(unit=u, node=n, direction=from_node) for (u, n) in unit__from_node.relationships]
    append!(relationships, [(unit=u, node=n, direction=to_node) for (u, n) in unit__to_node.relationships])
    parameter_values = Dict((u, n, from_node) => val for ((u, n), val) in unit__from_node.parameter_values)
    merge!(parameter_values, Dict((u, n, to_node) => val for ((u, n), val) in unit__to_node.parameter_values))
    unit__node__direction = RelationshipClass(
        :unit__node__direction, (:unit, :node, :direction), relationships, parameter_values
    )
    @eval begin
        unit__node__direction = $unit__node__direction
        export unit__node__direction
    end
    parameter_names = Set(keys(first(values(unit__from_node.parameter_values))))
    union!(parameter_names, keys(first(values(unit__to_node.parameter_values))))
    for parameter_name in parameter_names
        parameter = getfield(SpineModel, parameter_name)
        filter!(class -> !(class in (unit__from_node, unit__to_node)), parameter.classes)
        push!(parameter.classes, unit__node__direction)
    end
end 

function generate_connection__node__direction()
    from_node = direction(:from_node)
    to_node = direction(:to_node)
    relationships = [(connection=conn, node=n, direction=from_node) for (conn, n) in connection__from_node.relationships]
    append!(relationships, [(connection=conn, node=n, direction=to_node) for (conn, n) in connection__to_node.relationships])
    parameter_values = Dict((conn, n, from_node) => val for ((conn, n), val) in connection__from_node.parameter_values)
    merge!(parameter_values, Dict((conn, n, to_node) => val for ((conn, n), val) in connection__to_node.parameter_values))
    connection__node__direction = RelationshipClass(
        :connection__node__direction, (:connection, :node, :direction), relationships, parameter_values
    )
    @eval begin
        connection__node__direction = $connection__node__direction
        export connection__node__direction
    end
    parameter_names = Set(keys(first(values(connection__from_node.parameter_values))))
    union!(parameter_names, keys(first(values(connection__to_node.parameter_values))))
    for parameter_name in parameter_names
        parameter = getfield(SpineModel, parameter_name)
        filter!(class -> !(class in (connection__from_node, connection__to_node)), parameter.classes)
        push!(parameter.classes, connection__node__direction)
    end
end


function generate_variable_indices()
    unit_flow_indices = unique(
        (unit=u, node=n, direction=d, temporal_block=tb)
        for (u, n, d) in unit__node__direction()
        for tb in node__temporal_block(node=n)
    )
    connection_flow_indices = unique(
        (connection=conn, node=n, direction=d, temporal_block=tb)
        for (conn, n, d) in connection__node__direction()
        for tb in node__temporal_block(node=n)
    )
    node_state_indices = unique(
        (node=n, temporal_block=tb)
        for n in node(has_state=Symbol("true"))
        for tb in node__temporal_block(node=n)
    )
    unit_flow_indices_rc = RelationshipClass(
        :unit_flow_indices_rc, (:unit, :node, :direction, :temporal_block), unit_flow_indices
    )
    connection_flow_indices_rc = RelationshipClass(
        :connection_flow_indices_rc, (:connection, :node, :direction, :temporal_block), connection_flow_indices
    )
    node_state_indices_rc = RelationshipClass(
        :node_state_indices_rc, (:node, :temporal_block), node_state_indices
    )
    @eval begin
        unit_flow_indices_rc = $unit_flow_indices_rc
        connection_flow_indices_rc = $connection_flow_indices_rc
        node_state_indices_rc = $node_state_indices_rc
    end
end