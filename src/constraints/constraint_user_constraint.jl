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
    add_constraint_user_constraint!(m::Model)

Custom constraint for `units`.
"""
function add_constraint_user_constraint!(m::Model)
    @fetch (
        unit_flow_op,
        unit_flow,
        units_on,
        units_started_up,
        connection_flow,
        node_state,
        units_invested,
        units_invested_available,
        storages_invested,
        storages_invested_available,
        connections_invested,
        connections_invested_available
    ) = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:user_constraint] = Dict(
        (user_constraint=uc, stochastic_path=s, t=t) => sense_constraint(
            m,
            + expr_sum(
                + unit_flow_op[u, n, d, op, s, t_short]
                * unit_flow_coefficient[
                    (unit=u, node=n, user_constraint=uc, direction=d, i=op, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * duration(t_short)
                for (u, n, uc, d) in indices(unit_flow_coefficient;user_constraint=uc)
                for (u, n, d, op, s, t_short) in unit_flow_op_indices(
                    m;
                    unit=u,
                    node=n,
                    direction=d,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            + expr_sum(
                + unit_flow[u, n, d, s, t_short]
                * unit_flow_coefficient[
                    (unit=u, node=n, user_constraint=uc, direction=d, i=1, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * duration(t_short)
                for (u, n, uc, d) in indices(unit_flow_coefficient;user_constraint=uc)
                for (u, n, d, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=n,
                    direction=d,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                ) if isempty(unit_flow_op_indices(m; unit=u, node=n, direction=d, t=t_short));
                init=0,
            )
            + expr_sum(
                (   
                    + units_on[u, s, t1]
                    * units_on_coefficient[(user_constraint=uc, unit=u, stochastic_scenario=s, analysis_time=t0, t=t1)]
                )
                * min(duration(t1), duration(t))
                for (u, uc) in indices(units_on_coefficient;user_constraint=uc)
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )  
            + expr_sum(
                (   
                    + units_started_up[u, s, t1]
                    * units_started_up_coefficient[(user_constraint=uc, unit=u, stochastic_scenario=s, analysis_time=t0, t=t1)]
                )
                * min(duration(t1), duration(t))
                for (u, uc) in indices(units_started_up_coefficient;user_constraint=uc)
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )  
            + expr_sum(
                (   
                    + units_invested_available[u, s, t1]
                    * units_invested_available_coefficient[(user_constraint=uc, unit=u, stochastic_scenario=s, analysis_time=t0, t=t1)]
                )
                * min(duration(t1), duration(t)) 
                for (u, uc) in indices(units_invested_available_coefficient;user_constraint=uc)
                for (u, s, t1) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )
            + expr_sum(
                (   
                    + units_invested[u, s, t1]
                    * units_invested_coefficient[(user_constraint=uc, unit=u, stochastic_scenario=s, analysis_time=t0, t=t1)]
                )
                * min(duration(t1), duration(t)) 
                for (u, uc) in indices(units_invested_coefficient;user_constraint=uc)
                for (u, s, t1) in units_invested_available_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )
            + expr_sum(
                (   
                    + connections_invested_available[c, s, t1]
                    * connections_invested_available_coefficient[(user_constraint=uc, connection=c, stochastic_scenario=s, analysis_time=t0, t=t1)]                  
                )
                * min(duration(t1), duration(t)) 
                for (c, uc) in indices(connections_invested_available_coefficient;user_constraint=uc)
                for (c, s, t1) in connections_invested_available_indices(m; connection=c, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )
            + expr_sum(
                (   
                    + connections_invested[c, s, t1]
                    * connections_invested_coefficient[(user_constraint=uc, connection=c, stochastic_scenario=s, analysis_time=t0, t=t1)]                    
                )
                * min(duration(t1), duration(t)) 
                for (c, uc) in indices(connections_invested_coefficient;user_constraint=uc)
                for (c, s, t1) in connections_invested_available_indices(m; connection=c, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )
            + expr_sum(
                (   
                    + storages_invested_available[n, s, t1]
                    * storages_invested_available_coefficient[(user_constraint=uc, node=n, stochastic_scenario=s, analysis_time=t0, t=t1)]                   
                )
                * min(duration(t1), duration(t)) 
                for (n,uc) in indices(storages_invested_available_coefficient; user_constraint=uc)
                for (n, s, t1) in storages_invested_available_indices(m; node=n, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )      
            + expr_sum(
                (   
                    + storages_invested[n, s, t1]
                    * storages_invested_coefficient[(user_constraint=uc, node=n, stochastic_scenario=s, analysis_time=t0, t=t1)]                    
                )
                * min(duration(t1), duration(t)) 
                for (n,uc) in indices(storages_invested_coefficient; user_constraint=uc)
                for (n, s, t1) in storages_invested_available_indices(m; node=n, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            )      
            + expr_sum(
                + connection_flow[c, n, d, s, t_short]
                * connection_flow_coefficient[
                    (connection=c, node=n, user_constraint=uc, direction=d, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * duration(t_short)
                for (c, n, uc, d) in indices(connection_flow_coefficient;user_constraint=uc)
                for (c, n, d, s, t_short) in connection_flow_indices(
                    m;
                    connection=c,
                    node=n,
                    direction=d,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            )
            + expr_sum(
                + node_state[n, s, t_short]
                * node_state_coefficient[
                    (node=n, user_constraint=uc, stochastic_scenario=s, analysis_time=t0, t=t_short),
                ]
                * duration(t_short) 
                for (n,uc) in indices(node_state_coefficient; user_constraint=uc)
                for (n, s, t_short) in node_state_indices(m; node=n, stochastic_scenario=s, t=t_in_t(m; t_long=t));
                init=0,
            )
            + expr_sum(
                + demand[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
                * demand_coefficient[(node=n, user_constraint=uc, stochastic_scenario=s, analysis_time=t0, t=t)]
                * duration(t_short) 
                for (n,uc) in indices(demand_coefficient; user_constraint=uc)
                for (ns, s, t_short) in node_stochastic_time_indices(
                    m;
                    node=n,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ),
            constraint_sense(user_constraint=uc),
            + expr_sum(
                right_hand_side[(user_constraint=uc, stochastic_scenario=s, analysis_time=t0, t=t)] for s in s;
                init=0,
            ) / length(s),
        ) for (uc, s, t) in constraint_user_constraint_indices(m)
    )
end

function constraint_user_constraint_indices(m::Model)
    unique(
        (user_constraint=uc, stochastic_path=path, t=t)
        for uc in user_constraint() for t in _constraint_user_constraint_lowest_resolution_t(m, uc)
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_user_constraint_indices(m, uc, t)),
        )
    )
end

"""
    constraint_user_constraint_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:user_constraint` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow`, `unit_flow_op`,
