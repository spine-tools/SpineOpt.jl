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
    constraint_trans_capacity(m::Model, trans)

Limit the maximum in/out `trans` of a `connection` if the parameters `connection_capacity,
number_of_connection, connection_conv_cap_to_trans, avail_factor` exist.
"""
function constraint_trans_capacity(m::Model, trans)
    @butcher for (c, n, conn) in commodity__node__connection__direction(direction=:in), t=1:number_of_timesteps(time=:timer)
        all([
            connection_capacity(connection=conn, commodity=c, node=n, direction=:in) != nothing,
            number_of_connections(connection=conn) != nothing,
            connection_conv_cap_to_trans(connection=conn, commodity=c) != nothing,
            avail_factor_trans(connection=conn, t=t) != nothing
        ]) || continue
        @constraint(
            m,
            + trans[c, n, conn, :in, t]
            <=
            + avail_factor_trans(connection=conn, t=t)
                * connection_capacity(connection=conn, commodity=c, node=n, direction=:in)
                    * number_of_connections(connection=conn)
                        * connection_conv_cap_to_trans(connection=conn, commodity=c)
        )
    end
end
