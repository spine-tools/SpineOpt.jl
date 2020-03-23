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
    add_constraint_trans_capacity!(m::Model)

Limit the maximum in/out `trans` of a `connection` for all `trans_capacity` indices.
Check if `connection_conv_cap_to_trans` is defined.
"""
function add_constraint_trans_capacity!(m::Model)
    @fetch trans = m.ext[:variables]
    cons = m.ext[:constraints][:trans_capacity] = Dict()
    for (conn_, n_, d) in indices(connection_capacity)
        for (conn,) in indices(connection_availability_factor; connection=conn_)
            for t in time_slice()
                cons[conn, n, t] = @constraint(
                    m,
                    + reduce(
                        +,
                        trans[conn1, n1, d1, t1] * duration(t1)
                        for (conn1, n1, d1, t1) in trans_indices(connection=conn, node=n, direction=d, t=t);
                        init=0
                    )
                    <=
                    + connection_capacity[(connection=conn, node=n, direction=d, t=t)]
                    * connection_availability_factor[(connection=conn, t=t)]
                    * connection_conv_cap_to_flow[(connection=conn, node=n, direction=d, t=t)]
                    * duration(t)
                )
            end
        end
    end
end