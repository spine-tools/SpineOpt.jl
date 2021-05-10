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

function process_master_problem_solution(mp)
    function _save_mp_values(
        obj_cls::ObjectClass, 
        rel_cls::RelationshipClass, 
        investment_parameter::Parameter,
        variable_indices::Function,
        investment_variable_name::Symbol,
        fix_param_name::Symbol,
        param_name_bi::Symbol
    )
        for obj in indices(investment_parameter)
            # FIXME: Use Map instead of TimeSeries, to account for different stochastic scenarios
            inds_vals = [
                (start(ind.t), mp.ext[:values][investment_variable_name][ind])
                for ind in variable_indices(mp; Dict(obj_cls.name => obj)...) if end_(ind.t) <= end_(current_window(mp))
            ]
            pv = parameter_value(TimeSeries(first.(inds_vals), last.(inds_vals), false, false))
            obj_cls.parameter_values[obj][fix_param_name] = pv
            push!(get!(rel_cls.parameter_values, (obj, current_bi), Dict()), param_name_bi => pv)
        end
    end
    _save_mp_values(
        unit, 
        unit__benders_iteration, 
        candidate_units, 
        units_invested_available_indices, 
        :units_invested_available, 
        :fix_units_invested_available,
        :units_invested_available_bi
    )
    _save_mp_values(
        connection, 
        connection__benders_iteration, 
        candidate_connections, 
        connections_invested_available_indices, 
        :connections_invested_available, 
        :fix_connections_invested_available,
        :connections_invested_available_bi
    )
    _save_mp_values(
        node, 
        node__benders_iteration, 
        candidate_storages, 
        storages_invested_available_indices, 
        :storages_invested_available, 
        :fix_storages_invested_available,
        :storages_invested_available_bi
    )
end

function process_subproblem_solution(m, mp)
    save_sp_marginal_values(m)
    save_sp_objective_value_bi(m, mp)
    reset_fix_parameter_values()
end

function reset_fix_parameter_values()
    function _reset_fix_parameter_value(class::ObjectClass, invest_param::Parameter, fix_name::Symbol, starting_name::Symbol)
        for obj in indices(invest_param)
            if haskey(class.parameter_values[obj], starting_name)
                class.parameter_values[obj][fix_name] = class.parameter_values[obj][starting_name]
            else
                delete!(class.parameter_values[obj], fix_name)
            end
        end
    end
    fix_name, starting_name = :fix_units_invested_available, :starting_fix_units_invested_available
    _reset_fix_parameter_value(unit, candidate_units, fix_name, starting_name)
    fix_name, starting_name = :fix_connections_invested_available, :starting_fix_connections_invested_available
    _reset_fix_parameter_value(connection, candidate_connections, fix_name, starting_name)
    fix_name, starting_name = :fix_storages_invested_available, :starting_fix_storages_invested_available
    _reset_fix_parameter_value(node, candidate_storages, fix_name, starting_name)
end

function add_benders_iteration(j)
    function _bi_relationships(class_name::Symbol, new_bi::Object, invest_param::Parameter)
        [(Dict(class_name => obj)..., benders_iteration=new_bi) for obj in indices(invest_param)]
    end
    new_bi = Object(Symbol(string("bi_", j)))
    add_object!(benders_iteration, new_bi)
    add_relationships!(unit__benders_iteration, _bi_relationships(:unit, new_bi, candidate_units))
    add_relationships!(connection__benders_iteration, _bi_relationships(:connection, new_bi, candidate_connections))
    add_relationships!(node__benders_iteration, _bi_relationships(:node, new_bi, candidate_storages))
    new_bi
end

function save_sp_marginal_values(m)
    function _save_marginal_value(rel_cls::RelationshipClass, invest_param::Parameter, out_name::Symbol, var_name::Symbol)
        obj_scen_val = Dict()
        for ((obj, scen), val) in m.ext[:outputs][out_name]
            push!(get!(obj_scen_val, obj, Dict()), scen => val)
        end
        for obj in indices(invest_param)
            # FIXME: Use Map instead of TimeSeries, to account for different stochastic scenarios
            scen_val = obj_scen_val[obj]
            val = first(values(scen_val))
            pv = parameter_value(TimeSeries(collect(keys(val)), collect(values(val)), false, false))
            rel_cls.parameter_values[(obj, current_bi)][var_name] = pv
        end
    end
    out_name, var_name = :bound_units_on, :units_available_mv
    _save_marginal_value(unit__benders_iteration, candidate_units, out_name, var_name)
    out_name, var_name = :bound_connections_invested_available, :connections_invested_available_mv
    _save_marginal_value(connection__benders_iteration, candidate_connections, out_name, var_name)
    out_name, var_name = :bound_storages_invested_available, :storages_invested_available_mv
    _save_marginal_value(node__benders_iteration, candidate_storages, out_name, var_name)
end

function save_sp_objective_value_bi(m, mp)
    total_sp_obj_val = reduce(+, values(m.ext[:values][:total_costs]), init=0)
    benders_iteration.parameter_values[current_bi] = Dict(:sp_objective_value_bi => parameter_value(total_sp_obj_val))

    total_mp_investment_costs = reduce(+, values(mp.ext[:values][:unit_investment_costs]); init=0)
    total_mp_investment_costs += reduce(+, values(mp.ext[:values][:connection_investment_costs]); init=0)

    obj_ub = mp.ext[:objective_upper_bound] = total_sp_obj_val + total_mp_investment_costs
    obj_lb = mp.ext[:objective_lower_bound] = reduce(+, values(mp.ext[:values][:mp_objective_lowerbound]); init=0)
    mp.ext[:benders_gap] = (2 * (obj_ub - obj_lb)) / (obj_ub + obj_lb)
end
