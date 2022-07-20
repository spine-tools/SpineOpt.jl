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
    unit_decommissioning_costs(m::Model)

Create and expression for unit decommissioning costs.
"""
function unit_decommissioning_costs(m::Model, t1)
    @fetch units_decommissioned = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        + expr_sum(
            units_decommissioned[u, s, t]
            * unit_decommissioning_conversion_to_discounted_annuities[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * unit_decommissioning_cost[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * reduce(+,
                unit_capacity[(unit=u, node=n, direction = d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, n, d) in indices(use_unit_capacity_for_investment_cost_scaling; unit=u)
                    if use_unit_capacity_for_investment_cost_scaling(unit=u, node=n, direction = d)
                ;init=1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s)
            for (u, s, t) in units_invested_available_indices(m; unit=indices(unit_decommissioning_cost)) if end_(t) <= t1;
            init=0,
        )
    )
end
