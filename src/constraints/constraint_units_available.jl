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
    @fetch units_available, units_invested_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:units_available] = Dict(
        (unit=u, stochastic_scenario=s, t=t) => @constraint(
            m,
            + expr_sum(
                units_available[u, s, t] for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t);
                init=0,
            )
            <=
            + unit_availability_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * (
                + number_of_units[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)] 
                + expr_sum(
                    units_invested_available[u, s, t1]
                    for (u, s, t1) in units_invested_available_indices(
                        m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t)
                    );
                    # If t_overlaps_t is chosen here, we don't predefine hierarchy; 
                    # not crucial, as most likely always t_operations < t_investment
                    # but could be considered in the future
                    init=0,
                )
            )
        )
        for (u, s, t) in constraint_units_available_indices(m)
    )
end

"""
    constraint_units_available_indices(m::Model, unit, t)
    
Creates all indices required to include units, stochastic paths and temporals for the `add_constraint_units_available!`
constraint generation.
"""
function constraint_units_available_indices(m::Model)
    unique(
        (unit=u, stochastic_scenario=s, t=t)
        for (u, t) in unit_time_indices(m)
        for path in active_stochastic_paths(
            unique(
                ind.stochastic_scenario
                for ind in vcat(
                    units_on_indices(m; unit=u, t=t),
                    units_invested_available_indices(m; unit=u, t=t_overlaps_t(m; t=t))
                )
            )
        )
        for s in path
    )
end
