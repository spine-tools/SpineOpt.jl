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

Limit the operating point flow variables `unit_flow_op` to the difference between successive operating points times
the capacity of the unit.
"""
function add_constraint_operating_point_bounds!(m::Model)
    @fetch unit_flow_op, units_available = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:operating_point_bounds] = Dict(
        (unit=u, node=n, direction=d, i=op, stochastic_scenario=s, t=t) => @constraint(
            m,
            + unit_flow_op[u, n, d, op, s, t]
            <=
            (
                + operating_points[(unit=u, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, i=op)] - (
                    (op > 1) ?
                    operating_points[(unit=u, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, i=op - 1)] :
                    0
                )
            )
            * unit_capacity[(unit=u, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
            * units_available[u, s, t]
            * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
            # TODO: extend to investment functionality ? (is that even possible)
        ) for (u, n, d) in indices(unit_capacity)
        for (u, n, d, op, s, t) in unit_flow_op_indices(m; unit=u, node=n, direction=d)
    )
end
