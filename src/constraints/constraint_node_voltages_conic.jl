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
add_constraint_node_voltages_conic!(m::Model)

Binds the different voltage products together with a second order conic constraint. This is a
relaxation of the original constraint which is an equality constraint.

"""
function add_constraint_node_voltages_conic!(m::Model)
    @fetch node_voltage_squared, node_voltageproduct_cosine, 
        node_voltageproduct_sine = m.ext[:spineopt].variables
    
    m.ext[:spineopt].constraints[:node_voltages_conic] = Dict(
        (node1=n1, node2=n2, stochastic_path=s, t=t) => @constraint(
            m,
            [0.5 * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t]),
             node_voltageproduct_cosine[n1, n2, s, t],
             node_voltageproduct_sine[n1, n2, s, t],
             0.5 * (node_voltage_squared[n1, s, t] - node_voltage_squared[n2, s, t])
            ] in SecondOrderCone()
            )

        for (n1, n2, s, t) in node_voltageproduct_indices(m)
    )
end


