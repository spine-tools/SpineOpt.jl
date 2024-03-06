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


"""
    add_expression_capacity_margin!(m::Model)

Create an expression for `capacity_margin`. This represents the loat that must be met by conventional
    resources net of variable renewable production and storage. It is used in the `min_capacity_margin` constraint
"""

function add_expression_capacity_margin!(m::Model)
    @fetch unit_flow, units_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    
    m.ext[:spineopt].expressions[:capacity_margin] = Dict(
        (node=n, stochastic_path=s, t=t) => @expression(
            m,
            - sum(                
                + demand[
                    (node=n, stochastic_scenario=s, analysis_time=t0, t=first(representative_time_slice(m, t)))
                ]                
                for (n, s, t) in node_injection_indices(
                    m; node=n, stochastic_scenario=s, t=t, temporal_block=anything
                );
                init=0,
            )
            - sum(
                fractional_demand[
                    (node=n, stochastic_scenario=s, analysis_time=t0, t=first(representative_time_slice(m, t)))
                ]
                * demand[(node=ng, stochastic_scenario=s, analysis_time=t0, t=first(representative_time_slice(m, t)))]
                for (n, s, t) in node_injection_indices(
                    m; node=n, stochastic_scenario=s, t=t, temporal_block=anything
                )
                for ng in groups(n);
                init=0,
            )                                  
           
            # Commodity flows to storage units
            - sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t,
                    temporal_block=anything,
                ) if is_storage_unit(u);
                init=0,
            )

            # Commodity flows from storage units
            + sum(
                unit_flow[u, n, d, s, t_short]
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t,
                    temporal_block=anything,
                )
                if is_storage_unit(u);
                init=0,
            )           

            # Conventional and Renewable Capacity
            + sum(
                + unit_capacity[(unit=u, node=n_, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
                * unit_availability_factor[(unit=u, stochastic_scenario=s, analysis_time=t0, t=t)]
                * (                   
                    + sum(
                        + units_available[u, s, t_ua]
                        for (u, s, t_ua) in units_on_indices(
                            m;
                            unit=u,
                            stochastic_scenario=s,
                            t=t_overlaps_t(m; t=t),
                            temporal_block=anything,
                        );
                        init=0,
                    )                                           
                )
                for (u, n_, d) in indices(unit_capacity; node=n, direction=direction(:to_node)) if !is_storage_unit(u)
            )
        )
        for (n, s, t) in expression_capacity_margin_indices(m)
    )
end

"""
    expression_capacity_margin_indices!(m::Model; t_range)

    Return the indices for the capacity_margin expression
"""

function expression_capacity_margin_indices(m::Model; t_range=anything)
    unique(
        (node=n, stochastic_path=path, t=t)        
        for n in indices(min_capacity_margin)        
        for (n, t) in node_time_indices(m; node=n)
        for path in active_stochastic_paths(
            m,  
            [                                      
                node_stochastic_time_indices(m; node=n, t=t);
                [
                    (unit=u, stochastic_scenario=s, t=t2)
                    for u in indices(unit_capacity; node=n, direction=direction(:to_node)) if !is_storage_unit(u)
                    for (u, s, t2) in units_on_indices(m; unit=u, t=t_overlaps_t(m; t=t))
                ];
                [
                   (unit=u, node=n, stochastic_scenario=s, t=t)
                   for u in unit__to_node(node=n, direction=direction(:to_node)) if is_storage_unit(u)
                   for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=n, direction=direction(:to_node), t=t) 
                ];
                [
                   (unit=u, node=n, stochastic_scenario=s, t=t)
                   for u in unit__to_node(node=n, direction=direction(:from_node)) if is_storage_unit(u)
                   for (u, n, d, s, t) in unit_flow_indices(m; unit=u, node=n, direction=direction(:from_node), t=t) 
                ]
            ]
            
        )
        
    )
end

"""
    is_storage_unit(u)

    Determines whether the unit u is attached to a node with storage or not.
"""

function is_storage_unit(u)
    for n in unit__from_node(unit=u, direction=direction(:from_node))
        if has_state(node=n)
            return true
        end
    end
    false
end
