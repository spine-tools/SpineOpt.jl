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

Generates transmissions `trans` for each existing tuple of [connection,node_i,node_j].
For each `connection` between to `nodes`, two `trans` variables exist.
"""
function generate_variable_trans(m::Model)
    @butcher Dict{Tuple, JuMP.Variable}(
        (c, i, t) => @variable(
            m, basename="trans[$c, $i, $t]"
        ) for (c, i) in connection__node(), t=1:number_of_timesteps(time="timer")
    )
end
