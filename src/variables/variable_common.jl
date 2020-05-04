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

_base_name(name, ind) = """$(name)[$(join(ind, ", "))]"""

function _variable(m, name, ind, lb, ub, bin, int)
    var = @variable(m, base_name=_base_name(name, ind))
    lb != nothing && set_lower_bound(var, lb(ind))
    ub != nothing && set_upper_bound(var, ub(ind))
    bin != nothing && bin(ind) && set_binary(var)
    int != nothing && int(ind) && set_integer(var)
    var
end

function create_variable!(
        m::Model, name::Symbol, indices::Function;
        lb=nothing, ub=nothing, bin=nothing, int=nothing
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
    m.ext[:variables_ub][name] = ub
    m.ext[:variables_lb][name] = lb
end

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
    val = m.ext[:values][name] = Dict{eltype(inds),Number}()
    for ind in inds
        end_(ind.t) <= end_(current_window) || continue
        val[ind] = _value(var[ind])
    end
end

function update_variable!(m::Model, name::Symbol, indices::Function)
    var = m.ext[:variables][name]
    val = m.ext[:values][name]
    lb = m.ext[:variables_lb][name]
    ub = m.ext[:variables_ub][name]
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

function create_variables!(m::Model)
    create_variable_unit_flow!(m)
    create_variable_unit_flow_op!(m)
    create_variable_units_on!(m)
    create_variable_connection_flow!(m)
    create_variable_node_state!(m)
    create_variable_node_injection!(m)
    create_variable_node_slack_pos!(m)
    create_variable_node_slack_neg!(m)
    create_variable_units_available!(m)
    create_variable_units_started_up!(m)
    create_variable_units_shut_down!(m)
end

function fix_variables!(m::Model)
    fix_variable_unit_flow!(m)
    fix_variable_unit_flow_op!(m)
    fix_variable_units_on!(m)
    fix_variable_connection_flow!(m)
    fix_variable_node_state!(m)
end

function save_values!(m::Model)
    save_value!(m, :unit_flow, unit_flow_indices)
    save_value!(m, :unit_flow_op, unit_flow_op_indices)
    save_value!(m, :connection_flow, connection_flow_indices)
    save_value!(m, :node_state, node_state_indices)
    save_value!(m, :units_on, units_on_indices)
    save_value!(m, :units_available, units_on_indices)
    save_value!(m, :units_started_up, units_on_indices)
    save_value!(m, :units_shut_down, units_on_indices)
    save_value!(m, :node_slack_pos, node_slack_indices)
    save_value!(m, :node_slack_neg, node_slack_indices)
end

function update_variables!(m::Model)
    update_variable!(m, :unit_flow, unit_flow_indices)
    update_variable!(m, :unit_flow_op, unit_flow_op_indices)
    update_variable!(m, :connection_flow, connection_flow_indices)
    update_variable!(m, :node_state, node_state_indices)
    update_variable!(m, :units_on, units_on_indices)
    update_variable!(m, :units_available, units_on_indices)
    update_variable!(m, :units_started_up, units_on_indices)
    update_variable!(m, :units_shut_down, units_on_indices)
    update_variable!(m, :node_slack_pos, node_slack_indices)
    update_variable!(m, :node_slack_neg, node_slack_indices)
    update_variable!(m, :node_injection, node_injection_indices)
end
