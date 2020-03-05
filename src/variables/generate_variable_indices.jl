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
        (unit=u, node=n, commodity=c, direction=d, temporal_block=tb)
        for (u, n, d) in unit__node__direction()
        for c in node__commodity(node=n)
        for tb in node__temporal_block(node=n)
    )
    trans_indices = unique(
        (connection=conn, node=n, commodity=c, direction=d, temporal_block=tb)
        for (conn, n, d) in connection__node__direction()
        for c in node__commodity(node=n)
        for tb in node__temporal_block(node=n)
    )
    node_state_indices = unique(
    	(node=n, temporal_block=tb)
        for (n, tb) in node__temporal_block()
    )
	flow_indices_rc = RelationshipClass(
		:flow_indices_rc, (:unit, :node, :commodity, :direction, :temporal_block), flow_indices
	)
	trans_indices_rc = RelationshipClass(
		:trans_indices_rc, (:connection, :node, :commodity, :direction, :temporal_block), trans_indices
	)
	node_state_indices_rc = RelationshipClass(
		:node_state_indices_rc, (:node, :temporal), node_state_indices
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