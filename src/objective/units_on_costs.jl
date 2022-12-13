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
    units_on_costs(m::Model)

Create an expression for units_on cost.
"""
function units_on_costs(m::Model, t_range)
    @fetch units_on = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            + units_on[u, s, t]
            * duration(t)
            * units_on_cost[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s)
            for (u, s, t) in units_on_indices(m; unit=indices(units_on_cost), t=t_range);
            init=0,
        )
    )
end
