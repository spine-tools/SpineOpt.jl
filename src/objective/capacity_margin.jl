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
    fixed_om_costs(m)

Create an expression for fixed operation costs of units.
"""
function capacity_margin_penalty_term(m, t_range)
    @fetch capacity_margin = m.ext[:spineopt].expressions
    t0 = _analysis_time(m)
    @expression(
        m,
        sum(
            + capacity_margin_penalty[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * capacity_margin[n, s, t]
            
            # This term is activated when there is a representative termporal block in those containing TimeSlice t.
            # We assume only one representative temporal structure available, of which the termporal blocks represent
            # an extended period of time with a weight >=1, e.g. a representative month represents 3 months.
            * duration(t)
            for (n, s, t) in expression_capacity_margin_indices(m; t_range=t_range);
            init=0,
        )
    )
end


"""
    add_expression_capacity_margin!(m)

Create a expression for the capacity margin at nodes where `margin_penalty` is specified
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

# TODO: can we find an easier way to define the constraint indices?
# I feel that for unexperienced uses it gets more an more complicated to understand our code
function expression_capacity_margin_indices(m::Model; t_range=anything)
    unique(
        (node=n, stochastic_path=path, t=t)        
        for n_margin in indices(capacity_margin_penalty)
        for (n, t) in node_time_indices(m; node=n_margin, t=t_range)
        for path in active_stochastic_paths(
            m,           
            node_stochastic_time_indices(m; node=n, t=t),
        )
    )
end



function is_storage_unit(u)
    for n in unit__from_node(unit=u, direction=direction(:from_node))
        if has_state(node=n)
            return true
        end
    end
    false
end
