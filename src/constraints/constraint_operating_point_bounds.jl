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
    add_constraint_operating_point_bounds!(m::Model)

Limit the operating point flow variables to the difference between successive operating points times the capacity of the unit

"""

function add_constraint_operating_point_bounds!(m::Model)
    @fetch unit_flow_op, unit_flow = m.ext[:variables]
    cons = m.ext[:constraints][:operating_point_bounds] = Dict()

    for (u_, n_, d_) in indices(unit_capacity)
        for (u, n, d, op, t) in unit_flow_op_indices(unit=u_, node=n_, direction=d_)
            cons[u, n, d, op, t] = @constraint(
                m,
                unit_flow_op[u, n, d, op, t]
                <=
                (
                    + operating_points[(unit=u, node=n, i=op)]
                    - reduce(
                        +,
                        + operating_points[(unit=u, node=n, i=op_previous)]
                        for op_previous in op-1:op-1 if op > 1;
                        init = 0
                    )
                )
                * unit_capacity[(unit=u, node=n, direction=d, t=t)]
                * unit_conv_cap_to_flow[(unit=u, node=n, direction=d, t=t)]
            )
        end
    end
end
