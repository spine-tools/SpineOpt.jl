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
        export unit_flow_indices_rc
        export connection_flow_indices_rc
        export node_state_indices_rc
    end
end