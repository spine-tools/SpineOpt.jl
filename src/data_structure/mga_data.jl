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

function set_objective_mga_iteration!(m;iteration=nothing, mga_alpha=nothing)
    instance = m.ext[:instance]
    if !mga_diff_relative(model=instance) #FIXME: define also for relative diffs in the future
        _set_objective_mga_iteration!(
            m,
            :units_invested,
            units_invested_available_indices,
            unit_stochastic_scenario_weight,
            units_invested_mga_indices,
            units_invested_mga_scaling_factor,
            use_unit_capacity_for_mga_scaling,
            unit_capacity,
            units_invested_big_m_mga,
            iteration,
        )
        _set_objective_mga_iteration!(
            m,
            :connections_invested,
            connections_invested_available_indices,
            connection_stochastic_scenario_weight,
            connections_invested_mga_indices,
            connections_invested_mga_scaling_factor,
            use_connection_capacity_for_mga_scaling,
            connection_capacity,
            connections_invested_big_m_mga,
            iteration,
        )
        _set_objective_mga_iteration!(
            m,
            :storages_invested,
            storages_invested_available_indices,
            node_stochastic_scenario_weight,
            storages_invested_mga_indices,
            storages_invested_mga_scaling_factor,
            use_storage_capacity_for_mga_scaling,
            node_state_cap,
            storages_invested_big_m_mga,
            iteration,
        )
        @fetch mga_aux_diff, mga_objective = m.ext[:variables]
        ub_objective = get!(m.ext[:constraints],:mga_objective_ub,Dict())
        if !isnothing(mga_alpha)
            for ind in vcat(
                [storages_invested_mga_indices(iteration)...,
                connections_invested_mga_indices(iteration)...,
                units_invested_mga_indices(iteration)...,
                ]
                )
                ind_mga_alpha = collect(indices(mga_alpha_step_length))[1]
                @show ind_mga_alpha,ind
                if ind_mga_alpha == ind[1]
                    @show mga_alpha
                else
                    @show (1-mga_alpha)
                    @show "multiplier otherwise"
                end
            end
            ind_mga_alpha = collect(indices(mga_alpha_step_length))[1]#find mga_alpha #TODO add parameter!!!
            ub_objective[iteration] = @constraint(
                    m,
                    mga_objective[(model = m.ext[:instance],t=current_window(m))]
                    <= sum(
                    mga_aux_diff[((ind...,mga_iteration=iteration))]
                    *(ind[1] == ind_mga_alpha ? mga_alpha : (1-mga_alpha))
                    for ind in vcat(
                        [storages_invested_mga_indices(iteration)...,
                        connections_invested_mga_indices(iteration)...,
                        units_invested_mga_indices(iteration)...,
                        ]
                        )
                    )

            )
        else
            ub_objective[iteration] = @constraint(
                    m,
                    mga_objective[(model = m.ext[:instance],t=current_window(m))]
                    <= sum(
                    mga_aux_diff[((ind...,mga_iteration=iteration))]
                    for ind in vcat(
                        [storages_invested_mga_indices(iteration)...,
                        connections_invested_mga_indices(iteration)...,
                        units_invested_mga_indices(iteration)...,
                        ]
                        )
                    )
            )
        end
        for (con_key, cons) in m.ext[:constraints]
            for (inds, con) in cons
                set_name(con, string(con_key, inds))
            end
        end
    end
end

