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

function run_spineopt_mga!(
    m,
    url_out;
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
    build_model!(m; log_level)
    outputs = Dict()
    mga_iteration_count = 0
    max_mga_iters = max_mga_iterations(model=m.ext[:spineopt].instance)
    mga_iteration = ObjectClass(:mga_iteration, [])
    @eval mga_iteration = $mga_iteration
    _solve_standard_model!(
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
        optimize_model!(m; log_level=log_level, output_suffix=_add_mga_iteration(mga_iteration_count)) || break
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
