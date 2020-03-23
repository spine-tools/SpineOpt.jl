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
    trans_indices(
        connection=anything,
        node=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `trans` variable.
The keyword arguments act as filters for each dimension.
"""
function trans_indices(;connection=anything, node=anything, direction=anything, t=anything)
    node = expand_node_group(node)
    [
        (connection=conn, node=n, direction=d, t=t1)
        for (conn, n, d, tb) in trans_indices_rc(
            connection=connection, node=node, direction=direction, _compact=false
        )
        for t1 in time_slice(temporal_block=tb, t=t)
    ]
end

fix_trans_(x) = fix_connection_flow(connection=x.connection, node=x.node, direction=x.direction, t=x.t, _strict=false)

create_variable_trans!(m::Model) = create_variable!(m, :trans, trans_indices; lb=x -> 0)
save_variable_trans!(m::Model) = save_variable!(m, :trans, trans_indices)
fix_variable_trans!(m::Model) = fix_variable!(m, :trans, trans_indices, fix_trans_)