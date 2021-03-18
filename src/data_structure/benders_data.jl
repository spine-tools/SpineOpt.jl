#############################################################################
# Copyright (C) 2017 - 2020  Spine Project
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

function process_master_problem_solution(mp)
    for u in indices(candidate_units)
        time_indices = [
            start(inds.t)
            for inds in units_invested_available_indices(mp; unit=u) if end_(inds.t) <= end_(current_window(mp))
        ]
        vals = [
            mp.ext[:values][:units_invested_available][inds]
            for inds in units_invested_available_indices(mp; unit=u) if end_(inds.t) <= end_(current_window(mp))
        ]
        unit.parameter_values[u][:fix_units_invested_available] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
        if !haskey(unit__benders_iteration.parameter_values, (u, current_bi))
            unit__benders_iteration.parameter_values[(u, current_bi)] = Dict()
        end
        unit__benders_iteration.parameter_values[(u, current_bi)][:units_invested_available_bi] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
    end
    for c in indices(candidate_connections)
        time_indices = [
            start(inds.t)
            for inds in connections_invested_available_indices(mp; connection=c) if end_(inds.t) <= end_(current_window(mp))
        ]
        vals = [
            mp.ext[:values][:connections_invested_available][inds]
            for inds in connections_invested_available_indices(mp; connection=c) if end_(inds.t) <= end_(current_window(mp))
        ]
        connection.parameter_values[c][:connections_invested_available_mp] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
        connection.parameter_values[c][:fix_connections_invested_available] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
        if !haskey(connection__benders_iteration.parameter_values, (c, current_bi))
            connection__benders_iteration.parameter_values[(c, current_bi)] = Dict()
        end
        connection__benders_iteration.parameter_values[(c, current_bi)][:connections_invested_available_bi] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
    end
    for n in indices(candidate_storages)
        time_indices = [
            start(inds.t)
            for inds in storages_invested_available_indices(mp; node=n) if end_(inds.t) <= end_(current_window(mp))
        ]
        vals = [
            mp.ext[:values][:storages_invested_available][inds]
            for inds in storages_invested_available_indices(mp; node=n) if end_(inds.t) <= end_(current_window(mp))
        ]
        node.parameter_values[n][:fix_storages_invested_available] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
        if !haskey(node__benders_iteration.parameter_values, (n, current_bi))
            node__benders_iteration.parameter_values[(n, current_bi)] = Dict()
        end
        node__benders_iteration.parameter_values[(n, current_bi)][:storages_invested_available_bi] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
    end

end


function process_subproblem_solution(m, mp, j)
    save_sp_marginal_values(m)
    save_sp_objective_value_bi(m, mp)
    unfix_mp_variables()
end


function unfix_mp_variables()
    for u in indices(candidate_units)
        if haskey(unit.parameter_values[u], :starting_fix_units_invested_available)
            unit.parameter_values[u][:fix_units_invested_available] =
                unit.parameter_values[u][:starting_fix_units_invested_available]
        else
            delete!(unit.parameter_values[u], :fix_units_invested_available)
        end
    end
    for c in indices(candidate_connections)
        if haskey(connection.parameter_values[c], :starting_fix_connections_invested_available)
            connection.parameter_values[c][:fix_connections_invested_available] =
                connection.parameter_values[c][:starting_fix_connections_invested_available]
        else
            delete!(connection.parameter_values[c], :fix_connections_invested_available)
        end
    end
    for n in indices(candidate_storages)
        if haskey(node.parameter_values[n], :starting_fix_storages_invested_available)
            node.parameter_values[n][:fix_storages_invested_available] =
                node.parameter_values[n][:starting_fix_storages_invested_available]
        else
            delete!(node.parameter_values[n], :fix_storages_invested_available)
        end
    end
end


function add_benders_iteration(j)
    new_bi = Object(Symbol(string("bi_", j)))
    add_object!(benders_iteration, new_bi)
    add_relationships!(unit__benders_iteration, [(unit=u, benders_iteration=new_bi) for u in indices(candidate_units)])
    add_relationships!(connection__benders_iteration, [(connection=c, benders_iteration=new_bi) for c in indices(candidate_connections)])
    new_bi
end


function save_sp_marginal_values(m)
    inds = keys(m.ext[:values][:bound_units_on])
    for u in indices(candidate_units)
        time_indices = [start(ind.t) for ind in inds if ind.unit == u]
        vals = [m.ext[:values][:bound_units_on][ind] for ind in inds if ind.unit == u]
        unit__benders_iteration.parameter_values[(u, current_bi)][:units_available_mv] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
    end
    inds = keys(m.ext[:values][:bound_connections_invested_available])
    for c in indices(candidate_connections)
        time_indices = [start(ind.t) for ind in inds if ind.connection == c]
        vals = [m.ext[:values][:bound_connections_invested_available][ind] for ind in inds if ind.connection == c]
        connection__benders_iteration.parameter_values[(c, current_bi)][:connections_invested_available_mv] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
    end
    inds = keys(m.ext[:values][:bound_storages_invested_available])
    for n in indices(candidate_storages)
        time_indices = [start(ind.t) for ind in inds if ind.node == n]
        vals = [m.ext[:values][:bound_storages_invested_available][ind] for ind in inds if ind.node == n]
        node__benders_iteration.parameter_values[(n, current_bi)][:storages_invested_available_mv] =
            parameter_value(TimeSeries(time_indices, vals, false, false))
    end
end


function save_sp_objective_value_bi(m, mp)
    total_sp_objective_value = 0
    for (ind, value) in m.ext[:values][:total_costs]
        total_sp_objective_value += value
    end
    benders_iteration.parameter_values[current_bi] =
        Dict(:sp_objective_value_bi => parameter_value(total_sp_objective_value))

    total_mp_investment_costs = 0
    for (ind, value) in mp.ext[:values][:unit_investment_costs]
        total_mp_investment_costs += value
    end
    for (ind, value) in mp.ext[:values][:connection_investment_costs]
        total_mp_investment_costs += value
    end

    objective_upper_bound = total_sp_objective_value + total_mp_investment_costs
    mp.ext[:objective_upper_bound] = objective_upper_bound

    objective_lower_bound = 0
    for (ind, value) in mp.ext[:values][:mp_objective_lowerbound]
        objective_lower_bound += value
    end

    mp.ext[:objective_lower_bound] = objective_lower_bound

    mp.ext[:benders_gap] =
        (2 * (objective_upper_bound - objective_lower_bound)) / (objective_upper_bound + objective_lower_bound)

end
