#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
    fuel_costs(m::Model)

Create an expression for fuel costs of units.
"""
function fuel_costs(m::Model, t_range)
    @fetch unit_flow = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            unit_flow[u, n, d, s, t]
            * duration(t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * fuel_cost(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * node_stochastic_scenario_weight(m; node=ng, stochastic_scenario=s)
            for (u, ng, d) in indices(fuel_cost)
            for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_range);
            init=0,
        )
    )
end
