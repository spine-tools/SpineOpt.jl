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
    generate_variable_trans(m::Model)

A `trans` variable (short for transfer)
for each tuple of `commodity__node__unit__direction__time_slice`, attached to model `m`.
`trans` represents the (average) instantaneous flow of a 'commodity' between a 'node' and a 'connection' within a certain 'time_slice'
in a certain 'direction'. The direction is relative to the connection.
"""
function variable_trans(m::Model)
    m.ext[:variables][:trans] = Dict(
        (connection=conn, node=n, commodity=c, direction=d, t=t) => @variable(
            m,
            base_name="trans[$conn, $n, $c, $d, $(t.JuMP_name)]",
            lower_bound=0
        ) for (conn, n, c, d, t) in trans_indices()
    )
end


"""
    trans_indices(filtering_options...)

A set of tuples for indexing the `trans` variable. Any filtering options can be specified
for `commodity`, `node`, `connection`, `direction`, and `t`.
"""
function trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    [
        (connection=conn, node=n, commodity=c, direction=d, t=t1)
        for (conn, n_, d, blk) in connection__node__direction__temporal_block(
                node=node, connection=connection, direction=Object(direction), _compact=false)
            for (n, c) in node__commodity(commodity=commodity, node=n_, _compact=false)
                for t1 in intersect(time_slice(temporal_block=blk), t)
    ]
end
