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

"""
    postprocess_results!(m::Model)

Perform calculations on the model outputs and save them to the ext.values dict.
bases on contents of report__output
"""
function postprocess_results!(m::Model)
    fns! = Dict(
        :connection_avg_throughflow => save_connection_avg_throughflow!,
        :connection_avg_intact_throughflow => save_connection_avg_intact_throughflow!,
        :contingency_is_binding => save_contingency_is_binding!
    )
    for out_name in _output_names(m)
        fn! = get(fns!, out_name, nothing)
        fn! === nothing || fn!(m)
    end
end

function save_connection_avg_throughflow!(m::Model)    
    connection_flow = get(m.ext[:spineopt].values, :connection_flow, nothing)
    connection_flow === nothing && return
    _save_connection_avg_throughflow!(m, :connection_avg_throughflow, connection_flow)
end

function save_connection_avg_intact_throughflow!(m::Model)
    connection_intact_flow = get(m.ext[:spineopt].values, :connection_intact_flow, nothing)
    connection_intact_flow === nothing && return
    _save_connection_avg_throughflow!(m, :connection_avg_intact_throughflow, connection_intact_flow)    
end

function _save_connection_avg_throughflow!(m::Model, key, connection_flow)
    m_start = model_start(model=m.ext[:spineopt].instance)
    avg_throughflow = m.ext[:spineopt].values[key] = Dict()
    sizehint!(avg_throughflow, length(connection()) * length(stochastic_scenario()) * length(time_slice(m)))
    for ((conn, n, d, s, t), value) in connection_flow
        start(t) >= m_start || continue
        # NOTE: Whenever available, always assume that the flow goes from 
        # the first to the second node in `connection__from_node`.
        # CAUTION: works for bi-directional connections with 2 nodes
        if length(connection__from_node(connection=conn, direction=anything)) >= 2 
            n_from, n_to, n_others... = connection__from_node(connection=conn, direction=anything)
        # NOTE: When only one node in `connection__from_node`, assume that the flow goes from
        # the first node in `connection__from_node` to the first node in `connection__to_node` that is different.
        else
            n_from, n_from_others... = connection__from_node(connection=conn, direction=anything)
            n_to, n_to_others... = filter(
                x -> x != n_from, connection__to_node(connection=conn, direction=anything)
            )
        end
        # CAUTION: may cause trouble for multi-terminal connections (with >= 3 nodes linked)
        
        if (n == n_to && d == direction(:to_node)) || (n == n_from && d == direction(:from_node))
            new_value = 0.5 * value
        elseif (n == n_from && d == direction(:to_node)) || (n == n_to && d == direction(:from_node))
            new_value = -0.5 * value
        else
            continue
        end
        
        inner_key = (connection=conn, node=n_to, stochastic_scenario=s, t=t)
        current_value = get(avg_throughflow, inner_key, 0)
        avg_throughflow[inner_key] = current_value + new_value
    end
    avg_throughflow
end

function _contingency_is_binding_indices(m)
    contingency_is_binding = get(m.ext[:spineopt].values, :contingency_is_binding, nothing)
    contingency_is_binding === nothing ? constraint_connection_flow_lodf_indices(m) : keys(contingency_is_binding)
end

function _contingency_is_binding(m, connection_flow, conn_cont, conn_mon, s, t)
    ratio = abs(
        realize(
            connection_post_contingency_flow(m, connection_flow, conn_cont, conn_mon, s, t)
            / connection_minimum_emergency_capacity(m, conn_mon, s, t)
        )
    )
    isapprox(ratio, 1) || ratio >= 1 ? 1 : 0
end

function save_contingency_is_binding!(m::Model)
    connection_flow = get(m.ext[:spineopt].values, :connection_flow, nothing)
    connection_flow === nothing && return
    m.ext[:spineopt].values[:contingency_is_binding] = Dict(
        (
            connection_contingency=conn_cont, connection_monitored=conn_mon, stochastic_path=s, t=t
        ) => _contingency_is_binding(m, connection_flow, conn_cont, conn_mon, s, t)
        for (conn_cont, conn_mon, s, t) in _contingency_is_binding_indices(m)
    )
end
