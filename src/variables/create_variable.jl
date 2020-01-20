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

function create_variable!(
        m::Model, name::Symbol, indices::Function; 
        lb=nothing, ub=nothing, bin=nothing, int=nothing
    )
    inds = indices()
    m.ext[:variables][name] = var = Dict{eltype(inds),Union{VariableRef,Float64}}()
    for ind in inds
        base_name = """$(name)[$(join(ind, ", "))]"""
        var[ind] = @variable(m, base_name=base_name)
        lb isa Function && set_lower_bound(var[ind], lb(ind))
        ub isa Function && set_upper_bound(var[ind], ub(ind))
        bin isa Function && bin(ind) && set_binary(var[ind])
        int isa Function && int(ind) && set_integer(var[ind])
        end_(ind.t) <= end_(current_window) || continue
        history_ind = (; ind..., t=t_history_t[ind.t])
        var[history_ind] = zero(Float64)
    end
end

function save_variable!(m::Model, name::Symbol, indices::Function)
    var = m.ext[:variables][name]
    for ind in indices()
        end_(ind.t) <= end_(current_window) || continue
        history_ind = (; ind..., t=t_history_t[ind.t])
        var[history_ind] = value(var[ind])
    end
end

function fix_variable!(m::Model, name::Symbol, indices::Function, fix_value::Function)
    var = m.ext[:variables][name]
    for ind in indices()
        fix_value_ = fix_value(ind)
        fix_value_ != nothing && fix(var[ind], fix_value_; force=true)
        end_(ind.t) <= end_(current_window) || continue
        history_ind = (; ind..., t=t_history_t[ind.t])
        fix_value_ = fix_value(history_ind)
        fix_value_ != nothing && (var[history_ind] = fix_value_)
    end
end

function create_variables!(m::Model)
    create_variable_flow!(m)
    create_variable_units_on!(m)
    create_variable_trans!(m)
    create_variable_stor_state!(m)
    create_variable_units_available!(m)
    create_variable_units_started_up!(m)
    create_variable_units_shut_down!(m)
end

function save_variables!(m::Model)
    save_variable_flow!(m)
    save_variable_units_on!(m)
    save_variable_trans!(m)
    save_variable_stor_state!(m)
    save_variable_units_available!(m)
    save_variable_units_started_up!(m)
    save_variable_units_shut_down!(m)
end

function fix_variables!(m::Model)
    fix_variable_flow!(m)
    fix_variable_units_on!(m)
    fix_variable_trans!(m)
    fix_variable_stor_state!(m)
end

