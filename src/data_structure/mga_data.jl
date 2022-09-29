#############################################################################
# Copyright (C) 2017 - 2021  Spine Project
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

function units_invested_mga_indices()
    unique(
        [
        (unit=ug,)
        for ug in unit(units_invested_mga=true)])
end

function units_invested_mga_indices(mga_iteration)
    unique(
        [
        (unit=ug, mga_iteration=mga_it)
        for ug in unit(units_invested_mga=true)
            for mga_it in mga_iteration])
end

function connections_invested_mga_indices()
    unique(
        [
        (connection=cg,)
        for cg in connection(connections_invested_mga=true)])
end

function connections_invested_mga_indices(mga_iteration)
    unique(
        [
        (connection=cg, mga_iteration=mga_it)
        for cg in connection(connections_invested_mga=true)
            for mga_it in mga_iteration])
end

function storages_invested_mga_indices()
    unique(
        [
        (node=ng, )
        for ng in node(storages_invested_mga=true)])
end

function storages_invested_mga_indices(mga_iteration)
    unique(
        [
        (node=ng, mga_iteration=mga_it)
        for ng in node(storages_invested_mga=true)
            for mga_it in mga_iteration])
end

function set_objective_mga_iteration!(m;iteration=nothing,iterations_num=0)
    instance = m.ext[:spineopt].instance
    _set_objective_mga_iteration!(
        m,
        :units_invested,
        units_invested_available_indices,
        unit_stochastic_scenario_weight,
        units_invested_mga_indices,
        units_invested_mga_weight,
        units_invested_big_m_mga,
        iteration,
        iterations_num
    )
    _set_objective_mga_iteration!(
        m,
        :connections_invested,
        connections_invested_available_indices,
        connection_stochastic_scenario_weight,
        connections_invested_mga_indices,
        connections_invested_mga_weight,
        connections_invested_big_m_mga,
        iteration,
        iterations_num
    )
    _set_objective_mga_iteration!(
        m,
        :storages_invested,
        storages_invested_available_indices,
        node_stochastic_scenario_weight,
        storages_invested_mga_indices,
        storages_invested_mga_weight,
        storages_invested_big_m_mga,
        iteration,
        iterations_num
    )
    @fetch mga_aux_diff, mga_objective = m.ext[:spineopt].variables
    ub_objective = get!(m.ext[:spineopt].constraints,:mga_objective_ub,Dict())
    ub_objective[(model=m.ext[:spineopt].instance,)] = @constraint(
            m,
            mga_objective[(model = m.ext[:spineopt].instance,t=current_window(m))]
            <= sum(
            mga_aux_diff[ind]
            for ind in vcat(
                [storages_invested_mga_indices(iteration)...,
                connections_invested_mga_indices(iteration)...,
                units_invested_mga_indices(iteration)...]
                )
            )
    )
    _update_constraint_names!(m)
end

