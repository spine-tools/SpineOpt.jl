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

"""
    connection_flow_costs(m::Model)

Create an expression for `connection_flow` costs.
"""
function connection_flow_costs(m::Model, t1)
    @fetch connection_flow = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            connection_flow[conn, n, d, s, t]
            # * connection_discounted_duration[(connection=conn, stochastic_scenario=s,t=t)]
            * duration(t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * connection_flow_cost[(connection=conn, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (conn, n, d) in indices(connection_flow_cost)
            for (conn, n, d, s, t) in connection_flow_indices(m; connection=conn, node=n, direction=d) if end_(t) <= t1;
            init=0,
        )
    )
end
# TODO: add weight scenario tree