function _set_objective_mga_iteration!(
        m::Model,
        variable_name::Symbol,
        variable_indices_function::Function,
        scenario_weight_function::Function,
        mga_indices::Function,
        mga_scaling_function::Parameter,
        use_obj_capacity_for_scaling::Parameter,
        obj_capacity::Parameter,
        mga_variable_bigM::Parameter,
        mga_current_iteration::Object,
        )
        if !isempty(mga_indices())
            t0 = _analysis_time(m).ref.x
            mga_results = m.ext[:outputs]
            d_aux = get!(m.ext[:variables], :mga_aux_diff, Dict())
            d_bin = get!(m.ext[:variables],:mga_aux_binary, Dict())
            for ind in mga_indices(mga_current_iteration)
                d_aux[ind] = @variable(m, base_name = _base_name(:mga_aux_diff,ind), lower_bound = 0)
                d_bin[ind] = @variable(m, base_name = _base_name(:mga_aux_binary,ind), binary=true)
            end
            @fetch mga_aux_diff, mga_aux_binary = m.ext[:variables]
            mga_results = m.ext[:outputs]
            variable = m.ext[:variables][variable_name]
            #FIXME: don't create new dict everytime, but get existing one
            d_diff_ub1 = get!(m.ext[:constraints],:mga_diff_ub1,Dict())
            d_diff_ub2 = get!(m.ext[:constraints],:mga_diff_ub2,Dict())
            d_diff_lb1 = get!(m.ext[:constraints],:mga_diff_lb1,Dict())
            d_diff_lb2 = get!(m.ext[:constraints],:mga_diff_lb2,Dict())
            for ind in mga_indices()
                d_diff_ub1[(ind...,mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    <=
                    (
                        sum(
                        + (
                        variable[_ind]
                         - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x]
                         )
                         * reduce(*,
                             (typeof(ind_cap) == Object ? obj_capacity[NamedTuple{(ind_cap.class_name,)}(ind_cap)] : obj_capacity[(ind_cap)])
                             for ind_cap in indices(obj_capacity; _ind ...)
                                 if realize(use_obj_capacity_for_scaling[(typeof(ind_cap) == Object ? NamedTuple{(ind_cap.class_name,)}(ind_cap) : (ind_cap))]) == true
                             ;init=1
                         )
                         * scenario_weight_function(m; _drop_key(_ind,:t)...) #fix me, can also be only node or so
                         for _ind in variable_indices_function(m; ind...)
                       )
                       + mga_variable_bigM(;ind...)
                       *mga_aux_binary[(ind...,mga_iteration=mga_current_iteration)])
                       * mga_scaling_function(;ind...))
                d_diff_ub2[(ind...,mga_current_iteration...)]= @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    <=
                    (
                        sum(
                        - (variable[_ind]
                          - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x])
                          * reduce(*,
                              (typeof(ind_cap) == Object ? obj_capacity[NamedTuple{(ind_cap.class_name,)}(ind_cap)] : obj_capacity[(ind_cap)])
                              for ind_cap in indices(obj_capacity; _ind ...)
                                  if realize(use_obj_capacity_for_scaling[(typeof(ind_cap) == Object ? NamedTuple{(ind_cap.class_name,)}(ind_cap) : (ind_cap))]) == true
                              ;init=1
                          )
                          * scenario_weight_function(m; _drop_key(_ind,:t)...)
                          for _ind in variable_indices_function(m; ind...)
                       )
                  + mga_variable_bigM(;ind...)
                  *(1-mga_aux_binary[(ind...,mga_iteration=mga_current_iteration)]))
                  * mga_scaling_function(;ind...))
                  d_diff_lb1[(ind...,mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    >=
                    sum(
                    (variable[_ind]
                      - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x])
                      * reduce(*,
                          (typeof(ind_cap) == Object ? obj_capacity[NamedTuple{(ind_cap.class_name,)}(ind_cap)] : obj_capacity[(ind_cap)])
                          for ind_cap in indices(obj_capacity; _ind ...)
                              if realize(use_obj_capacity_for_scaling[(typeof(ind_cap) == Object ? NamedTuple{(ind_cap.class_name,)}(ind_cap) : (ind_cap))]) == true
                          ;init=1
                      )
                      * scenario_weight_function(m; _drop_key(_ind,:t)...)
                       for _ind in variable_indices_function(m; ind...)
                   )
                   * mga_scaling_function(;ind...)
                   )
                   d_diff_lb2[(ind...,mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    >=
                    sum(
                    - (variable[_ind]
                      - mga_results[variable_name][(_drop_key(_ind,:t)..., mga_iteration=mga_current_iteration)][t0][_ind.t.start.x])
                      * reduce(*,
                          (typeof(ind_cap) == Object ? obj_capacity[NamedTuple{(ind_cap.class_name,)}(ind_cap)] : obj_capacity[(ind_cap)])
                          for ind_cap in indices(obj_capacity; _ind ...)
                              if realize(use_obj_capacity_for_scaling[(typeof(ind_cap) == Object ? NamedTuple{(ind_cap.class_name,)}(ind_cap) : (ind_cap))]) == true
                          ;init=1
                      )
                      * scenario_weight_function(m; _drop_key(_ind,:t)...)
                       for _ind in variable_indices_function(m; ind...)
                   )
                    * mga_scaling_function(;ind...)
                   )
               end
        end
end

function add_mga_objective_constraint!(m::Model)
    instance = m.ext[:instance]
    m.ext[:constraints][:mga_slack_constraint] = Dict(m.ext[:instance] =>
        @constraint(m, total_costs(m, maximum(end_.(time_slice(m)))) <= (1+max_mga_slack(model=instance)) * objective_value_mga(model=instance))
        )
end

function save_mga_objective_values!(m::Model)
    ind = (model=m.ext[:instance], t=current_window(m))
    for name in [:mga_objective,]#:mga_aux_diff]
        for ind in keys(m.ext[:variables][name])
            m.ext[:values][name] = Dict(ind => value(m.ext[:variables][name][ind]))
        end
    end
end

function set_mga_objective!(m)
    m.ext[:variables][:mga_objective] = Dict(
               (model = m.ext[:instance],t=current_window(m)) => @variable(m, base_name = _base_name(:mga_objective,(model = m.ext[:instance],t=current_window(m))), lower_bound=0)
               )
    @objective(m,
            Max,
            m.ext[:variables][:mga_objective][(model = m.ext[:instance],t=current_window(m))]
            )
end
