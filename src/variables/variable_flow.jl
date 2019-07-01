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
    variable_flow(m::Model)

Create the `flow` variable for the model `m`.

This variable represents the (average) instantaneous flow of a *commodity*
between a *node* and a *unit* in a certain *direction*
and within a certain *time slice*.

"""
function variable_flow(m::Model)
    m.ext[:variables][:flow] = Dict(
        (unit=u, node=n, commodity=c, direction=d, t=t) => @variable(
            m,
            base_name="flow[$u, $n, $c, $d, $(t.JuMP_name)]",
            lower_bound=0
        ) for (u, n, c, d, t) in flow_indices()
    )
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
    [
        var_flow_indices(commodity=commodity, node=node, unit=unit, direction=direction, t=t);
        fix_flow_indices(commodity=commodity, node=node, unit=unit, direction=direction, t=t)
    ]
end

"""
    var_flow_indices(
        commodity=anything,
        node=anything,
        unit=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to *non-fixed* indices of the `flow` variable.
The keyword arguments act as filters for each dimension.
"""
function var_flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything)
    unit = expand_unit_group(unit)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (unit=u, node=n, commodity=c, direction=d, t=t1)
        for (u, n, d, blk) in unit__node__direction__temporal_block(
                node=node, unit=unit, direction=direction, _compact=false)
            for (n_, c) in node__commodity(commodity=commodity, node=n, _compact=false)
                for t1 in time_slice(temporal_block=blk, t=t)
    ]
end

"""
    fix_flow_indices(
        commodity=anything,
        node=anything,
        unit=anything,
        direction=anything,
        t=anything
    )

A list of `NamedTuple`s corresponding to *fixed* indices of the `flow` variable.
The keyword arguments act as filters for each dimension.
"""
function fix_flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything)
    unit = expand_unit_group(unit)
    node = expand_node_group(node)
    commodity = expand_commodity_group(commodity)
    [
        (unit=u, node=n, commodity=c, direction=d, t=t1)
        for (u, c, d) in indices(fix_flow; unit=unit, commodity=commodity, direction=direction)
                if fix_flow(unit=u, commodity=c, direction=d) isa TimeSeries
            for (n, c) in node__commodity(commodity=c, node=node, _compact=false)
                for t1 in intersect(
                        t_highest_resolution(
                            to_time_slice(fix_flow(unit=u, commodity=c, direction=d).indexes...)
                        ),
                        t
                    )
    ]
end
