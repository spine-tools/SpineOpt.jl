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
    generate_variable_flow(m::Model)

A `flow` variable for each tuple of `commodity__node__unit__direction__time_slice`,
attached to model `m`.
`flow` represents the (average) instantaneous flow of a 'commodity' between a 'node' and a 'unit' within a certain 'time_slice'
in a certain 'direction'. The direction is relative to the unit.
"""
function variable_flow(m::Model)
    Dict{Tuple,JuMP.VariableRef}(
        (u, n, c, d, t) => @variable(
            m, base_name="flow[$u, $n, $c, $d, $(t.JuMP_name)]", lower_bound=0
        ) for (u, n, c, d, t) in flow_indices()
    )
end


"""
    flow_indices(filtering_options...)

A set of tuples for indexing the `flow` variable. Any filtering options can be specified
for `commodity`, `node`, `unit`, `direction`, and `t`.
"""
function flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything)
    [
        (unit=u, node=n, commodity=c, direction=d, t=t1)
        for (n, c) in node__commodity(commodity=commodity, node=node, _compact=false)
            for (u, n_, d, blk) in unit__node__direction__temporal_block(
                    node=n, unit=unit, direction=direction, _compact=false)
                for t1 in intersect(time_slice(temporal_block=blk), t)
    ]
end
