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
    constraint_node_voltage_angle_ref(m::Model)

Reference node voltage angle.
"""
function add_constraint_node_voltage_angle_ref!(m::Model)
    @fetch node_voltage_angle = m.ext[:variables]
    constr_dict = m.ext[:constraints][:ref_node] = Dict()
    for (n,s,t) in node_voltage_angle_indices(m,node=node(:node_1))
            constr_dict[n,s,t] = @constraint(
                m,
                node_voltage_angle[n,s,t]
                ==
                0
            )
    end
end
