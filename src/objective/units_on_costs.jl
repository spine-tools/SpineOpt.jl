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
    units_on_costs(m::Model)

Create an expression for units_on cost.
"""
function units_on_costs(m::Model, t_range)
    @fetch units_on = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            + units_on[u, s, t]
            * (!isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
               unit_discounted_duration[(unit=u, stochastic_scenario=s, t=t)] : 1
            ) 
            * duration(t)
            * units_on_cost(m; unit=u, stochastic_scenario=s, t=t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            # This term is activated when there is a representative termporal block in those containing TimeSlice t.
            # We assume only one representative temporal structure available, of which the termporal blocks represent
            # an extended period of time with a weight >=1, e.g. a representative month represents 3 months.
            * unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s)
            for (u, s, t) in units_on_indices(m; unit=indices(units_on_cost), t=t_range);
            init=0,
        )
    )
end
