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
    generate_variable_stor_state(m::Model)

A `stor_level` variable for each tuple returned by `commodity__stor()`,
attached to model `m`.
`stor_level` represents the state of the storage level.
"""
function generate_variable_stor_state(m::Model)
    @butcher Dict{Tuple,JuMP.VariableRef}(
        (c, stor, t) => @variable(
            m, base_name="stor_state[$c, $stor, $(t.JuMP_name)]", lower_bound=0
        ) for (c, stor, block) in commodity__storage__temporal_block()
            for t in time_slice(temporal_block=block)
    )
end
