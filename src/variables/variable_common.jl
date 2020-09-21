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
        fix_value::Union{Function,Nothing}=nothing
    )
    m.ext[:variables_definition][name] = Dict{Symbol,Union{Function,Nothing}}(
        :indices => indices, :lb => lb, :ub => ub, :bin => bin, :int => int, :fix_value => fix_value
    )
    var = m.ext[:variables][name] = Dict(
        ind => _variable(m, name, ind, lb, ub, bin, int) for ind in indices(m)
    )
    history_var = Dict(
        history_ind => _variable(m, name, history_ind, lb, ub, bin, int)
        for ind in indices(m)
        if ind.t in keys(m.ext[:temporal_structure][:t_history_t])
        for history_ind in indices(m; ind..., stochastic_scenario=anything, t=t_history_t(m; t=ind.t))
    )
    merge!(var, history_var)
end

"""
    _base_name(name, ind)

Create JuMP `base_name` from `name` and `ind`.
"""
_base_name(name, ind) = """$(name)[$(join(ind, ", "))]"""

"""
    _variable(m, name, ind, lb, ub, bin, int)

Create a JuMP variable with the input properties.
"""
function _variable(m, name, ind, lb, ub, bin, int)
    var = @variable(m, base_name=_base_name(name, ind))
    lb != nothing && set_lower_bound(var, lb(ind))
    ub != nothing && set_upper_bound(var, ub(ind))
    bin != nothing && bin(ind) && set_binary(var)
    int != nothing && int(ind) && set_integer(var)
    var
end

