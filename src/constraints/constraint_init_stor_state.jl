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
    constraint_node_state(m::Model)

Balance for storage level.
"""
function add_constraint_init_node_state!(m::Model)
    @fetch node_state= m.ext[:variables]
    constr_dict = m.ext[:constraints][:init_node_state] = Dict()
    t_before1 = t_before_t(m;t_after=time_slice(m)[1])
    t0 = startref(current_window(m))
    for (stor, s, t_before) in node_state_indices(m;t=t_before_t(m;t_after=time_slice(m)[1]))
        if stor in indices(node_state_init)
            constr_dict[stor, s, t_before] = @constraint(
                m,
                + node_state[stor, s, t_before]
                    * state_coeff(node=stor)
                     / duration(t_before)
                ==
                node_state_init(node=stor))
        end
    end
    for (stor, s, t_before) in node_state_indices(m;t=time_slice(m)[end])
        if stor in indices(node_state_init)
            constr_dict[stor, s, t_before] = @constraint(
                m,
                + node_state[stor, s, t_before]
                    * state_coeff(node=stor)
                     / duration(t_before)
                >=
                node_state_init(node=stor)
                )#
            end
    end
end
