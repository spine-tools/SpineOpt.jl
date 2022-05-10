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
"""
function add_variable!(
    m::Model,
    name::Symbol,
    indices::Function;
    lb::Union{Function,Nothing}=nothing,
    ub::Union{Function,Nothing}=nothing,
    bin::Union{Function,Nothing}=nothing,
    int::Union{Function,Nothing}=nothing,
    fix_value::Union{Function,Nothing}=nothing,
    non_anticipativity_time::Union{Function,Nothing}=nothing,
)
    m.ext[:variables_definition][name] = Dict{Symbol,Union{Function,Nothing}}(
        :indices => indices,
        :lb => lb,
        :ub => ub,
        :bin => bin,
        :int => int,
        :fix_value => fix_value,
        :non_anticipativity_time => non_anticipativity_time,
    )
    var = m.ext[:variables][name] = Dict(
        ind => _variable(m, name, ind, lb, ub, bin, int)
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
    )
    merge!(var, _representative_periods_mapping(m, var, indices))
    ((bin != nothing) || (int != nothing)) && push!(m.ext[:integer_variables], name)
end

"""
    _rep_ind(ind)

The representative index corresponding to the given one.
"""
function _rep_ind(m, ind, indices)
    rep_t = representative_time_slice(m, ind.t)
    rep_inds = indices(m; ind..., t=rep_t)
    first(rep_inds)
end

"""
    _representative_periods_mapping(v::Dict{VariableRef}, indices::Function)

A `Dict` mapping non representative indices to the variable for the representative index.
"""
function _representative_periods_mapping(m::Model, var::Dict, indices::Function)
    # By default, `indices` skips non-representative time slices for operational variables other than node_state,
    # as well as for investment variables. This is done by setting the default value of the `temporal_block` argument
    # to `temporal_block(representative_periods_mapping=nothing)` - so any block that define a mapping is ignored.
    # To include non-representative time slices, we need to specify `temporal_block=anything`.
    # Note that for node_state and investment variables, `non_rep_indices`, below, will be empty.
    rep_indices = indices(m)
    all_indices = indices(m, temporal_block=anything)
    non_rep_indices = setdiff(all_indices, rep_indices)
    Dict(ind => var[_rep_ind(m, ind, indices)] for ind in non_rep_indices)
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
function _variable(m, name, ind, lb, ub, bin, int)
    var = @variable(m, base_name = _base_name(name, ind))
    lb != nothing && _set_lower_bound(var, lb(ind))
    ub != nothing && _set_upper_bound(var, ub(ind))
    bin != nothing && bin(ind) && set_binary(var)
    int != nothing && int(ind) && set_integer(var)
    var
end

_set_lower_bound(var, ::Nothing) = nothing
_set_lower_bound(var, lb) = set_lower_bound(var, lb)

_set_upper_bound(var, ::Nothing) = nothing
_set_upper_bound(var, lb) = set_upper_bound(var, lb)