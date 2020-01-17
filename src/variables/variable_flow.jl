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
    create_variable_flow!(m::Model)

Add new `flow` variable to the model `m`.

This variable represents the (average) instantaneous flow of a *commodity*
between a *node* and a *unit* in a certain *direction*
and within a certain *time slice*.

"""
function create_variable_flow!(m::Model)
    KeyType = NamedTuple{(:unit, :node, :commodity, :direction, :t),Tuple{Object,Object,Object,Object,TimeSlice}}
    flow = Dict{KeyType,Any}()
    for (u, n, c, d, t) in flow_indices()
        fix_flow_ = fix_flow(unit=u, node=n, direction=d, t=t)
        flow[(unit=u, node=n, commodity=c, direction=d, t=t)] = if fix_flow_ != nothing
            fix_flow_
        else
            @variable(m, base_name="flow[$u, $n, $c, $d, $(t.JuMP_name)]", lower_bound=0)
        end
    end
    merge!(get!(m.ext[:variables], :flow, Dict{KeyType,Any}()), flow)
end

"""
    flow_indices(
        commodity=anything,
        node=anything,
        unit=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `flow` variable.
The keyword arguments act as filters for each dimension.
"""
function flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything)
    unit = expand_unit_group(unit)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (unit=u, node=n, commodity=c, direction=d, t=t1)
        for (u, n, c, d, tb) in flow_indices_rc(
            unit=unit, node=node, commodity=commodity, direction=direction, _compact=false
        )
        for t1 in time_slice(temporal_block=tb, t=t)
    ]
end