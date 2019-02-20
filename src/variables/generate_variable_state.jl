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
    generate_variable_state(m::Model)

A `state` variable for each tuple returned by `commodity__node()`,
attached to model `m`.
`state` represents the 'commodity' stored  inside a 'node'.
"""
function generate_variable_state(m::Model)
    Dict{Tuple, JuMP.Variable}(
        (c, n, t) => @variable(
            m, basename="state[$c, $n, $t]"
        ) for (c, n) in commodity__node(), t=1:number_of_timesteps(time=:timer)
    )
end