function _set_objective_mga_iteration!(
        m::Model,
        variable_name::Symbol,
        variable_indices_function::Function,
        scenario_weight_function::Function,
        mga_indices::Function,
        mga_weight_iteration::Parameter,
        mga_variable_bigM::Parameter,
        mga_current_iteration::Object,
        iterations_num::Int64,
        )
        if !isempty(mga_indices())
            weighted_investments = isempty(indices(connections_invested_big_m_mga)) && isempty(indices(units_invested_big_m_mga)) && isempty(indices(storages_invested_big_m_mga))
            t0 = _analysis_time(m).ref.x
            @fetch units_invested = m.ext[:spineopt].variables
            mga_results = m.ext[:spineopt].outputs
            d_aux = get!(m.ext[:spineopt].variables, :mga_aux_diff, Dict())
            d_bin = get!(m.ext[:spineopt].variables,:mga_aux_binary, Dict())
            for ind in mga_indices(mga_current_iteration)
                if weighted_investments
                    d_aux[ind] = @variable(m, base_name = _base_name(:mga_aux_diff,ind))
                else
                    d_aux[ind] = @variable(m, base_name = _base_name(:mga_aux_diff,ind), lower_bound = 0)
                    d_bin[ind] = @variable(m, base_name = _base_name(:mga_aux_binary,ind), binary=true)
                end
            end
            @fetch mga_aux_diff, mga_aux_binary = m.ext[:spineopt].variables
            mga_results = m.ext[:spineopt].outputs
            variable = m.ext[:spineopt].variables[variable_name]
            #FIXME: don't create new dict everytime, but get existing one
            d_diff_ub1 = get!(m.ext[:spineopt].constraints,:mga_diff_ub1,Dict())
            d_diff_ub2 = get!(m.ext[:spineopt].constraints,:mga_diff_ub2,Dict())
            d_diff_lb1 = get!(m.ext[:spineopt].constraints,:mga_diff_lb1,Dict())
            d_diff_lb2 = get!(m.ext[:spineopt].constraints,:mga_diff_lb2,Dict())
            if weighted_investments
                for ind in mga_indices()
                    for _ind in variable_indices_function(m; ind...)
                    end
                    d_diff_ub1[(ind...,mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    ==
                    (
                        sum(
                        + variable[_ind]
                         * scenario_weight_function(m; _drop_key(_ind,:t)...)
                         for _ind in variable_indices_function(m; ind...)
                         )
                       )
                       * mga_weight_iteration(;ind...,i=iterations_num)
                       )
                       #TODO: add scaling factor to template
               end
            else
                for ind in mga_indices()
                #TODO: ADD mga_scaling factor
                    d_diff_ub1[(ind...,mga_current_iteration...)] = @constraint(
                        m,
                        mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                        <=
                        sum(
                        + (
                        variable[_ind]
                         - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x]
                         )
                         * scenario_weight_function(m; _drop_key(_ind,:t)...) #fix me, can also be only node or so
                         for _ind in variable_indices_function(m; ind...)
                       ) * mga_weight_iteration(;ind...)
                       + mga_variable_bigM(;ind...)*mga_aux_binary[(ind...,mga_iteration=mga_current_iteration)])
                    d_diff_ub2[(ind...,mga_current_iteration...)]= @constraint(
                        m,
                        mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                        <=
                        sum(
                        - (variable[_ind]
                          - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x])
                          * scenario_weight_function(m; _drop_key(_ind,:t)...)
                          for _ind in variable_indices_function(m; ind...)
                       ) * mga_weight_iteration(;ind...)
                      + mga_variable_bigM(;ind...)*(1-mga_aux_binary[(ind...,mga_iteration=mga_current_iteration)])
                      )
                      d_diff_lb1[(ind...,mga_current_iteration...)] = @constraint(
                        m,
                        mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                        >=
                        sum(
                        (variable[_ind]
                          - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x])
                          * scenario_weight_function(m; _drop_key(_ind,:t)...)
                           for _ind in variable_indices_function(m; ind...)
                       ) * mga_weight_iteration(;ind...)
                       )
                       d_diff_lb2[(ind...,mga_current_iteration...)] = @constraint(
                        m,
                        mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                        >=
                        sum(
                        - (variable[_ind]
                          - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x])
                          * scenario_weight_function(m; _drop_key(_ind,:t)...)
                           for _ind in variable_indices_function(m; ind...)
                       ) * mga_weight_iteration(;ind...)
                       )
               end
           end
        end
end

function add_mga_objective_constraint!(m::Model)
    instance = m.ext[:spineopt].instance
    m.ext[:spineopt].constraints[:mga_slack_constraint] = Dict((model=m.ext[:spineopt].instance,) =>
        @constraint(m, total_costs(m, end_(last(time_slice(m)))) <= (1+max_mga_slack(model=instance)) * objective_value_mga(model=instance))
        )
end

function save_mga_objective_values!(m::Model)
    ind = (model=m.ext[:spineopt].instance, t=current_window(m))
    for name in [:mga_objective,]#:mga_aux_diff]
        for ind in keys(m.ext[:spineopt].variables[name])
            m.ext[:spineopt].values[name] = Dict(ind => value(m.ext[:spineopt].variables[name][ind]))
        end
    end
end

function set_mga_objective!(m)
    weighted_investments = isempty(indices(connections_invested_big_m_mga)) && isempty(indices(units_invested_big_m_mga)) && isempty(indices(storages_invested_big_m_mga))
    m.ext[:spineopt].variables[:mga_objective] = Dict(
               (model = m.ext[:spineopt].instance,t=current_window(m)) =>
               @variable(
                m, base_name = _base_name(:mga_objective,(model = m.ext[:spineopt].instance,t=current_window(m))), lower_bound= (weighted_investments ? Inf : 0))
               )
    @objective(m,
            Max,
            m.ext[:spineopt].variables[:mga_objective][(model = m.ext[:spineopt].instance,t=current_window(m))]
            )
end
