#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
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
    unit_investment_costs(m::Model)

Create and expression for unit investment costs.
"""
function unit_investment_costs(m::Model, t_range)
    @fetch units_invested = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    @expression(
        m,
        + expr_sum(
            units_invested[u, s, t]
            * (1- unit_salvage_fraction[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)])
            * unit_tech_discount_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * unit_conversion_to_discounted_annuities[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * unit_investment_cost[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * reduce(*,
                unit_capacity[(unit=u, node=n, direction = d, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, n, d) in indices(use_unit_capacity_for_investment_cost_scaling; unit=u)
                    if use_unit_capacity_for_investment_cost_scaling(unit=u, node=n, direction = d)
                ;init=1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            # This term is activated when there is a representative termporal block in those containing TimeSlice t.
            # We assume only one representative temporal structure available, of which the termporal blocks represent
            # an extended period of time with a weight >=1, e.g. a representative month represents 3 months.
            * unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s)
            for (u, s, t) in units_invested_available_indices(m; unit=indices(unit_investment_cost), t=t_range);
            init=0,
        )
    )
end
