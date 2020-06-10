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
function add_constraint_max_start_up_ramp!(m::Model)
    @fetch units_started_up, nonspin_starting_up, start_up_unit_flow = m.ext[:variables]
    cons = m.ext[:constraints][:max_start_up_ramp] = Dict()
    for (u, n, d) in indices(max_startup_ramp)
            for (u, s, t) in units_on_indices(unit=u)
                    constr_dict1[u, n, d, s, t] = @constraint(
                        m,
                        + sum(
                            start_up_unit_flow[u, n, d, s, t]
                                    for (u, n, d, s, t) in start_up_unit_flow_indices(unit=u, commodity=c, direction = d, s=s, t=t_in_t(t_long=t))
                        ) #TODO: t_in_t_after of rahter t_short
                        <=
                            + (units_started_up[u, s, t] + nonspin_starting_up[u, n, s, t])
                                * max_startup_ramp[(unit=u, node=n, direction=d)]
                                # * max_res_startup_ramp(unit=u, node=n, direction=d, t=t)
                            * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)] *unit_capacity[(unit=u, node=n, direction=d, t=t)]
                    #TODO how does this work with the capacities? ... separate capacity for mFRR?
        end
    end
end
