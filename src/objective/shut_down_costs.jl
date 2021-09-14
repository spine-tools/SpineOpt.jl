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
    shut_down_costs(m::Model)

Create an expression for unit shutdown costs.
"""
function shut_down_costs(m::Model, t1)
    @fetch units_shut_down = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            + units_shut_down[u, s, t]
            * shut_down_cost[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s)
            for (u, s, t) in units_on_indices(m; unit=indices(shut_down_cost)) if end_(t) <= t1;
            init=0,
        )
    )
end
