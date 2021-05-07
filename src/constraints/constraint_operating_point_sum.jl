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
    add_constraint_operating_point_sum!(m::Model)

Limit the operating point flow variables to the difference between successive operating points
times the capacity of the unit.
"""
function add_constraint_operating_point_sum!(m::Model)
    @fetch unit_flow_op, unit_flow = m.ext[:variables]
    m.ext[:constraints][:operating_point_sum] = Dict(
        (unit=u, node=n, direction=d, stochastic_scenmario=s, t=t) => @constraint(
            m,
            + unit_flow[u, n, d, s, t]
            ==
            + expr_sum(
                + unit_flow_op[u, n, d, op, s, t] for op in 1:length(operating_points(unit=u, node=n, direction=d));
                init=0,
            )
        ) for (u, n, d) in indices(operating_points)
        for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=n, direction=d)
    )
end
