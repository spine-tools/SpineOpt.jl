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

Create the `trans` variable for model `m`.

This variable represents the (average) instantaneous flow of a *commodity* between a *node* and a *connection*
in a certain *direction* and within a certain *time slice*.
"""
function variable_trans(m::Model)
    KeyType = NamedTuple{(:connection, :node, :commodity, :direction, :t),Tuple{Object,Object,Object,Object,TimeSlice}}
    m.ext[:variables][:var_trans] = Dict{KeyType,Any}(
        (connection=conn, node=n, commodity=c, direction=d, t=t) => @variable(
            m, base_name="trans[$conn, $n, $c, $d, $(t.JuMP_name)]", lower_bound=0
        )
        for (conn, n, c, d, t) in var_trans_indices()
    )
    m.ext[:variables][:fix_trans] = Dict{KeyType,Any}(
        (connection=conn, node=n, commodity=c, direction=d, t=t) => fix_trans(connection=conn, node=n, direction=d, t=t)
        for (conn, n, c, d, t) in fix_trans_indices()
    )
    m.ext[:variables][:trans] = merge(m.ext[:variables][:var_trans], m.ext[:variables][:fix_trans])
end


"""
    trans_indices(
        commodity=anything,
        node=anything,
        connection=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `trans` variable.
The keyword arguments act as filters for each dimension.
"""
function trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    [
        var_trans_indices(commodity=commodity, node=node, connection=connection, direction=direction, t=t);
        fix_trans_indices(commodity=commodity, node=node, connection=connection, direction=direction, t=t)
    ]
end

"""
    var_trans_indices(
        commodity=anything,
        node=anything,
        connection=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to *non-fixed* indices of the `trans` variable.
The keyword arguments act as filters for each dimension.
"""
function var_trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (connection=conn, node=n, commodity=c, direction=d, t=t1)
        for (conn, n, d) in connection__node__direction(
            connection=connection, node=node, direction=direction, _compact=false
        )
        for t_blk in node__temporal_block(node=n)
        for t1 in time_slice(temporal_block=t_blk, t=t)
        if fix_trans(connection=conn, node=n, direction=d, t=t1, _strict=false) === nothing
        for (n_, c) in node__commodity(node=n, commodity=commodity, _compact=false)
    ]
end

"""
    fix_trans_indices(
        commodity=anything,
        node=anything,
        connection=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to *fixed* indices of the `trans` variable.
The keyword arguments act as filters for each dimension.
"""
function fix_trans_indices(;commodity=anything, node=anything, connection=anything, direction=anything, t=anything)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (connection=conn, node=n, commodity=c, direction=d, t=t_)
        for (conn, n, d) in indices(fix_trans; connection=connection, node=node, direction=direction)
        for t_ in time_slice(t=t)
        if fix_trans(connection=conn, node=n, direction=d, t=t_) != nothing
        for (n_, c) in node__commodity(node=n, commodity=commodity, _compact=false)
    ]
end