and `units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_user_constraint_indices_filtered(
    m::Model;
    user_constraint=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; user_constraint=user_constraint, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_user_constraint_indices(m))
end

"""
    _constraint_user_constraint_lowest_resolution_t(m, uc, t)

Find the lowest temporal resolution amoung the `unit_flow` variables appearing in the `user_constraint`.
"""
function _constraint_user_constraint_lowest_resolution_t(m, uc)
    t_lowest_resolution(ind.t for ind in _constraint_user_constraint_indices(m, uc))
end

"""
    _constraint_user_constraint_unit_flow_indices(uc, t)

Gather the `unit_flow` variable indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_unit_flow_indices(m, uc, t)
    (
        ind
        for (u, n, uc, d) in indices(unit_flow_coefficient;user_constraint=uc)
        for ind in unit_flow_indices(m; unit=u, node=n, direction=d, t=t)
    )
end

"""
    _constraint_user_constraint_units_on_indices(uc, t)

Gather the `units_on` variable indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_units_on_indices(m, uc, t)
    (
        ind
        for (u, uc) in unique(Iterators.flatten((
                   indices(units_on_coefficient;user_constraint=uc),
                   indices(units_started_up_coefficient;user_constraint=uc), 
                   )))
        for ind in units_on_indices(m; unit=u, t=t)
    )
end

"""
    _constraint_user_constraint_connection_flow_indices(uc, t)

Gather the `connection_flow` variable indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_connection_flow_indices(m, uc, t)
    (
        ind
        for (conn, n, uc, d) in indices(connection_flow_coefficient;user_constraint=uc)
        for ind in connection_flow_indices(m; connection=conn, node=n, direction=d, t=t)
    )
end

                                                                                        
"""
    _constraint_user_constraint_units_invested_indices(uc, t)

Gather the `units_invested` variable indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_units_invested_indices(m, uc, t)
    (
        ind
        for (u, uc) in unique(Iterators.flatten((
           indices(units_invested_available_coefficient;user_constraint=uc),
           indices(units_invested_coefficient;user_constraint=uc), 
           )))
        for ind in units_invested_available_indices(m; unit=u, t=t)
    )
end


"""
    _constraint_user_constraint_connections_invested_indices(uc, t)

Gather the `connections_invested` variable indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_connections_invested_indices(m, uc, t)
    (
        ind
        for (conn, uc) in unique(Iterators.flatten((
           indices(connections_invested_available_coefficient;user_constraint=uc),
           indices(connections_invested_coefficient;user_constraint=uc), 
           )))
        for ind in connections_invested_available_indices(m; connection=conn, t=t)
    )
end

"""
    _constraint_user_constraint_storages_invested_indices(uc, t)

Gather the `storages_invested` variable indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_storages_invested_indices(m, uc, t)
    (
        ind
        for (n, uc) in unique(Iterators.flatten((
           indices(storages_invested_available_coefficient;user_constraint=uc),
           indices(storages_invested_coefficient;user_constraint=uc), 
           )))
        for ind in storages_invested_available_indices(m; node=n, t=t)
    )
end


"""
    _constraint_user_constraint_node_stochastic_time_indices(m, uc, t)

Gather the `node_stochastic_time_indices` indices appearing in `add_constraint_user_constraint!`.
"""
function _constraint_user_constraint_node_stochastic_time_indices(m, uc, t)
    (
        ind
        for (n, uc) in unique(Iterators.flatten((
           indices(node_state_coefficient;user_constraint=uc),
           indices(demand_coefficient;user_constraint=uc), 
           )))
        for ind in node_stochastic_time_indices(m; node=n, t=t)
    )
end

"""
    _constraint_user_constraint_indices(m, uc, t)

Gather the `unit_flow`, `units_on`, `connection_flow`, `node_state` variables appearing in `add_constraint_user_constraint!`
"""
function _constraint_user_constraint_indices(m, uc, t=anything)
    t = t_in_t(m; t_long=t)
    Iterators.flatten((
        _constraint_user_constraint_unit_flow_indices(m, uc, t),
        _constraint_user_constraint_units_on_indices(m, uc, t),
        _constraint_user_constraint_connection_flow_indices(m, uc, t),
        _constraint_user_constraint_node_stochastic_time_indices(m, uc, t),
        _constraint_user_constraint_units_invested_indices(m, uc, t),
        _constraint_user_constraint_connections_invested_indices(m, uc, t),
        _constraint_user_constraint_storages_invested_indices(m, uc, t)
    ))
end
