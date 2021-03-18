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
    start_up_costs(m::Model)

Create an expression for unit startup costs.
"""
function res_start_up_costs(m::Model, t1)
    @fetch nonspin_units_started_up = m.ext[:variables]
    @expression(
        m,
        expr_sum(
            +nonspin_units_started_up[u, n, s, t] *
            res_start_up_cost[(unit=u, node=n, direction=d, stochastic_scenario=s, t=t)] *
            prod(weight(temporal_block=blk) for blk in blocks(t)) *
            unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s) for (u, n, d) in indices(res_start_up_cost)
            for (u, n, s, t) in nonspin_units_started_up_indices(m; unit=u, node=n) if end_(t) <= t1;
            init=0,
        )
    )
end
