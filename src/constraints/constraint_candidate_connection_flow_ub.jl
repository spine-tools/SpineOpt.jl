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
    add_constraint_candidate_connection_flow_ub!(m::Model)

For connection investments with PTDF flow enabled, this constraint limits the flow on the candidate_connection
to the intact_flow on that connection, which represents the flow on the line if it is invested.

"""
function add_constraint_candidate_connection_flow_ub!(m::Model)
    @fetch connection_flow, connection_intact_flow = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:candidate_connection_flow_ub] = Dict(
        (connection=conn, node=ng, direction=d, stochastic_path=s, t=t) => @constraint(
            m,
            + connection_flow[conn, ng, d, s, t]
            <=
            + connection_intact_flow[conn, ng, d, s, t]            
        )
        for conn in connection(is_candidate=true, has_ptdf=true)
        for (conn, ng, d, s, t) in connection_flow_indices(m; connection=conn)
    )
end
