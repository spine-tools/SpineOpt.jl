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
    add_constraint_unit_constraint!(m::Model)

Custom constraint for `units`.
"""
function add_constraint_unit_constraint!(m::Model)       
    @fetch unit_flow_op, unit_flow, units_on, units_started_up, connection_flow, node_state = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:unit_constraint] = Dict(
        (unit_constraint=uc, stochastic_path=s, t=t) => sense_constraint(
            m,
            +expr_sum(
                +unit_flow_op[u, n, d, op, s, t_short] *
                unit_flow_coefficient[(
                    unit=u,
                    node=n,
                    unit_constraint=uc,
                    i=op,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
                for
                (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    m;
                    unit=u,
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ) +
            expr_sum(
                +unit_flow[u, n, d, s, t_short] *
                unit_flow_coefficient[(
                    unit=u,
                    node=n,
                    unit_constraint=uc,
                    i=1,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
                for
                (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                ) if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
                init=0,
            ) +
            expr_sum(
                +unit_flow_op[u, n, d, op, s, t_short] *
                unit_flow_coefficient[(
                    unit=u,
                    node=n,
                    unit_constraint=uc,
                    i=op,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
                for
                (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    m;
                    unit=u,
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ) +
            expr_sum(
                +unit_flow[u, n, d, s, t_short] *
                unit_flow_coefficient[(
                    unit=u,
                    node=n,
                    unit_constraint=uc,
                    i=1,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
                for
                (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                ) if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
                init=0,
            ) +
            expr_sum(
                +units_on[u, s, t1] *
                units_on_coefficient[(unit_constraint=uc, unit=u, stochastic_scenario=s, analysis_time=t0, t=t1)] *
                min(duration(t1), duration(t)) for u in unit__unit_constraint(unit_constraint=uc)
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            ) +
            expr_sum(
                +units_started_up[u, s, t1] *
                units_started_up_coefficient[(
                    unit_constraint=uc,
                    unit=u,
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t1,
                )] *
                min(duration(t1), duration(t)) for u in unit__unit_constraint(unit_constraint=uc)
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )
            +expr_sum(
                +connection_flow[c, n, d, s, t_short] *
                connection_flow_coefficient[(
                    connection=c,
                    node=n,
                    unit_constraint=uc,                    
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for (c, n) in connection__from_node__unit_constraint(unit_constraint=uc)                
                for
                (c, n, d, s, t_short) in connection_flow_indices(
                    m;
                    connection=c,
                    node=n,
                    direction=direction(:from_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ) 
            +expr_sum(
                +connection_flow[c, n, d, s, t_short] *
                connection_flow_coefficient[(
                    connection=c,
                    node=n,
                    unit_constraint=uc,                    
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for (c, n) in connection__to_node__unit_constraint(unit_constraint=uc)
                for
                (c, n, d, s, t_short) in connection_flow_indices(
                    m;
                    connection=c,
                    node=n,
                    direction=direction(:to_node),
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ) 
            +expr_sum(
                +node_state[n, s, t_short] *
                node_state_coefficient[(                    
                    node=n,
                    unit_constraint=uc,                    
                    stochastic_scenario=s,
                    analysis_time=t0,
                    t=t_short,
                )] *
                duration(t_short) for n in indices(node_state_coefficient; unit_constraint=uc)
                for
                (n, s, t_short) in node_state_indices(
                    m;                    
                    node=n,                    
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            +expr_sum(
                +demand[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]                 
                    *demand_coefficient[(node=n, unit_constraint=uc, stochastic_scenario=s, analysis_time=t0, t=t)]
                    *duration(t_short)
                for n in node__unit_constraint(unit_constraint=uc)
                for (ns, s, t_short) in node_stochastic_time_indices(m; node=n, stochastic_scenario=s, t=t_in_t(m; t_long=t));
                init=0,            
            ),
            constraint_sense(unit_constraint=uc),
            +expr_sum(
                right_hand_side[(unit_constraint=uc, stochastic_scenario=s, analysis_time=t0, t=t)] for s in s;
                init=0,
            ) / length(s),
        ) for (uc, s, t) in constraint_unit_constraint_indices(m)
    )
end

"""
    constraint_unit_constraint_indices(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:unit_constraint` constraint.
    
Uses stochastic path indices due to potentially different stochastic structures between `unit_flow`, `unit_flow_op`,
and `units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_constraint_indices(
    m::Model;
    unit_constraint=unit_constraint(),
    stochastic_path=anything,
    t=anything,
)
    unique(
        (unit_constraint=uc, stochastic_path=path, t=t) for uc in unit_constraint
        for t in _constraint_unit_constraint_lowest_resolution_t(m, uc, t)
        for
        path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in _constraint_unit_constraint_indices(m, uc, t)
        )) if path == stochastic_path || path in stochastic_path
    )
