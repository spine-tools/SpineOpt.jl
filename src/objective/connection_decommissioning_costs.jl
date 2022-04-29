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
    connection_decommissioning_costs(m::Model)

Create and expression for connection decommissioning costs.
"""
function connection_decommissioning_costs(m::Model, t1)
    @fetch connections_decommissioned = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        + expr_sum(
            connections_decommissioned[c, s, t]
            # * connection_decommissioning_conversion_to_discounted_annuities[(connection=c, stochastic_scenario=s, analysis_time=t0, t=t)]
            * reduce(+,
                connection_capacity[(connection=c, node=n, direction = d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, n, d) in indices(use_connection_capacity_for_investment_cost_scaling; unit=u)
                    if use_connection_capacity_for_investment_cost_scaling(unit=u, node=n, direction = d)
                ;init=1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * connection_decommissioning_cost[(connection=c, stochastic_scenario=s, analysis_time=t0, t=t)]
            * connection_stochastic_scenario_weight(m; connection=c, stochastic_scenario=s)
            for (c, s, t) in connections_invested_available_indices(m; connection=indices(connection_decommissioning_cost))
                if end_(t) <= t1;
            init=0,
        )
    )
end
