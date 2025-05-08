#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    connection_flow_costs(m::Model)

Create an expression for `connection_flow` costs.
"""
function connection_flow_costs(m::Model, t_range)
    @fetch connection_flow = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            connection_flow[conn, n, d, s, t]
            * duration(t)
            * (!isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
               connection_discounted_duration[(connection=conn, stochastic_scenario=s, t=t)] : 1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * connection_flow_cost(m; connection=conn, node=n, direction=d, stochastic_scenario=s, t=t)
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (conn, n, d) in indices(connection_flow_cost)
            for (conn, n, d, s, t) in connection_flow_indices(m; connection=conn, node=n, direction=d, t=t_range);
            init=0,
        )
    )
end
# TODO: add weight scenario tree
