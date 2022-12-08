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
    add_constraint_operating_point_bounds!(m::Model)

Limit the maximum number of each activated segment `unit_flow_op_active` cannot be higher than the number of online units.
"""
function add_constraint_operating_point_bounds!(m::Model)
    @fetch unit_flow_op_active, units_on = m.ext[:spineopt].variables
    m.ext[:spineopt].constraints[:operating_point_bounds] = Dict(
        (unit=u, node=n, direction=d, i=op, stochastic_scenario=s, t=t) => @constraint(
            m,
            unit_flow_op_active[u, n, d, op, s, t]
            <= 
            units_on[u, s, t]
        )
        for (u, s, t) in units_on_indices(m)
        for (u, n, d, op, s, t) in unit_flow_op_indices(m; unit=u, stochastic_scenario=s, t=t)
    )
end
