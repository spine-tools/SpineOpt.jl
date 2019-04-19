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
    @butcher Dict{Tuple,JuMP.VariableRef}(
        (conn, n, c, d, t) => @variable(
            m, base_name="trans[$conn, $n, $c, $d, $(t.JuMP_name)]", lower_bound=0
        ) for (conn, n, d, block) in connection__node__direction__temporal_block() for c in node__commodity(node=n)
                for t in time_slice(temporal_block=block)
    )
end
