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
    variable_trans(m::Model)

A `trans` variable (short for transfer)
for each tuple of commodity, node, unit, direction, and time slice, attached to model `m`.
`trans` represents the (average) instantaneous flow of a commodity between a node and a connection,
within a certain time slice and in a certain direction. The direction is relative to the connection.
"""
function variable_trans(m::Model)
    names = (:connection, :node, :commodity, :direction, :t)
    KeyType = NamedTuple{names,Tuple{Object,Object,Object,Object,TimeSlice}}
    m.ext[:variables][:var_trans] = Dict{KeyType,Any}(
        (connection=conn, node=n, commodity=c, direction=d, t=t) => @variable(
            m,
            base_name="trans[$conn, $n, $c, $d, $(t.JuMP_name)]",
            lower_bound=0
        ) for (conn, n, c, d, t) in var_trans_indices()
    )
    m.ext[:variables][:fix_trans] = Dict{KeyType,Any}(
        (connection=conn, node=n, commodity=c, direction=d, t=t) => fix_trans(
            connection=conn, node=n, direction=d, t=t
        ) for (conn, n, c, d, t) in fix_trans_indices()
    )
    m.ext[:variables][:trans] = merge(
        m.ext[:variables][:var_trans],
        m.ext[:variables][:fix_trans]
    )
end


"""
    trans_indices(filtering_options...)

A set of tuples for indexing the `trans` variable. Any filtering options can be specified
for `commodity`, `node`, `connection`, `direction`, and `t`.
"""
function trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    unique([
        var_trans_indices(commodity=commodity, node=node, connection=connection, direction=direction, t=t);
        fix_trans_indices(commodity=commodity, node=node, connection=connection, direction=direction, t=t)
    ])
end

function var_trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (connection=conn, node=n, commodity=c, direction=d, t=t1)
        for (conn, n_, d, blk) in connection__node__direction__temporal_block(
                node=node, connection=connection, direction=Object(direction), _compact=false)
            for (n, c) in node__commodity(commodity=commodity, node=n_, _compact=false)
                for t1 in intersect(time_slice(temporal_block=blk), t)
    ]
end

function fix_trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (connection=conn, node=n, commodity=c, direction=d, t=t1)
        for (conn, n_, d) in indices(fix_trans; connection=connection, node=node, direction=direction)
                if fix_trans(connection=conn, node=n, direction=d) isa TimeSeriesValue
            for (n, c) in node__commodity(commodity=commodity, node=n_, _compact=false)
                for t1 in intersect(
                        t_highest_resolution(
                            t for t in time_slice()
                                if any(s in t for s in time_stamps(fix_trans(connection=conn, node=n, direction=d)))
                        ),
                        t
                    )
    ]
end
