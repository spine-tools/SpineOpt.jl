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

function preprocess_data_structure()
    generate_direction()
#   generate_array_indices()
    generate_variable_indices()
end

function generate_array_indices()
    array_indices=[]
    for i in 1:100
        push!(array_indices,Object(Symbol(i), 100000000+i))
    end
    array_index = ObjectClass(:array_index, array_indices, Dict())
    @eval begin
        array_index = $array_index
        export array_index
    end
end

function generate_direction()

    from_node = Object(:from_node, 1)
    to_node = Object(:to_node, 2)

    direction = ObjectClass(:direction, [from_node, to_node], Dict())
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

function generate_variable_indices()
    unit_flow_indices = unique(
        (unit=u, node=n, direction=d, temporal_block=tb)
        for (u, n, d) in Iterators.flatten((unit__from_node(), unit__to_node()))
        for tb in node__temporal_block(node=n)
    )
    connection_flow_indices = unique(
        (connection=conn, node=n, direction=d, temporal_block=tb)
        for (conn, n, d) in Iterators.flatten((connection__from_node(), connection__to_node()))
        for tb in node__temporal_block(node=n)
    )
    node_state_indices = unique(
        (node=n, temporal_block=tb)
        for n in node(has_state=:node_has_state_true)
        for tb in node__temporal_block(node=n)
    )
    unit_flow_indices_rc = RelationshipClass(
        :unit_flow_indices_rc, [:unit, :node, :direction, :temporal_block], unit_flow_indices
    )
    connection_flow_indices_rc = RelationshipClass(
        :connection_flow_indices_rc, [:connection, :node, :direction, :temporal_block], connection_flow_indices
    )
    node_state_indices_rc = RelationshipClass(
        :node_state_indices_rc, [:node, :temporal_block], node_state_indices
    )
    @eval begin
        unit_flow_indices_rc = $unit_flow_indices_rc
        connection_flow_indices_rc = $connection_flow_indices_rc
        node_state_indices_rc = $node_state_indices_rc
    end
end
