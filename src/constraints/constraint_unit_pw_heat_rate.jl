#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    add_constraint_unit_pw_heat_rate!(m)

Implements a standard piecewise linear heat_rate function where `unit_flow` from `node_from` (input fuel consumption) is equal to the
sum over operating point segments of `unit_flow_op` to `node_to` (output electricity node) times the corresponding incremental_heat_rate

"""
function add_constraint_unit_pw_heat_rate!(m::Model)
    @fetch unit_flow, unit_flow_op, units_on, units_started_up = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:unit_pw_heat_rate] = Dict(
        (unit=u, node1=n_from, node2=n_to, stochastic_path=s, t=t) => @constraint(
            m,            
            expr_sum(
                +unit_flow[u, n, d, s, t_short] *
                duration(t_short)
                for
                (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n_from,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            ==
            +expr_sum(
                + unit_flow_op[u, n, d, op, s, t_short] *                
                unit_incremental_heat_rate[(
                    unit=u,
                    node1=n_from,
                    node2=n,
                    i=op,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short)
                for
                (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    m;
                    unit=u,
                    node=n_to,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )            
            +
            expr_sum(
                +unit_flow[u, n, d, s, t_short] *
                unit_incremental_heat_rate[(
                    unit=u,
                    node1=n_from,
                    node2=n,                    
                    i=1,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short)
                for
                (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n_to,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                ) if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
                init=0,
            )             
             + expr_sum(
                + ( units_on[u, s, t1] *
                    min(duration(t1), duration(t)) *
                    unit_idle_heat_rate[(unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, analysis_time=t0, t=t)]                     
                )
                + ( units_started_up[u, s, t1] *                    
                    unit_start_flow[(unit=u, node1=n_from, node2=n_to, stochastic_scenario=s, analysis_time=t0, t=t)]                     
                )
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )           
        ) for (u, n_from, n_to, s, t) in constraint_unit_pw_heat_rate_indices(m)
    )
end



"""
    constraint_unit_pw_heat_rate_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `unit_pw_heat_rate` constraint 

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and
`units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_pw_heat_rate_indices(
    m::Model,    
    unit=anything,
    node_from=anything,         #input "fuel" node
    node_to=anything,           #output "electricity" node
    stochastic_path=anything,
    t=anything,
)
    unique(
        (unit=u, node_from=n_from, node_to=n_to, stochastic_path=path, t=t)
        for (u, n_from, n_to) in indices(unit_incremental_heat_rate) if u in unit && n_from in node_from && n_to in node_to
        for
        t in t_lowest_resolution(x.t for x in unit_flow_indices(m; unit=u, node=[n_from, n_to], t=t))
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_unit_pw_heat_rate_indices(m, u, n_from, n_to, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_unit_pw_heat_rate_indices(unit, node_from, node_to, t)

Gather the indices of the relevant `unit_flow` and `units_on` variables.
"""
function _constraint_unit_pw_heat_rate_indices(m, unit, node_from, node_to, t)
    Iterators.flatten((
        unit_flow_indices(m; unit=unit, node=node_from, direction=direction(:from_node), t=t_in_t(m; t_long=t)),
        unit_flow_indices(m; unit=unit, node=node_to, direction=direction(:to_node), t=t_in_t(m; t_long=t)),
        units_on_indices(m; unit=unit, t=t_in_t(m; t_long=t)),
    ))
end
