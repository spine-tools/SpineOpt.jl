#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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

@doc raw"""
    add_expression_line_charging_q!(m::Model)

Create an expression for `line_charging_q` which just the voltage squared
    but adjusted for the number of connections (0 or 1 are supported).

"""
function add_expression_line_charging_q!(m::Model)
    @fetch node_voltage_squared, line_charging_q_inv = m.ext[:spineopt].variables
    m.ext[:spineopt].expressions[:line_charging_q] = Dict(
        (connection=conn, node=n, direction=d, stochastic_scenario=s, t=t1) => 
        begin
            if is_candidate(connection=conn) && conn in indices(line_shunt_susceptance)
                @expression(m, line_charging_q_inv[conn, n, d, s, t1] 
                * line_shunt_susceptance(m; connection=conn, stochastic_scenario=s, t=t1, _default=0) 
                * 0.5)
            else
                @expression(m, node_voltage_squared[n, s, t1]
                * line_shunt_susceptance(m; connection=conn, stochastic_scenario=s, t=t1, _default=0)
                * 0.5)
            end
        
        end
        for (conn, n, d, s, t1) in connection_reactive_flow_indices(m)
    )
end