end

"""
    _constraint_unit_constraint_lowest_resolution_t(m, uc, t)

Find the lowest temporal resolution amoung the `unit_flow` variables appearing in the `unit_constraint`.
"""
function _constraint_unit_constraint_lowest_resolution_t(m, uc, t)
    t_lowest_resolution(
        vcat(
            [ind.t for unit__node__unit_constraint in (unit__from_node__unit_constraint, unit__to_node__unit_constraint)
            for (u, n) in unit__node__unit_constraint(unit_constraint=uc)
            for ind in unit_flow_indices(m; unit=u, node=n, t=t)],
            [ind.t for connection__node__unit_constraint in (connection__from_node__unit_constraint, connection__to_node__unit_constraint)
            for (c, n) in connection__node__unit_constraint(unit_constraint=uc)
            for ind in connection_flow_indices(m; connection=c, node=n, t=t)],
            [ind.t for n in node__unit_constraint(unit_constraint=uc)
            for ind in node_state_indices(m; node=n, t=t)],
            [ind.t for n in node__unit_constraint(unit_constraint=uc)
            for ind in node_stochastic_time_indices(m; node=n, t=t)],
        )
    )
end


"""
    _constraint_unit_constraint_unit_flow_indices(uc, t)

Gather the `unit_flow` variable indices appearing in `add_constraint_unit_constraint!`.
"""
function _constraint_unit_constraint_unit_flow_indices(m, uc, t)
    (
        ind for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc) for
        ind in unit_flow_indices(m; unit=u, node=n, direction=direction(:from_node), t=t_in_t(m; t_long=t))
    )
end


"""
    _constraint_unit_constraint_connectiojn_flow_indices(uc, t)

Gather the `connection_flow` variable indices appearing in `add_constraint_unit_constraint!`.
"""
function _constraint_unit_constraint_connection_flow_indices(m, uc, t)
    (
        ind for (c, n) in unit__from_node__unit_constraint(unit_constraint=uc) for
        ind in connection_flow_indices(m; connection=c, node=n, direction=direction(:from_node), t=t_in_t(m; t_long=t))
    )
end


"""
    _constraint_unit_constraint_node_stochastic_time_indices(m, uc, t)

Gather the `node_stochastic_time_indices` indices appearing in `add_constraint_unit_constraint!`.
"""
function _constraint_unit_constraint_node_stochastic_time_indices(m, uc, t)
    (
        ind for n in node__unit_constraint(unit_constraint=uc) for
        ind in node_stochastic_time_indices(m; node=n, t=t_in_t(m; t_long=t))
    )
end


"""
    _constraint_unit_constraint_node_state_indices(uc, t)

Gather the `node_state` variable indices appearing in `add_constraint_unit_constraint!`.
"""
function _constraint_unit_constraint_node_state_indices(m, uc, t)
    (
        ind for n in node__unit_constraint(unit_constraint=uc) for
        ind in node_state_indices(m; node=n, t=t_in_t(m; t_long=t))
    )
end


"""
    _constraint_unit_constraint_units_on_indices(uc, t)

Gather the `units_on` variable indices appearing in `add_constraint_unit_constraint!`.
"""
function _constraint_unit_constraint_units_on_indices(m, uc, t)
    (
        ind for u in unit__unit_constraint(unit_constraint=uc) for
        ind in units_on_indices(m; unit=u, t=t_in_t(m; t_long=t))
    )
end

"""
    _constraint_unit_constraint_indices(m, uc, t)

Gather the `unit_flow`, `units_on`, `connection_flow`, `node_state` variables appearing in `add_constraint_unit_constraint!`
"""
function _constraint_unit_constraint_indices(m, uc, t)
    Iterators.flatten((
        _constraint_unit_constraint_unit_flow_indices(m, uc, t),
        _constraint_unit_constraint_units_on_indices(m, uc, t),
        _constraint_unit_constraint_connection_flow_indices(m, uc, t),
        _constraint_unit_constraint_node_state_indices(m, uc, t),
        _constraint_unit_constraint_node_stochastic_time_indices(m, uc, t),
    ))
end
