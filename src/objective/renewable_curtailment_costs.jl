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
    renewable_curtailment_costs(m::Model)

Create an expression for curtailment costs of renewables.
"""
function renewable_curtailment_costs(m::Model, t_range)
    @fetch unit_flow, units_on = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            + curtailment_cost(m; unit=u, stochastic_scenario=s, t=t_short)
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            * (
                + units_on[u, s, t_long]
                * unit_flow_capacity(m; unit=u, node=n, direction=d, stochastic_scenario=s, t=t_short)
                - unit_flow[u, n, d, s, t_short]
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t_short))
            * (!isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
               unit_discounted_duration[(unit=u, stochastic_scenario=s, t=t)] : 1
            ) 
            * duration(t_short) for u in indices(curtailment_cost) for (u, n, d) in indices(unit_capacity; unit=u)
            for (u, s, t_long) in units_on_indices(m; unit=u, t=t_range)
            for (u, n, d, s, t_short) in unit_flow_indices(m; unit=u, node=n, direction=d, t=t_in_t(m; t_long=t_long));
            init=0,
        )
    )
end
