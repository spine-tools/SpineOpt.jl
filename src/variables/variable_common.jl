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
        ind => _variable(m, name, ind, lb, ub, bin, int) for ind in indices()
    )
    history_var = Dict(
        history_ind => _variable(m, name, history_ind, lb, ub, bin, int)
        for history_ind in (
            (; ind..., t=t_history_t[ind.t]) for ind in indices() if end_(ind.t) <= end_(current_window)
        )
    )
    merge!(var, history_var)
end

_base_name(name, ind) = """$(name)[$(join(ind, ", "))]"""

function _variable(m, name, ind, lb, ub, bin, int)
    var = @variable(m, base_name=_base_name(name, ind))
    lb != nothing && set_lower_bound(var, lb(ind))
    ub != nothing && set_upper_bound(var, ub(ind))
    bin != nothing && bin(ind) && set_binary(var)
    int != nothing && int(ind) && set_integer(var)
    var
end

fix_variable!(m::Model, name::Symbol, indices::Function, fix_value::Nothing) = nothing

function fix_variable!(m::Model, name::Symbol, indices::Function, fix_value::Function)
    var = m.ext[:variables][name]
    for ind in indices()
        fix_value_ = fix_value(ind)
        fix_value_ != nothing && fix(var[ind], fix_value_; force=true)
        end_(ind.t) <= end_(current_window) || continue
        history_ind = (; ind..., t=t_history_t[ind.t])
        fix_value_ = fix_value(history_ind)
        fix_value_ != nothing && fix(var[history_ind], fix_value_; force=true)
    end
end

_value(v::VariableRef) = (is_integer(v) || is_binary(v)) ? round(Int, JuMP.value(v)) : JuMP.value(v)

function save_value!(m::Model, name::Symbol, indices::Function)
    inds = indices()
    var = m.ext[:variables][name]
    m.ext[:values][name] = Dict(
        ind => _value(var[ind]) for ind in indices() if end_(ind.t) <= end_(current_window)
    )
end

function update_variable!(m::Model, name::Symbol, indices::Function)
    var = m.ext[:variables][name]
    val = m.ext[:values][name]
    lb = m.ext[:variables_definition][name][:lb]
    ub = m.ext[:variables_definition][name][:ub]
    for ind in indices()
        set_name(var[ind], _base_name(name, ind))
        if is_fixed(var[ind])
            unfix(var[ind])
            lb != nothing && set_lower_bound(var[ind], lb(ind))
            ub != nothing && set_upper_bound(var[ind], ub(ind))
        end
        end_(ind.t) <= end_(current_window) || continue
        history_ind = (; ind..., t=t_history_t[ind.t])
        set_name(var[history_ind], _base_name(name, history_ind))
        fix(var[history_ind], val[ind]; force=true)
    end
end

function fix_variables!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        fix_variable!(m, name, definition[:indices], definition[:fix_value])
    end
end

function save_values!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        save_value!(m, name, definition[:indices])
    end
end

function update_variables!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        update_variable!(m, name, definition[:indices])
    end
end
