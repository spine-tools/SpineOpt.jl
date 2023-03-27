#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    add_variable!(m::Model, name::Symbol, indices::Function; <keyword arguments>)

Add a variable to `m`, with given `name` and indices given by interating over `indices()`.

# Arguments

  - `lb::Union{Function,Nothing}=nothing`: given an index, return the lower bound.
  - `ub::Union{Function,Nothing}=nothing`: given an index, return the upper bound.
  - `bin::Union{Function,Nothing}=nothing`: given an index, return whether or not the variable should be binary
  - `int::Union{Function,Nothing}=nothing`: given an index, return whether or not the variable should be integer
  - `fix_value::Union{Function,Nothing}=nothing`: given an index, return a fix value for the variable or nothing
  - `non_anticipativity_time::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity time or nothing
  - `non_anticipativity_margin::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity margin or nothing
"""
function add_variable!(
    m::Model,
    name::Symbol,
    indices::Function;
    bin::Union{Function,Nothing}=nothing,
    int::Union{Function,Nothing}=nothing,
    lb::Union{Constant,Parameter,Nothing}=nothing,
    ub::Union{Constant,Parameter,Nothing}=nothing,
    initial_value::Union{Parameter,Nothing}=nothing,
    fix_value::Union{Parameter,Nothing}=nothing,
    non_anticipativity_time::Union{Parameter,Nothing}=nothing,
    non_anticipativity_margin::Union{Parameter,Nothing}=nothing,
)
    m.ext[:spineopt].variables_definition[name] = Dict{Symbol,Union{Function,Parameter,Nothing}}(
        :indices => indices,
        :bin => bin,
        :int => int,
        :non_anticipativity_time => non_anticipativity_time,
        :non_anticipativity_margin => non_anticipativity_margin
    )
    last_history_t = last(history_time_slice(m))
    var = m.ext[:spineopt].variables[name] = Dict(
        ind => _variable(
            m, name, ind, bin, int, lb, ub, overlaps(ind.t, last_history_t) ? initial_value : nothing, fix_value
        )
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
    )
    merge!(var, _representative_periods_mapping(m, var, indices))
end

"""
    _representative_index(ind)

The representative index corresponding to the given one.
"""
function _representative_index(m, ind, indices)
    representative_t = representative_time_slice(m, ind.t)
    representative_inds = indices(m; ind..., t=representative_t)
    first(representative_inds)
end

"""
    _representative_periods_mapping(v::Dict{VariableRef}, indices::Function)

A `Dict` mapping non representative indices to the variable for the representative index.
"""
function _representative_periods_mapping(m::Model, var::Dict, indices::Function)
    # By default, `indices` skips represented time slices for operational variables other than node_state,
    # as well as for investment variables. This is done by setting the default value of the `temporal_block` argument
    # to `temporal_block(representative_periods_mapping=nothing)` - so any blocks that define a mapping are ignored.
    # To include represented time slices, we need to specify `temporal_block=anything`.
    # Note that for node_state and investment variables, `represented_indices`, below, will be empty.
    representative_indices = indices(m)
    all_indices = indices(m, temporal_block=anything)
    represented_indices = setdiff(all_indices, representative_indices)
    Dict(ind => var[_representative_index(m, ind, indices)] for ind in represented_indices)
end

"""
    _base_name(name, ind)

Create JuMP `base_name` from `name` and `ind`.
"""
_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

"""
    _variable(m, name, ind, lb, ub, bin, int)

Create a JuMP variable with the input properties.
"""
function _variable(m, name, ind, bin, int, lb, ub, initial_value, fix_value)
    var = @variable(m, base_name = _base_name(name, ind))
    bin !== nothing && bin(ind) && set_binary(var)
    int !== nothing && int(ind) && set_integer(var)
    initial_value_ = initial_value === nothing ? nothing : initial_value(; ind..., _strict=false)
    initial_value_ === nothing || fix(var, initial_value_)
    lb === nothing || set_lower_bound(var, lb[(; ind..., _strict=false)])
    ub === nothing || set_upper_bound(var, ub[(; ind..., _strict=false)])
    fix_value === nothing || fix(var, fix_value[(; ind..., _strict=false)])
    var
end
