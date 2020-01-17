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
    create_variable_trans!(m::Model)

Add new `trans` variable for model `m`.

This variable represents the (average) instantaneous flow of a *commodity* between a *node* and a *connection*
in a certain *direction* and within a certain *time slice*.
"""
function create_variable_trans!(m::Model)
    KeyType = NamedTuple{(:connection, :node, :commodity, :direction, :t),Tuple{Object,Object,Object,Object,TimeSlice}}
    trans = Dict{KeyType,Any}()
    for (conn, n, c, d, t) in trans_indices()
        fix_trans_ = fix_trans(connection=conn, node=n, direction=d, t=t)
        trans[(connection=conn, node=n, commodity=c, direction=d, t=t)] = if fix_trans_ != nothing
            fix_trans_
        else
            @variable(m, base_name="trans[$conn, $n, $c, $d, $(t.JuMP_name)]", lower_bound=0)
        end
    end
    merge!(get!(m.ext[:variables], :trans, Dict{KeyType,Any}()), trans)
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
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (connection=conn, node=n, commodity=c, direction=d, t=t1)
        for (conn, n, c, d, tb) in trans_indices_rc(
            connection=connection, node=node, commodity=commodity, direction=direction, _compact=false
        )
        for t1 in time_slice(temporal_block=tb, t=t)
    ]
end