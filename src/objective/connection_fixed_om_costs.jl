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
    fixed_om_costs(m)

Create an expression for fixed operation costs of connections.
"""
function connection_fixed_om_costs(m, t1)
    t0 = _analysis_time(m)
    @fetch connections_invested_available = m.ext[:variables]
    @expression(
        m,
        expr_sum(
            + connection_capacity[(connection=c, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
            * (!isnothing(candidate_connections(connection=c)) ? connections_invested_available[c, s, t] : 1)
            * connection_fom_cost[(connection=c, stochastic_scenario=s, analysis_time=t0, t=t)] #should be given as costs per year?
            # * connection_discounted_duration[(connection=c, stochastic_scenario=s,t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            for (c, ng, d) in indices(connection_capacity; connection=indices(connection_fom_cost))
            for (c, s, t) in connections_invested_available_indices(m; connection=c) if end_(t) <= t1;
            init=0,
        )
    )
end
#TODO: scenario tree?
