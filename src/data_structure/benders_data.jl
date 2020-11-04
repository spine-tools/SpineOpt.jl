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
        time_indices = [start(inds.t) 
            for inds in units_invested_available_indices(mp; unit=u)
            if end_(inds.t) <= end_(current_window(mp))
        ] 
        vals = [mp.ext[:values][:units_invested_available][inds] 
            for inds in units_invested_available_indices(mp; unit=u)
            if end_(inds.t) <= end_(current_window(mp))
        ] 
        unit.parameter_values[u][:fix_units_invested_available] = parameter_value(TimeSeries(time_indices, vals, false, false))
        if !haskey(unit__benders_iteration.parameter_values, (u, current_bi))
            unit__benders_iteration.parameter_values[(u, current_bi)] = Dict()
        end
        unit__benders_iteration.parameter_values[(u, current_bi)][:units_invested_available_bi] = parameter_value(TimeSeries(time_indices, vals, false, false))
    end 
end


function process_subproblem_solution(m, j)
    save_sp_marginal_values(m)
    save_sp_objective_value_bi(m)    
    current_bi = add_benders_iteration(j+1)    
    unfix_mp_variables()
end


function unfix_mp_variables()    
    for u in indices(candidate_units)
        if haskey(unit.parameter_values[u], starting_fix_units_invested_available)
            unit.parameter_values[u][:fix_units_invested_available] = unit.parameter_values[u][:starting_fix_units_invested_available]
        else
            delete(unit.parameter_values[u], fix_units_invested_available)
        end
    end
end


function add_benders_iteration(j)
    new_bi = add_object!(benders_iteration, Symbol(string("bi_", j)))    
    add_relationships!(
        unit__benders_iteration,
        [(unit=u, benders_iteration=new_bi) for u in indices(candidate_units)]
    )    
    new_bi
end


function save_sp_marginal_values(m)
    save_marginals!(m, :units_available)           
    inds = keys(m.ext[:marginals][:units_available])    
    for u in indices(candidate_units)        
        time_indices = [start(ind.t) for ind in inds if ind.u == u] 
        vals = [m.ext[:marginals][:units_available][ind] for ind in inds if ind.u == u]
        unit__benders_iteration.parameter_values[(unit=u, benders_iteration=current_bi)][:units_available_mv] = parameter_value(TimeSeries(time_indices, vals, false, false))
    end
end


function save_sp_objective_value_bi(m)
    benders_iteration.parameter_values[current_bi][:sp_objective_value_bi] = parameter_value(objective_value(m))
end

