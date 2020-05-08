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
    start_up_costs(m::Model)

Startup cost term for units.
"""
function start_up_costs(m::Model)
    @fetch units_started_up = m.ext[:variables]
    @expression(
        m,
        expr_sum(
            + units_started_up[u, s, t]
            * start_up_cost[(unit=u, stochastic_scenario=s, t=t)]
            * unit_stochastic_scenario_weight(unit=u, stochastic_scenario=s)
            for (u, s, t) in units_on_indices(unit=indices(start_up_cost));
            init=0
        )
    )
end
