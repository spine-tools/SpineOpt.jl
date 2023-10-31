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
    add_constraint_unit_flow_capacity!(m::Model)

Limit the maximum in/out `unit_flow` of a `unit` for all `unit_capacity` indices.

Check if `unit_conv_cap_to_flow` is defined.
"""
function add_constraint_unit_flow_capacity!(m::Model)
    @fetch unit_flow, units_on, units_shut_down, nonspin_units_shut_down, nonspin_units_started_up = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_flow_capacity] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t=t_unit_flow) => @constraint(
            m,
            expr_sum(
                unit_flow[u, n, d, s, t_unit_flow] * duration(t_unit_flow) 
                for (u, n, d, s, t_unit_flow) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(m; t_long=t_unit_flow)
                ) 
                if !is_reserve_node(node=n);
                init=0,
            ) 
            + expr_sum(
                unit_flow[u, n, d, s, t_unit_flow] * duration(t_unit_flow) 
                for (u, n, d, s, t_unit_flow) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_in_t(m; t_long=t_unit_flow)
                ) 
                if is_reserve_node(node=n) && upward_reserve(node=n) && !is_non_spinning(node=n);
                init=0,
            ) 
            <=
            + expr_sum(
                # first part
                units_on[u, s, t_unit_on] * min(duration(t_unit_on), duration(t_unit_flow)) 
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_flow)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_flow)]
                -
                # second part
                (1 - max_res_shutdown_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_on)])
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_flow)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_flow)]
                *
                (
                + units_shut_down[u, s, t_after_unit_on] * min(duration(t_after_unit_on), duration(t_unit_flow))
                + expr_sum(
                    nonspin_units_shut_down[u, n, s, t_unit_on] for (u, n, s, t_unit_on) in nonspin_units_shut_down_indices(
                    m; unit=u, stochastic_scenario=s, t=t_unit_on); 
                    init=0
                    ) 
                  * min(duration(t_unit_on), duration(t_unit_flow))
                )
                -
                # third part
                (1 - max_res_startup_ramp[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_on)]) 
                * unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_flow)]
                * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_unit_flow)] 
                * units_started_up[u, s, t_unit_on] * min(duration(t_unit_on), duration(t_unit_flow)) 
                for (u, s, t_unit_on) in 
                    units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t_unit_flow))
                for (u, s, t_after_unit_on) in 
                    units_on_indices(m; unit=u, stochastic_scenario=s, t=t_before_t(m; t_before=t_unit_on));
                init=0,        
            )
        )
        for (u, ng, d, s, t_unit_flow) in constraint_unit_flow_capacity_indices(m)
    )
end

function constraint_unit_flow_capacity_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t=t_unit_flow)
        for (u, ng, d) in indices(unit_capacity)
        for t_unit_flow in time_slice(m; temporal_block=node__temporal_block(node=members(ng)))  
        for path in active_stochastic_paths(
            m,
            [
            unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_unit_flow);
            units_on_indices(m; unit=u, t=[t_overlaps_t(m; t=t_unit_flow); t_before_t(m; t_before=t_overlaps_t(m, t=t_unit_flow))])
            ]
        )
        # for s in path
        #     if min_up_time(unit=u, analysis_time=_analysis_time(m), stochastic_scenario=s, t=t_overlaps_t(m, t=t_unit_flow)) 
        #         > duration(t_overlaps_t(m, t=t_unit_flow))
        #     end
        # end    
        if all(min_up_time(unit=u, analysis_time=_analysis_time(m), stochastic_scenario=s, t=t_overlaps_t(m; t=t_unit_flow)) 
            > duration(t_overlaps_t(m; t=t_unit_flow)) for s in path) 
    )
end

"""
    constraint_unit_flow_capacity_indices_filtered(m::Model; filtering_options...)

Forms the stochastic indexing Array for the `:unit_flow_capacity` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and `units_on`
variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_flow_capacity_indices_filtered(
    m::Model; unit=anything, node=anything, direction=anything, stochastic_path=anything, t=anything
)
    f(ind) = _index_in(ind; unit=unit, node=node, direction=direction, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_unit_flow_capacity_indices(m))
end