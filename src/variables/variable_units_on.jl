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
    generate_units_on(m::Model)

#TODO: add model descirption here
"""
function variable_units_on(m::Model)
    KeyType = NamedTuple{(:unit, :t),Tuple{Object,TimeSlice}}
    m.ext[:variables][:integer_units_on] = Dict{KeyType,Any}(
        (unit=u, t=t) => @variable(
            m, base_name="units_on[$u, $(t.JuMP_name)]", integer=true, lower_bound=0
        ) for (u, t) in var_units_on_indices() if online_variable_type(unit=u) == :integer_online_variable
    )
    m.ext[:variables][:binary_units_on] = Dict{KeyType,Any}(
        (unit=u, t=t) => @variable(
            m, base_name="units_on[$u, $(t.JuMP_name)]", binary=true
        ) for (u, t) in var_units_on_indices() if online_variable_type(unit=u) == :binary_online_variable
    )
    m.ext[:variables][:continuous_units_on] = Dict{KeyType,Any}(
        (unit=u, t=t) => @variable(
            m, base_name="units_on[$u, $(t.JuMP_name)]", lower_bound=0
        ) for (u, t) in var_units_on_indices() if online_variable_type(unit=u) == :continuous_online_variable
    )
    m.ext[:variables][:no_units_on] = Dict{KeyType,Any}(
        (unit=u, t=t) => @variable(
            m, base_name="units_on[$u, $(t.JuMP_name)]", lower_bound=1 , upper_bound=1
        ) for (u, t) in var_units_on_indices() if online_variable_type(unit=u) == :no_online_variable
    )
    m.ext[:variables][:fix_units_on] = Dict{KeyType,Any}(
        (unit=u, t=t) => fix_units_on(unit=u, t=t) for (u, t) in fix_units_on_indices()
    )
    m.ext[:variables][:units_on] = merge(
        m.ext[:variables][:integer_units_on],
        m.ext[:variables][:binary_units_on],
        m.ext[:variables][:continuous_units_on],
        m.ext[:variables][:no_units_on],
        m.ext[:variables][:fix_units_on]
    )
end


"""
    units_on_indices(filtering_options...)

A set of tuples for indexing the `units_on` variable. Any filtering options can be specified
for `unit` and `t`.
"""
function units_on_indices(;unit=anything, t=anything)
    unique([var_units_on_indices(unit=unit, t=t); fix_units_on_indices(unit=unit, t=t)])
end

function var_units_on_indices(;unit=anything, t=anything)
    [
        (unit=u, t=t1)
        for u in intersect(SpineModel.unit(), unit)
            for t1 in intersect(t_highest_resolution([x.t for x in flow_indices(unit=u)]), t)
    ]
end

function fix_units_on_indices(;unit=anything, t=anything)
    [
        (unit=u, t=t1)
        for (u,) in indices(fix_units_on; unit=unit) if fix_units_on(unit=u) isa TimeSeriesValue
            for t1 in intersect(
                    t_highest_resolution(
                        overlap(
                            time_slice,
                            time_stamps(fix_units_on(unit=u))...
                        )
                    ),
                    t
                )
    ]
end
