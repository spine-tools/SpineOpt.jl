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
    units_shutting_down(m::Model)

#TODO: add model descirption here
"""
function variable_units_shutting_down(m::Model)
    Dict{NamedTuple,JuMP.VariableRef}(
        i => @variable(
            m,
            base_name="units_shutting_down[$(join(i, ", "))]", # TODO: JuMP_name (maybe use Base.show(..., ::TimeSlice))
            integer=true,
            lower_bound=0
        ) for i in units_online_indices()
    )
end
