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
    add_constraint_max_start_up_ramp!(m::Model)

Limit the maximum ramp at the start up of a unit. For reserves the max non-spinning
reserve ramp can be defined here.
"""
#TODO: Good to go for first try; make sure capacities are well defined
function add_constraint_max_nonspin_ramp_up!(m::Model)
    @fetch nonspin_ramp_up_unit_flow, nonspin_starting_up = m.ext[:variables]
    cons = m.ext[:constraints][:max_nonspin_start_up_ramp] = Dict()
    @warn "how to incorporate time_slice and stochastic strucutre?"
    @warn "this should get the highest resolution as in fix_ratio constraint"
    for (u, n, d) in indices(max_res_startup_ramp) #TODO: add to template and db
        for t in time_slice()
        s = stochastic_scenario()[1]
            cons[u, n, d, s, t] = @constraint(
                m,
                + sum(
                    nonspin_ramp_up_unit_flow[u, n, d, s, t]
                            for (u, n, d, s, t) in nonspin_ramp_up_unit_flow_indices(
                                unit=u, node=n, direction=d, stochastic_scenario=s, t=t_in_t(t_long=t))
                )
                <=
                + expr_sum(
                    nonspin_starting_up[u, n, s, t]
                            for (u, n, s, t) in nonspin_starting_up_indices(
                                unit=u, node=n, stochastic_scenario=s, t=t_overlaps_t(t));
                                init=0
                )
                    * max_res_startup_ramp[(unit=u, node=n, direction=d, stochastic_scenario=s, t=t)]
                    * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)]
                    * unit_capacity[(unit=u, node=n, direction=d, stochastic_scenario=s, t=t)]
            )
        end
    end
end
