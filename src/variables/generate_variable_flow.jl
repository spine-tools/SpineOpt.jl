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

A `flow` variable for each tuple returned by `commodity__node__unit__direction()`,
attached to model `m`.
`flow` represents the flow of a 'commodity' between a 'node' and a 'unit'
in a certain 'direction'.
"""
function generate_variable_flow(m::Model, timesliceblocks)
    @butcher Dict{Tuple, JuMP.VariableRef}(
        (c, n, u, d, t) => @variable(
            m, base_name="flow[$c, $n, $u, $d, $t]", lower_bound=0
        ) for (c, n, u, d, block) in commodity__node__unit__direction__temporal_block()
                for t in keys(timesliceblocks[block])
    )
end

#=
function generate_variable_flow(m::Model)
    @butcher Dict{Tuple, JuMP.Variable}(
        (c, n, u, d, t) => @variable(
            m, basename="flow[$c, $n, $u, $d, $t]", lowerbound=0
        ) for (c, n, u, d, block) in commodity__node__unit__direction__temporal_block()
                for t in keys(time_slices_tempblock()[block])
    )
end
=#
