#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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

"Optimizer bridges are required for MGA algorithm to form inequality constraints"
needs_bridges(::Val{:mga_algorithm}) = true

function do_run_spineopt!(
    m,
    url_out,
    ::Val{:mga_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    outputs = Dict()
    mga_iteration_count = 0
    max_mga_iters = max_mga_iterations(model=m.ext[:spineopt].instance)
    mga_iteration = ObjectClass(:mga_iteration, [])
    @eval mga_iteration = $mga_iteration
    build_model!(m; log_level)
    solve_model!(
        m;
        log_level=log_level,
        update_names=update_names,
        output_suffix=_add_mga_iteration(mga_iteration_count),
    )
    mga_iteration_count += 1
    add_mga_objective_constraint!(m)
    set_mga_objective!(m)
    # TODO: max_mga_iters can be different now
    if isnothing(max_mga_iters)
        u_max = if !isempty(indices(units_invested_mga_weight))
            maximum(length(units_invested_mga_weight(unit=u)) for u in indices(units_invested_mga_weight))
        else
            0
        end
        c_max = if !isempty(indices(connections_invested_mga_weight))
            maximum(
                length(connections_invested_mga_weight(connection=c)) for c in indices(connections_invested_mga_weight)
            )
        else
            0
        end
        s_max = if !isempty(indices(storages_invested_mga_weight))
            maximum(length(storages_invested_mga_weight(node=s)) for s in indices(storages_invested_mga_weight))
        else
            0
        end
        max_mga_iters = maximum([u_max, s_max, c_max])
    end
    while mga_iteration_count <= max_mga_iters
        # TODO: set_objective_mga_iteration is different now
        set_objective_mga_iteration!(m; iteration=last(mga_iteration()), iteration_number=mga_iteration_count)
        solve_model!(
            m;
            log_level=log_level,
            update_names=update_names,
            output_suffix=_add_mga_iteration(mga_iteration_count),
        ) || break
        save_mga_objective_values!(m)
        # TODO: needs to clean outputs?
        if (
            isempty(indices(connections_invested_big_m_mga))
            && isempty(indices(units_invested_big_m_mga))
            && isempty(indices(storages_invested_big_m_mga))
            && mga_iteration_count < max_mga_iters
        )
            for name in (:mga_objective_ub, :mga_diff_ub1)
                for con in values(m.ext[:spineopt].constraints[name])
                    try
                        delete(m, con)
                    catch
                    end
                end
            end
        end
        # TODO: needs to clean constraint (or simply clean within function)
        mga_iteration_count += 1
    end
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
end

function _add_mga_iteration(k)
    new_mga_name = Symbol(:mga_it_, k)
    new_mga_i = Object(new_mga_name, :mga_iteration)
    add_object!(mga_iteration, new_mga_i)
    (mga_iteration=mga_iteration(new_mga_name),)
end

function units_invested_mga_indices()
    unique((unit=ug,) for ug in unit(units_invested_mga=true))
end

function units_invested_mga_indices(mga_iteration)
    unique((unit=ug, mga_iteration=mga_it) for ug in unit(units_invested_mga=true) for mga_it in mga_iteration)
end

function connections_invested_mga_indices()
    unique((connection=cg,) for cg in connection(connections_invested_mga=true))
end

function connections_invested_mga_indices(mga_iteration)
    unique(
        (connection=cg, mga_iteration=mga_it)
        for cg in connection(connections_invested_mga=true)
        for mga_it in mga_iteration
    )
end

function storages_invested_mga_indices()
    unique((node=ng,) for ng in node(storages_invested_mga=true))
end

function storages_invested_mga_indices(mga_iteration)
    unique(
        (node=ng, mga_iteration=mga_it)
        for ng in node(storages_invested_mga=true)
        for mga_it in mga_iteration
    )
end

function set_objective_mga_iteration!(m; iteration=nothing, iteration_number=0)
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
        iteration_number
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
        iteration_number
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
        iteration_number
    )
    @fetch mga_aux_diff, mga_objective = m.ext[:spineopt].variables
    ub_objective = get!(m.ext[:spineopt].constraints, :mga_objective_ub, Dict())
    ub_objective[(model=m.ext[:spineopt].instance,)] = @constraint(
        m,
        mga_objective[(model = m.ext[:spineopt].instance, t=current_window(m))]
        <= sum(
            mga_aux_diff[ind]
            for ind in vcat(
                storages_invested_mga_indices(iteration),
                connections_invested_mga_indices(iteration),
                units_invested_mga_indices(iteration)
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
    iteration_number::Int64,
)
    if !isempty(mga_indices())
        weighted_investments = all(
            [
                isempty(indices(connections_invested_big_m_mga)),
                isempty(indices(units_invested_big_m_mga)),
                isempty(indices(storages_invested_big_m_mga))
            ]
        )
        t0 = start(current_window(m))
        @fetch units_invested = m.ext[:spineopt].variables
        d_aux = get!(m.ext[:spineopt].variables, :mga_aux_diff, Dict())
        d_bin = get!(m.ext[:spineopt].variables, :mga_aux_binary, Dict())
        for ind in mga_indices(mga_current_iteration)
            if weighted_investments
                d_aux[ind] = @variable(m, base_name=_base_name(:mga_aux_diff, ind))
            else
                d_aux[ind] = @variable(m, base_name=_base_name(:mga_aux_diff, ind), lower_bound=0)
                d_bin[ind] = @variable(m, base_name=_base_name(:mga_aux_binary, ind), binary=true)
            end
        end
        @fetch mga_aux_diff, mga_aux_binary = m.ext[:spineopt].variables
        variable = m.ext[:spineopt].variables[variable_name]
        d_diff_ub1 = get!(m.ext[:spineopt].constraints, :mga_diff_ub1, Dict())
        d_diff_ub2 = get!(m.ext[:spineopt].constraints, :mga_diff_ub2, Dict())
        d_diff_lb1 = get!(m.ext[:spineopt].constraints, :mga_diff_lb1, Dict())
        d_diff_lb2 = get!(m.ext[:spineopt].constraints, :mga_diff_lb2, Dict())
        if weighted_investments
            for ind in mga_indices()
                # for ind_ in variable_indices_function(m; ind...) end  # ???!!!
                d_diff_ub1[(ind..., mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[(ind..., mga_iteration=mga_current_iteration)]
                    ==
                    (
                        sum(
                            variable[ind_] * scenario_weight_function(m; _drop_key(ind_, :t)...)
                            for ind_ in variable_indices_function(m; ind...)
                        )
                    )
                    * mga_weight_iteration(; ind..., i=iteration_number)
                )
                # TODO: add scaling factor to template
            end
        else
            for ind in mga_indices()
                # TODO: ADD mga_scaling factor
                d_diff_ub1[(ind..., mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[(ind..., mga_iteration=mga_current_iteration)]
                    <=
                    sum(
                        (variable[ind_] - _mga_result(m, variable_name, ind_, mga_current_iteration))
                        * scenario_weight_function(m; _drop_key(ind_, :t)...) # FIXME: can also be only node or so
                        for ind_ in variable_indices_function(m; ind...)
                    )
                    * mga_weight_iteration(; ind...)
                    + mga_variable_bigM(; ind...) * mga_aux_binary[(ind..., mga_iteration=mga_current_iteration)]
                )
                d_diff_ub2[(ind..., mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[(ind..., mga_iteration=mga_current_iteration)]
                    <=
                    sum(
                        (_mga_result(m, variable_name, ind_, mga_current_iteration) - variable[ind_])
                        * scenario_weight_function(m; _drop_key(ind_, :t)...)
                        for ind_ in variable_indices_function(m; ind...)
                    )
                    * mga_weight_iteration(; ind...)
                    + mga_variable_bigM(; ind...) * (1 - mga_aux_binary[(ind..., mga_iteration=mga_current_iteration)])
                )
                d_diff_lb1[(ind..., mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[(ind..., mga_iteration=mga_current_iteration)]
                    >=
                    sum(
                        (variable[ind_] - _mga_result(m, variable_name, ind_, mga_current_iteration))
                        * scenario_weight_function(m; _drop_key(ind_, :t)...)
                        for ind_ in variable_indices_function(m; ind...)
                    )
                    * mga_weight_iteration(; ind...)
                )
                d_diff_lb2[(ind..., mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[(ind..., mga_iteration=mga_current_iteration)]
                    >=
                    sum(
                        (_mga_result(m, variable_name, ind_, mga_current_iteration) - variable[ind_])
                        * scenario_weight_function(m; _drop_key(ind_, :t)...)
                        for ind_ in variable_indices_function(m; ind...)
                    ) 
                    * mga_weight_iteration(; ind...)
                )
            end
        end
    end
end

function _mga_result(m, variable_name, ind, mga_iteration)
    suffix = (mga_iteration=mga_iteration,)
    window = start(current_window(m)), end_(current_window(m))
    m.ext[:spineopt].outputs[variable_name][suffix][window][_static(ind)]
end

function add_mga_objective_constraint!(m::Model)
    instance = m.ext[:spineopt].instance
    m.ext[:spineopt].constraints[:mga_slack_constraint] = Dict(
        (model=m.ext[:spineopt].instance,) => @constraint(
            m,
            total_costs(m, anything)
            <=
            (1 + max_mga_slack(model=instance)) * objective_value(m)
        )
    )
end

function save_mga_objective_values!(m::Model)
    ind = (model=m.ext[:spineopt].instance, t=current_window(m))
    for name in [:mga_objective,]
        for ind in keys(m.ext[:spineopt].variables[name])
            m.ext[:spineopt].values[name] = Dict(ind => value(m.ext[:spineopt].variables[name][ind]))
        end
    end
end

function set_mga_objective!(m)
    weighted_investments = all(
        [
            isempty(indices(connections_invested_big_m_mga)),
            isempty(indices(units_invested_big_m_mga)),
            isempty(indices(storages_invested_big_m_mga))
        ]
    )
    m.ext[:spineopt].variables[:mga_objective] = Dict(
        (model=m.ext[:spineopt].instance, t=current_window(m)) => @variable(
            m,
            base_name=_base_name(:mga_objective, (model=m.ext[:spineopt].instance, t=current_window(m))),
            lower_bound=(weighted_investments ? Inf : 0)
        )
    )
    @objective(
        m,
        Max,
        m.ext[:spineopt].variables[:mga_objective][(model=m.ext[:spineopt].instance, t=current_window(m))]
    )
end