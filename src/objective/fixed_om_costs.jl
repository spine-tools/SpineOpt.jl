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
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            + unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
            * fom_cost[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
            * (
                + number_of_units[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)] 
                + expr_sum(
                    units_invested_available[u, s, t1]
                    for (u, s, t1) in units_invested_available_indices(
                        m; unit=u, t=t_overlaps_t(m; t)
                        # m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t)
                    );
                    # Resemble constraint_units_available.jl, lift restriction on stochastic_scenario;
                    init=0,
                )
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * duration(t) for (u, ng, d) in indices(unit_capacity; unit=indices(fom_cost))
            # for (u, s, t) in units_invested_available_indices(m; unit=u, t=t_range);
            for (u, s, t) in units_on_indices(m; unit=u, t=t_range);
            init=0,
        )
    )
end
#TODO: scenario tree?
