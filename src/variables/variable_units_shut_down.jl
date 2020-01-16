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
    create_variable_units_shut_down!(m::Model)

"""
function create_variable_units_shut_down!(m::Model)
    KeyType = NamedTuple{(:unit, :t),Tuple{Object,TimeSlice}}
    units_shut_down = Dict{KeyType,Any}()
    for (u, t) in units_on_indices()
        units_shut_down[(unit=u, t=t)] = units_variable(m, u, "units_shut_down[$u, $(t.JuMP_name)]")
    end
    merge!(get!(m.ext[:variables], :units_shut_down, Dict{KeyType,Any}()), units_shut_down)
end