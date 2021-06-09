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
    add_constraint_units_available!(m::Model)

Limit the units_online by the number of available units.
"""
function add_constraint_units_available!(m::Model)
    @fetch units_available, units_invested_available = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:units_available] = Dict(
        (unit=u, stochastic_scenario=s, t=t) => @constraint(
            m,
            +units_available[u, s, t]
            <=
            +unit_availability_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)] * (
                +number_of_units[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)] 
                + expr_sum(
                    units_invested_available[u, s, t1]
                    for
                    (u, s, t1) in
                    units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t_in_t(m; t_short=t));
                    init=0,
                )
            )
        ) for (u, s, t) in units_on_indices(m)
    )
end
