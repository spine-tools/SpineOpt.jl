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
    create_variable_units_on!(m::Model)

Add `units_on` variable for model `m`.

This variable represents the number of online units for a given *unit*
within a certain *time slice*.
"""
function create_variable_units_on!(m::Model)
    KeyType = NamedTuple{(:unit, :t),Tuple{Object,TimeSlice}}
    units_on = Dict{KeyType,Any}()
    for (u, t) in units_on_indices()
        fix_units_on_ = fix_units_on(unit=u, t=t)
        units_on[(unit=u, t=t)] = if fix_units_on_ != nothing
            fix_units_on_
        else
            units_variable(m, u, "units_on[$u, $(t.JuMP_name)]")
        end
    end
    merge!(get!(m.ext[:variables], :units_on, Dict{KeyType,Any}()), units_on)
end

"""
    units_on_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function units_on_indices(;unit=anything, t=anything)
    [
        (unit=u, t=t_)
        for u in intersect(SpineModel.unit(), unit)
        for t_ in t_highest_resolution(unique(x.t for x in flow_indices(unit=u, t=t)))
    ]
end

function units_variable(m, u, base_name)
    var_type = online_variable_type(unit=u)
    if var_type == :none
        @variable(m, base_name=base_name, lower_bound=1, upper_bound=1)
    elseif var_type == :binary
        @variable(m, base_name=base_name, lower_bound=0, binary=true)
    elseif var_type == :integer
        @variable(m, base_name=base_name, lower_bound=0, integer=true)
    else
        @variable(m, base_name=base_name, lower_bound=0)
    end
end




