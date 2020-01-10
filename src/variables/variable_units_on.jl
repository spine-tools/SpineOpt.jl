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
    var = Dict{KeyType,Any}()
    for (u, t) in var_units_on_indices()
        base_name = "units_on[$u, $(t.JuMP_name)]"
        var_type = online_variable_type(unit=u)
        var[(unit=u, t=t)] = if var_type == :binary_online_variable
            @variable(m, base_name=base_name, lower_bound=0, upper_bound=1, integer=true)
        elseif var_type == :integer_online_variable
            @variable(m, base_name=base_name, lower_bound=0, integer=true)
        else
            @variable(m, base_name=base_name, lower_bound=0)
        end
    end
    fix = Dict{KeyType,Any}(
        (unit=u, t=t) => fix_units_on(unit=u, t=t) for (u, t) in fix_units_on_indices()
    )
    merge!(get!(m.ext[:variables], :units_on, Dict{KeyType,Any}()), var, fix)
end

function variable_units_on_value(m::Model)
    Dict{NamedTuple{(:unit, :t),Tuple{Object,TimeSlice}},Any}(
        (unit=u, t=t) => value(m.ext[:variables][:units_on][u, t])
        for (u, t) in var_units_on_indices()
    )
end

"""
    units_on_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function units_on_indices(;unit=anything, t=anything)
    unique([var_units_on_indices(unit=unit, t=t); fix_units_on_indices(unit=unit, t=t)])
end

"""
    var_units_on_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to *non_fixed* indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function var_units_on_indices(;unit=anything, t=anything)
    [
        (unit=u, t=t_)
        for u in intersect(SpineModel.unit(), unit)
        for t_ in t_highest_resolution(unique(x.t for x in flow_indices(unit=u, t=t)))
        if fix_units_on(unit=u, t=t_, _strict=false) === nothing
    ]
end

"""
    fix_units_on_indices(unit=anything, t=anything)

A list of `NamedTuple`s corresponding to *fixed* indices of the `units_on` variable.
The keyword arguments act as filters for each dimension.
"""
function fix_units_on_indices(;unit=anything, t=anything, )
    unit = expand_unit_group(unit)
    [
        (unit=u, t=t_)
        for (u,) in indices(fix_units_on; unit=unit)
        for t_ in time_slice(t=t)
        if fix_units_on(unit=u, t=t_) != nothing
    ]
end
