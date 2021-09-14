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
    renewable_curtailment_costs(m::Model)

Create an expression for curtailment costs of renewables.
"""
function renewable_curtailment_costs(m::Model, t1)
    @fetch unit_flow, units_available = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            curtailment_cost[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t_short)]
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            * (units_available[u, s, t_long]
               * unit_capacity[(unit=u, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_short)]
               * unit_conv_cap_to_flow[
                   (unit=u, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_short),
               ] - unit_flow[u, n, d, s, t_short])
            * prod(weight(temporal_block=blk) for blk in blocks(t_short))
            * duration(t_short) for u in indices(curtailment_cost) for (u, n, d) in indices(unit_capacity; unit=u)
            for (u, s, t_long) in units_on_indices(m; unit=u)
            for (u, n, d, s, t_short) in unit_flow_indices(m; unit=u, node=n, direction=d, t=t_in_t(m; t_long=t_long))
                if end_(t_short) <= t1;
            init=0,
        )
    )
end
