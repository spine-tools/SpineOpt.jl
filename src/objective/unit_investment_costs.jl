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
    unit = indices(unit_investment_cost)
    @expression(
        m,
        + sum(
            + units_invested[u, s, t]
            * unit_investment_cost(m; unit=u, stochastic_scenario=s, t=t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            # This term is activated when there is a representative temporal block in those containing TimeSlice t.
            # We assume only one representative temporal structure available, of which the temporal blocks represent
            # an extended period of time with a weight >=1, e.g. a representative month represents 3 months.
            * unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s)
            for (u, s, t) in units_invested_available_indices(m; unit=unit, t=t_range);
            init=0,
        )
    )
end
