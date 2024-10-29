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
    fixed_om_costs(m)

Create an expression for fixed operation costs of units.
"""
function fixed_om_costs(m, t_range)
    @fetch units_invested_available = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            + unit_capacity(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * (
                use_economic_representation(model=m.ext[:spineopt].instance) ? 
                unit_discounted_duration[(unit=u, stochastic_scenario=s, t=t)] : 1
            ) 
            * fom_cost(m; unit=u, stochastic_scenario=s, t=t)
            * (
                + number_of_units(m; unit=u, stochastic_scenario=s, t=t)
                + (
                    u in intersect(indices(candidate_units), members(u)) ? 
                    units_invested_available[u, s, t] : 0
                )
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            # This term is activated when there is a representative temporal block that includes t.
            # We assume only one representative temporal structure available, of which the termporal blocks represent
            # an extended period of time with a weight >=1, e.g. a representative month represents 3 months.
            * duration(t) 
            for (u, ng, d) in indices(unit_capacity; unit=indices(fom_cost))
            for (u, _n, _d, s, t) in unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_range);
            init=0,
        )
    )
end
#TODO: scenario tree?
