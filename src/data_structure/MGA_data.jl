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

function units_invested_MGA_indices()
    unique(
        [
        (unit=ug,)
        for ug in unit(units_invested_MGA=true)])
end

function units_invested_MGA_indices(MGA_iteration)
    unique(
        [
        (unit=ug, MGA_iteration=MGA_it)
        for ug in unit(units_invested_MGA=true)
            for MGA_it in MGA_iteration])
end

function connections_invested_MGA_indices()
    unique(
        [
        (connection=cg,)
        for cg in connection(connections_invested_MGA=true)])
end

function connections_invested_MGA_indices(MGA_iteration)
    unique(
        [
        (connection=cg, MGA_iteration=MGA_it)
        for cg in connection(connections_invested_MGA=true)
            for MGA_it in MGA_iteration])
end

function storages_invested_MGA_indices()
    unique(
        [
        (node=ng, )
        for ng in node(storages_invested_MGA=true)])
end

function storages_invested_MGA_indices(MGA_iteration)
    unique(
        [
        (node=ng, MGA_iteration=MGA_it)
        for ng in node(storages_invested_MGA=true)
            for MGA_it in MGA_iteration])
end

function set_objective_MGA_iteration!(m;iteration=nothing)
    instance = m.ext[:instance]
    if MGA_diff_relative(model=instance) #FIXME: define this properly for relative and not relative
        _set_objective_MGA_iteration!(
            m,
            :units_invested_available,
            units_invested_available_indices,
            unit_stochastic_scenario_weight,
            units_invested_MGA_indices,
            units_invested_big_m_MGA,
            iteration
        )
        _set_objective_MGA_iteration!(
            m,
            :connections_invested_available,
            connections_invested_available_indices,
            connection_stochastic_scenario_weight,
            connections_invested_MGA_indices,
            connections_invested_big_m_MGA,
            iteration
        )
        _set_objective_MGA_iteration!(
            m,
            :storages_invested_available,
            storages_invested_available_indices,
            node_stochastic_scenario_weight,
            storages_invested_MGA_indices,
            storages_invested_big_m_MGA,
            iteration
        )
        @fetch MGA_aux_diff, MGA_objective = m.ext[:variables]
        @show keys(MGA_aux_diff)
        m.ext[:constraints][:MGA_objective_ub] = Dict(
            (MGA_iteration=iteration) => @constraint(
                m,
                MGA_objective[(model = m.ext[:instance],t=current_window(m))]
                <= sum(MGA_aux_diff[ind...]
                       for ind in vcat([storages_invested_MGA_indices(iteration),connections_invested_MGA_indices(iteration),units_invested_MGA_indices(iteration)])
                )
        )
        )
        for (con_key, cons) in m.ext[:constraints]
            for (inds, con) in cons
                set_name(con, string(con_key, inds))
            end
        end
    end
end

function _set_objective_MGA_iteration!(
        m::Model,
        variable_name::Symbol,
        variable_indices_function::Function,
        scenario_weight_function::Function,
        MGA_indices::Function,
        MGA_variable_bigM::Parameter,
        MGA_current_iteration::Object,
        )
        if !isempty(MGA_indices())
            t0 = _analysis_time(m)
            @fetch units_invested_available = m.ext[:variables]
            MGA_results = m.ext[:outputs]
            t0 = _analysis_time(m)
            d_aux = get!(m.ext[:variables], :MGA_aux_diff, Dict())
            d_bin = get!(m.ext[:variables],:MGA_aux_binary, Dict())
            #FIXME: make more generic (easily add new MGA variables)
            for ind in MGA_indices(MGA_current_iteration)
                d_aux[ind] = @variable(m, base_name = _base_name(:MGA_aux_diff,ind), lower_bound = 0)
                d_bin[ind] = @variable(m, base_name = _base_name(:MGA_aux_binary,ind), binary=true)
            end
            @fetch MGA_aux_diff, MGA_aux_binary, MGA_objective = m.ext[:variables]
            MGA_results = m.ext[:outputs]
            variable = m.ext[:variables][variable_name]
            @show collect(keys(d_aux))
            @show [MGA_aux_diff[ind...,MGA_current_iteration] for ind in MGA_indices()]
            m.ext[:constraints][:MGA_diff_ub1] = Dict(
                (ind...,MGA_current_iteration...) => @constraint(
                    m,
                    MGA_aux_diff[ind...,MGA_current_iteration]
                    <=
                    sum(
                    + (
                    variable[_ind]
                     - MGA_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., MGA_iteration=MGA_current_iteration))][t0.ref.x][_ind.t.start.x]
                     )
                     *scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...) #fix me, can also be only node or so
                           for _ind in variable_indices_function(m; ind...)
                   )
                   + MGA_variable_bigM(;ind...)*MGA_aux_binary[(ind...,MGA_iteration=MGA_current_iteration)])
                   for ind in MGA_indices()
               )
           m.ext[:constraints][:MGA_diff_ub2] = Dict(
               (ind...,MGA_current_iteration...) => @constraint(
                    m,
                    MGA_aux_diff[ind...,MGA_current_iteration]
                    <=
                    sum(
                    - (variable[_ind]
                      - MGA_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., MGA_iteration=MGA_current_iteration))][t0.ref.x][_ind.t.start.x])
                      * scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...)
                           for _ind in variable_indices_function(m; ind...)
                   )
                  + MGA_variable_bigM(;ind...)*(1-MGA_aux_binary[(ind...,MGA_iteration=MGA_current_iteration)])
                  )
                   for ind in MGA_indices()
                )
            m.ext[:constraints][:MGA_diff_lb1] = Dict(
                (ind...,MGA_current_iteration...) => @constraint(
                    m,
                    MGA_aux_diff[ind...,MGA_current_iteration]
                    >=
                    sum(
                    (variable[_ind]
                      - MGA_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., MGA_iteration=MGA_current_iteration))][t0.ref.x][_ind.t.start.x])
                      * scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...)
                           for _ind in variable_indices_function(m; ind...)
                   )
                   )
                   for ind in MGA_indices()
                )
            m.ext[:constraints][:MGA_diff_lb2] = Dict(
                (ind...,MGA_current_iteration...) => @constraint(
                    m,
                    MGA_aux_diff[ind...,MGA_current_iteration]
                    >=
                    sum(
                    - (variable[_ind]
                      - MGA_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., MGA_iteration=MGA_current_iteration))][t0.ref.x][_ind.t.start.x])
                      * scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...)
                           for _ind in variable_indices_function(m; ind...)
                   )
                   )
                   for ind in MGA_indices()
                    )
        end
end

function add_MGA_objective_constraint!(m::Model)
    instance = m.ext[:instance]
    @constraint(m, total_costs(m, end_(last(time_slice(m)))) <= (1+max_MGA_slack(model = instance)) * objective_value_MGA(model= instance))
end

function save_MGA_objective_values!(m::Model)
    ind = (model=m.ext[:instance], t=current_window(m))
    for name in [:MGA_objective,]
        m.ext[:values][name] = Dict(ind => value(m.ext[:variables][name][ind]))
    end
end
