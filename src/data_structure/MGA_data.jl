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

function set_objective_mga_iteration!(m;iteration=nothing)
    instance = m.ext[:instance]
    if mga_diff_relative(model=instance) #FIXME: define this properly for relative and not relative
        _set_objective_mga_iteration!(
            m,
            :units_invested_available,
            units_invested_available_indices,
            unit_stochastic_scenario_weight,
            units_invested_mga_indices,
            units_invested_big_m_mga,
            iteration
        )
        _set_objective_mga_iteration!(
            m,
            :connections_invested_available,
            connections_invested_available_indices,
            connection_stochastic_scenario_weight,
            connections_invested_mga_indices,
            connections_invested_big_m_mga,
            iteration
        )
        _set_objective_mga_iteration!(
            m,
            :storages_invested_available,
            storages_invested_available_indices,
            node_stochastic_scenario_weight,
            storages_invested_mga_indices,
            storages_invested_big_m_mga,
            iteration
        )
        @fetch mga_aux_diff, mga_objective = m.ext[:variables]
        ub_objective = get!(m.ext[:constraints],:mga_objective_ub,Dict())
        ub_objective[iteration] = @constraint(
                m,
                mga_objective[(model = m.ext[:instance],t=current_window(m))]
                <= sum(
                mga_aux_diff[ind...]
                       for ind in vcat([storages_invested_mga_indices(iteration),connections_invested_mga_indices(iteration),units_invested_mga_indices(iteration)])
                )
        )
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
        mga_variable_bigM::Parameter,
        mga_current_iteration::Object,
        )
        if !isempty(mga_indices())
            t0 = _analysis_time(m)
            @fetch units_invested_available = m.ext[:variables]
            mga_results = m.ext[:outputs]
            t0 = _analysis_time(m)
            d_aux = get!(m.ext[:variables], :mga_aux_diff, Dict())
            d_bin = get!(m.ext[:variables],:mga_aux_binary, Dict())
            #FIXME: make more generic (easily add new mga variables)
            for ind in mga_indices(mga_current_iteration)
                d_aux[ind] = @variable(m, base_name = _base_name(:mga_aux_diff,ind), lower_bound = 0)
                d_bin[ind] = @variable(m, base_name = _base_name(:mga_aux_binary,ind), binary=true)
            end
            @fetch mga_aux_diff, mga_aux_binary, mga_objective = m.ext[:variables]
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
                    sum(
                    + (
                    variable[_ind]
                     - mga_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., mga_iteration=mga_current_iteration))][t0.ref.x][_ind.t.start.x]
                     )
                     *scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...) #fix me, can also be only node or so
                           for _ind in variable_indices_function(m; ind...)
                   )
                   + mga_variable_bigM(;ind...)*mga_aux_binary[(ind...,mga_iteration=mga_current_iteration)])
                d_diff_ub2[(ind...,mga_current_iteration...)]= @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    <=
                    sum(
                    - (variable[_ind]
                      - mga_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., mga_iteration=mga_current_iteration))][t0.ref.x][_ind.t.start.x])
                      * scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...)
                           for _ind in variable_indices_function(m; ind...)
                   )
                  + mga_variable_bigM(;ind...)*(1-mga_aux_binary[(ind...,mga_iteration=mga_current_iteration)])
                  )
                  d_diff_lb1[(ind...,mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    >=
                    sum(
                    (variable[_ind]
                      - mga_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., mga_iteration=mga_current_iteration))][t0.ref.x][_ind.t.start.x])
                      * scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...)
                      #FIXME: duration!
                           for _ind in variable_indices_function(m; ind...)
                   )
                   )
                   d_diff_lb2[(ind...,mga_current_iteration...)] = @constraint(
                    m,
                    mga_aux_diff[((ind...,mga_iteration=mga_current_iteration))]
                    >=
                    sum(
                    - (variable[_ind]
                      - mga_results[variable_name][((Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))..., mga_iteration=mga_current_iteration))][t0.ref.x][_ind.t.start.x])
                      * scenario_weight_function(m; Base.structdiff(_ind,NamedTuple{(:t,)}(_ind.t))...)
                           for _ind in variable_indices_function(m; ind...)
                   )
                   )
               end
        end
end

function add_mga_objective_constraint!(m::Model)
    instance = m.ext[:instance]
    m.ext[:constraints][:mga_slack_constraint] = Dict(m.ext[:instance] =>
        @constraint(m, total_costs(m, end_(last(time_slice(m)))) <= (1+max_mga_slack(model = instance)) * objective_value_mga(model= instance))
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
