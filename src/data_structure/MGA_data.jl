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

# function save_MGA_solution(mp)
#     function _save_mga_values(
#         MGA_cls::Union{ObjectClass,RelationshipClass},
#         rel_cls::RelationshipClass,
#         MGA_parameter::Parameter,
#         variable_indices::Function,
#         variable_name::Symbol,
#         fix_param_name::Symbol,
#         param_name_MGAi::Symbol
#     )
#         for id in indices(MGA_parameter)
#             # FIXME: Use Map instead of TimeSeries, to account for different stochastic scenarios
#             inds_vals = [
#                 (start(ind.t), mp.ext[:values][variable_name][ind])
#                 for ind in variable_indices(mp; Dict(MGA_cls.name => id)...) if end_(ind.t) <= end_(current_window(mp))
#             ]
#             pv = parameter_value(TimeSeries(first.(inds_vals), last.(inds_vals), false, false))
#             MGA_cls.parameter_values[id][fix_param_name] = pv
#             push!(get!(rel_cls.parameter_values, (MGA_cls, current_bi), Dict()), param_name_MGAi => pv)
#         end
#     end
#     _save_mga_values(
#         unit,
#         unit__MGA_iteration,
#         unit_invested__MGA,
#         units_invested_available_indices,
#         :units_invested_available,
#         :fix_units_invested_available,
#         :units_invested_available_MGAi
#     )
#     _save_mga_values(
#         unit__node__direction,
#         unit__node__direction__MGA_iteration,
#         unid_flow__MGA,
#         unit_flow_indices,
#         :unit_flow,
#         :fix_unit_flow,
#         :unit_flow_MGAi
#     )
# end

# function add_MGA_iteration(j)
#     function _MGA_relationships(class_name::Symbol, new_MGA::Object, invest_param::Parameter)
#         [(Dict(class_name => obj)..., benders_iteration=new_MGA) for obj in indices(invest_param)]
#     end
#     new_MGA = Object(Symbol(string("MGA_", j)))
#     add_object!(benders_iteration, new_MGA)
#     add_relationships!(unit__benders_iteration, _MGA_relationships(:unit, new_MGA, candidate_units))
#     add_relationships!(connection__benders_iteration, _MGA_relationships(:connection, new_MGA, candidate_connections))
#     add_relationships!(node__benders_iteration, _MGA_relationships(:node, new_MGA, candidate_storages))
#     new_MGA
# end
#
# function save_first_MGA_objective_value(m)
#     total_obj_val = m.ext[:values][:total_costs])
#     MGA_iteration.parameter_values[current_MGA] = Dict(:objective_value_MGA => parameter_value(total_obj_val))
# end
#
function units_invested_MGA_indices()
    unique(
        [
        (unit=ug, MGA_iteration=MGA_it)
        for ug in unit(units_invested_MGA=true)
            for MGA_it in MGA_iteration()])
end
# ```alternative objective```
function set_objective_MGA_iteration!(m)
    @fetch units_invested_available = m.ext[:variables]
    instance = m.ext[:instance]
    MGA_results = m.ext[:outputs]
    t0 = _analysis_time(m)
    #### Objective variables needed
    m.ext[:variables][:MGA_aux_diff] = Dict(
               ind => @variable(m, base_name = _base_name(:MGA_aux_diff,ind), lower_bound = 0)
               for ind in units_invested_MGA_indices())
   m.ext[:variables][:MGA_aux_binary] = Dict(
              ind => @variable(m, base_name = _base_name(:MGA_aux_binary,ind), binary=true)
              for ind in units_invested_MGA_indices())
    if MGA_diff_relative(model=instance) #FIXME: define this properly for relative and not relative
        @fetch MGA_aux_diff, MGA_aux_binary, units_invested_available = m.ext[:variables]
        m.ext[:constraints][:MGA_diff_pos] = Dict(
            (unit=ug, MGA_iteration=MGA_it) => @constraint(
                m,
                MGA_aux_diff[ug,MGA_it]
                <=
                sum(
                + units_invested_available[u, s, t]
                  - MGA_results[:units_invested_available][(unit=u, stochastic_scenario = s, MGA_iteration = MGA_it)][t0.ref.x][t.start.x]
                       for (u,s,t) in units_invested_available_indices(m; unit=ug)
               )
               + units_invested_big_m_MGA(unit=ug)*MGA_aux_binary[ug,MGA_it])
               for (ug, MGA_it) in units_invested_MGA_indices()
           )
       m.ext[:constraints][:MGA_diff_neg] = Dict(
           (unit=ug, MGA_iteration=MGA_it) => @constraint(
                m,
                MGA_aux_diff[ug,MGA_it]
                <=
                sum(
                - units_invested_available[u, s, t]
                  + MGA_results[:units_invested_available][(unit=u, stochastic_scenario = s, MGA_iteration = MGA_it)][t0.ref.x][t.start.x]
                       for (u,s,t) in units_invested_available_indices(m; unit=ug)
               )
              + units_invested_big_m_MGA(unit=ug)*(1-MGA_aux_binary[ug,MGA_it])
              )
               for (ug, MGA_it) in units_invested_MGA_indices()
            )
        m.ext[:constraints][:MGA_diff_lb1] = Dict(
            (unit=ug, MGA_iteration=MGA_it) => @constraint(
                m,
                MGA_aux_diff[ug,MGA_it]
                >=
                sum(
                units_invested_available[u, s, t]
                  - MGA_results[:units_invested_available][(unit=u, stochastic_scenario = s, MGA_iteration = MGA_it)][t0.ref.x][t.start.x]
                       for (u,s,t) in units_invested_available_indices(m; unit=ug)
               )
               )
               for (ug, MGA_it) in units_invested_MGA_indices()
            )
        m.ext[:constraints][:MGA_diff_lb2] = Dict(
            (unit=ug, MGA_iteration=MGA_it) => @constraint(
                m,
                MGA_aux_diff[ug,MGA_it]
                >=
                sum(
                -units_invested_available[u, s, t]
                  + MGA_results[:units_invested_available][(unit=u, stochastic_scenario = s, MGA_iteration = MGA_it)][t0.ref.x][t.start.x]
                       for (u,s,t) in units_invested_available_indices(m; unit=ug)
               )
               )
               for (ug, MGA_it) in units_invested_MGA_indices()
                )
        m.ext[:constraints][:MGA_objective_ub] = Dict(
            (MGA_iteration=MGA_it) => @constraint(
                m,
                m[:MGA_objective]
                <= sum(MGA_aux_diff[ug,MGA_it]
                        for ug in unit(units_invested_MGA=true))
                ) for MGA_it in MGA_iteration()
        )
        @objective(m,
                Max,
                m[:MGA_objective]
                )
    end
end

function add_MGA_objective_constraint!(m::Model)
    instance = m.ext[:instance]
    @constraint(m, total_costs(m, end_(last(time_slice(m)))) <= (1+max_MGA_slack(model = instance)) * objective_value_MGA(model= instance))
end
