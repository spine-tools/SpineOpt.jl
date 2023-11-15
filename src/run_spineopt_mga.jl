#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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

function rerun_spineopt_mga!(
    m::Model,
    url_out::Union{String,Nothing};
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    alternative_objective=m -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative="",
    write_as_roll=0,
    resume_file_path=nothing
)
    outputs = Dict()
    mga_iterations = 0
    max_mga_iteration = max_mga_iterations(model=m.ext[:spineopt].instance)
    mga_iteration = ObjectClass(:mga_iteration, [])
    @eval mga_iteration = $mga_iteration
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m)
    init_model!(
        m;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        alternative_objective=alternative_objective,
        log_level=log_level,
    )
    k = 1
    while optimize
        @log log_level 1 "Window $k: $(current_window(m))"
        optimize_model!(m; log_level=log_level, iterations=mga_iterations) || break
        @timelog log_level 2 "Applying non-anticipativity constraints..." apply_non_anticipativity_constraints!(m)
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m, k)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m; log_level=log_level, update_names=update_names)
        k += 1
    end
    objective_value_mga = :objective_value_mga
    model.parameter_values[m.ext[:spineopt].instance][objective_value_mga] = parameter_value(objective_value(m))
    @eval $(objective_value_mga) = $(Parameter(objective_value_mga, [model]))
    mga_iterations += 1
    add_mga_objective_constraint!(m)
    set_mga_objective!(m)
    # TODO: max_mga_iteration can be different now
    if isnothing(max_mga_iteration)
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
        max_mga_iteration = maximum([u_max, s_max, c_max])
    end
    while mga_iterations <= max_mga_iteration
        # TODO: set_objective_mga_iteration is different now
        set_objective_mga_iteration!(m; iteration=mga_iteration()[end], iterations_num=mga_iterations)
        optimize_model!(m; log_level=log_level, iterations=mga_iterations)  || break
        save_mga_objective_values!(m)
        # TODO: needs to clean outputs?
        if (
            isempty(indices(connections_invested_big_m_mga))
            && isempty(indices(units_invested_big_m_mga))
            && isempty(indices(storages_invested_big_m_mga))
            && mga_iterations < max_mga_iteration
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
        mga_iterations += 1
    end
    write_report(m, url_out; alternative=alternative, log_level=log_level)
    m
end
