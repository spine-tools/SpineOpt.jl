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

function generate_variable_indices()
    flow_indices = unique(
        (unit=u, node=n, direction=d, temporal_block=tb)
        for (u, n, d) in unit__node__direction()
        for tb in node__temporal_block(node=n)
    )
    trans_indices = unique(
        (connection=conn, node=n, direction=d, temporal_block=tb)
        for (conn, n, d) in connection__node__direction()
        for tb in node__temporal_block(node=n)
    )
    node_state_indices = unique(
        (node=n, temporal_block=tb)
        for n in node(has_state=Symbol("true"))
        for tb in node__temporal_block(node=n)
    )
    flow_indices_rc = RelationshipClass(
        :flow_indices_rc, (:unit, :node, :direction, :temporal_block), flow_indices
    )
    trans_indices_rc = RelationshipClass(
        :trans_indices_rc, (:connection, :node, :direction, :temporal_block), trans_indices
    )
    node_state_indices_rc = RelationshipClass(
        :node_state_indices_rc, (:node, :temporal_block), node_state_indices
    )
    @eval begin
        flow_indices_rc = $flow_indices_rc
        trans_indices_rc = $trans_indices_rc
        node_state_indices_rc = $node_state_indices_rc
        export flow_indices_rc
        export trans_indices_rc
        export node_state_indices_rc
    end
end

function generate_direction()
    # direction
    from_node = Object(:from_node, 1)
    to_node = Object(:to_node, 2)
    direction = ObjectClass(:direction, [from_node, to_node], Dict())
    # unit__node__direction
    u_n_d_rels = [(unit=u, node=n, direction=from_node) for (u, n) in unit__from_node.relationships]
    append!(u_n_d_rels, [(unit=u, node=n, direction=to_node) for (u, n) in unit__to_node.relationships])
    u_n_d_vals = Dict((u, n, from_node) => val for ((u, n), val) in unit__from_node.parameter_values)
    merge!(u_n_d_vals, Dict((u, n, to_node) => val for ((u, n), val) in unit__to_node.parameter_values))
    unit__node__direction = RelationshipClass(
        :unit__node__direction, (:unit, :node, :direction), u_n_d_rels, u_n_d_vals
    )
    # connection__node__direction
    conn_n_d_rels = [(connection=conn, node=n, direction=from_node) for (u, n) in connection__from_node.relationships]
    append!(
        conn_n_d_rels, 
        [(connection=conn, node=n, direction=to_node) for (u, n) in connection__to_node.relationships]
    )
    conn_n_d_vals = Dict((conn, n, from_node) => val for ((conn, n), val) in connection__from_node.parameter_values)
    merge!(
        conn_n_d_vals, Dict((conn, n, to_node) => val for ((conn, n), val) in connection__to_node.parameter_values)
    )
    connection__node__direction = RelationshipClass(
        :connection__node__direction, (:connection, :node, :direction), conn_n_d_rels, conn_n_d_vals
    )
end 
