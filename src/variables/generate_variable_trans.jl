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
for each tuple returned by `connection__node()`, attached to model `m`.
`trans` represents a transfer over a 'connection' from a 'node'.
For each `connection` between to `nodes`, two `trans` variables exist.
"""
function generate_variable_trans(m::Model)
    @butcher Dict{Tuple, JuMP.Variable}(
        (c, n, conn, d, t) => @variable(
            m, basename="trans[$c, $n, $conn, $d, $t]", lowerbound=0
        ) for (c, n, conn, d) in commodity__node__connection__direction(), t=1:number_of_timesteps(time=:timer)
    )
end
