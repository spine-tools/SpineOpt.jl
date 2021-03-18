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
- `fix_value::Union{Function,Nothing}=nothing`: given an index, return a fix value for the variable of nothing
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
)
    m.ext[:variables_definition][name] = Dict{Symbol,Union{Function,Nothing}}(
        :indices => indices,
        :lb => lb,
        :ub => ub,
        :bin => bin,
        :int => int,
        :fix_value => fix_value,
    )
    var =
        m.ext[:variables][name] = Dict(
            ind => _variable(m, name, ind, lb, ub, bin, int)
            for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
        )
    if !isempty(SpineOpt.indices(representative_periods_mapping))
        map_to_representative_periods!(m, m.ext[:variables][name], indices)
    end
    ((bin != nothing) || (int != nothing)) && push!(m.ext[:integer_variables], name)
end

"""
    map_to_representative_periods!(v::Dict{VariableRef}, indices_all::Function)

Extends variable Dictionary such that indexing by a non representative
time slice returns the variable with the corresponding representative
time slice.
"""
function map_to_representative_periods!(m::Model, var::Dict, var_indices::Function)
    @show "not here 1"
    for ind in setdiff(var_indices(m,temporal_block=anything),var_indices(m))
        # Get indices which aren't time slices
        # @show "not here 2"
        Keys = [k for k in keys(ind) if !(typeof(ind[k]) <: TimeSlice)]
        Values = [ind[k] for k in Keys]
        non_t_slice_ind = (; zip(Keys, Values)...) #this gets everything, but the timeslice index...
        # @show "not here 3"
        ind_rep = first(var_indices(m;non_t_slice_ind...,t=representative_time_slices(m)[to_time_slice(m,t=ind.t)]))
        var[ind] = var[ind_rep]
    end
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
    lb != nothing && set_lower_bound(var, lb(ind))
    ub != nothing && set_upper_bound(var, ub(ind))
    bin != nothing && bin(ind) && set_binary(var)
    int != nothing && int(ind) && set_integer(var)
    var
end
