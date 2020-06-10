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
    add_constraint_split_ramps!(m::Model)

Split delta(`unit_flow`) in `ramp_up_unit_flow and` `start_up_unit_flow`. This is
required to enforce separate limitations on these two ramp types.
"""
#TODO add scenario tree!!!
function add_constraint_ramp_up!(m::Model)
    @fetch unit_flow, ramp_up_unit_flow, start_up_unit_flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:split_ramp_up] = Dict()
    for (u, n, d, s, t_before) in ramp_up_unit_flow_indices()
        for (u, n, d, s, t_after) in unit_flow_indices(unit=u,node=n,commodity=c,direction=d,t=t_before_t(t_before=t_before))
            constr_dict[u, n, d, s, t_before] = @constraint(
                m,
                unit_flow[u, n, d, s, t_after]
                - unit_flow[u, n, d, s, t_before]
                #TODO: this needs to sum over u,n,d,
                #maybe have on unit__to_node relationship has ramps and then only trigger these constraints
                <=
                ramp_up_unit_flow[u, n, d, s, t_before]
                +
                start_up_unit_flow[u, n, d, s, t_after]
            )
        end
    end
end
