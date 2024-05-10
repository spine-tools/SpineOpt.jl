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

@doc raw"""
By defining the parameters [fix\_ratio\_out\_in\_connection\_flow](@ref),
[max\_ratio\_out\_in\_connection\_flow](@ref) or [min\_ratio\_out\_in\_connection\_flow](@ref),
a ratio can be set between **out**going and **in**coming flows from and to a connection.

The constraint below is written for [fix\_ratio\_out\_in\_connection\_flow](@ref), but equivalent formulations
exist for the other two cases.

```math
\begin{aligned}
& \sum_{n \in ng_{out}} v^{connection\_flow}_{(conn,n,from\_node,s,t)} \\
& = \\
& p^{fix\_ratio\_out\_in\_connection\_flow}_{(conn, ng_{out}, ng_{in},s,t)}
\cdot \sum_{n \in ng_{in}} v^{connection\_flow}_{(conn,n,to\_node,s,t)} \\
& \forall (conn, ng_{out}, ng_{in}) \in indices(p^{fix\_ratio\_out\_in\_connection\_flow}) \\
& \forall (s,t)
\end{aligned}
```

!!! note
    If any of the above mentioned ratio parameters is specified for a node group,
    then the ratio is enforced over the *sum* of flows from or to that group.
    In this case, there remains a degree of freedom regarding the composition of flows within the group.
    
See also [fix\_ratio\_out\_in\_connection\_flow](@ref).
"""
function add_constraint_ratio_out_in_connection_flow!(m::Model, ratio_out_in, sense)
    _add_constraint!(
        m,
        ratio_out_in.name,
        m -> constraint_ratio_out_in_connection_flow_indices(m, ratio_out_in),
        (m, ind...) -> _build_constraint_ratio_out_in_connection_flow(m, ind..., ratio_out_in, sense),
    )
end

function _build_constraint_ratio_out_in_connection_flow(m::Model, conn, ng_out, ng_in, s_path, t, ratio_out_in, sense)
    # NOTE: the `<sense>_ratio_<directions>_connection_flow` parameter uses the stochastic dimensions
    # of the second <direction>!
    @fetch connection_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    build_sense_constraint(
        + sum(
            + connection_flow[conn, n_out, d, s, t_short] * duration(t_short)
            for (conn, n_out, d, s, t_short) in connection_flow_indices(
                m;
                connection=conn,
                node=ng_out,
                direction=direction(:to_node),
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );
            init=0,
        ),
        sense,
        + sum(
            + connection_flow[conn, n_in, d, s, t_short]
            * ratio_out_in(
                m; connection=conn, node1=ng_out, node2=ng_in, stochastic_scenario=s, analysis_time=t0, t=t_short
            )
            * overlap_duration(t_short, _delayed_t(conn, ng_out, ng_in, t0, s, t))
            for (conn, n_in, d, s, t_short) in connection_flow_indices(
                m;
                connection=conn,
                node=ng_in,
                direction=direction(:from_node),
                stochastic_scenario=s_path,
                t=_to_delayed_time_slice(m, conn, ng_out, ng_in, s_path, t)
            );
            init=0,
        ),
    )
end

"""
    add_constraint_fix_ratio_out_in_connection_flow!(m::Model)

Call `add_constraint_ratio_out_in_connection_flow!` using the `fix_ratio_out_in_connection_flow` parameter.
"""
function add_constraint_fix_ratio_out_in_connection_flow!(m::Model)
    add_constraint_ratio_out_in_connection_flow!(m, fix_ratio_out_in_connection_flow, ==)
end

"""
    add_constraint_max_ratio_out_in_connection_flow!(m::Model)

Call `add_constraint_ratio_out_in_connection_flow!` using the `max_ratio_out_in_connection_flow` parameter.
"""
function add_constraint_max_ratio_out_in_connection_flow!(m::Model)
    add_constraint_ratio_out_in_connection_flow!(m, max_ratio_out_in_connection_flow, <=)
end

"""
    add_constraint_min_ratio_out_in_connection_flow!(m::Model)

Call `add_constraint_ratio_out_in_connection_flow!` using the `min_ratio_out_in_connection_flow` parameter.
"""
function add_constraint_min_ratio_out_in_connection_flow!(m::Model)
    add_constraint_ratio_out_in_connection_flow!(m, min_ratio_out_in_connection_flow, >=)
end

function constraint_ratio_out_in_connection_flow_indices(m::Model, ratio_out_in)
    (
        (connection=conn, node1=ng_out, node2=ng_in, stochastic_path=path, t=t)
        for (conn, ng_out, ng_in) in indices(ratio_out_in)
        if _fix_ratio_out_in_connection_flow_simple(conn, ng_out, ng_in) === nothing
        for (t, path_out) in t_lowest_resolution_path(
            m, connection_flow_indices(m; connection=conn, node=ng_out, direction=direction(:to_node))
        )
        for path in active_stochastic_paths(
            m, 
            Iterators.flatten(
                (
                    ((stochastic_scenario=s,) for s in path_out),
                    (
                        ind
                        for s in path_out
                        for ind in connection_flow_indices(
                            m;
                            connection=conn,
                            node=ng_in,
                            direction=direction(:from_node),
                            t=_to_delayed_time_slice(m, conn, ng_out, ng_in, s, t)
                        )
                    ),
                )
            )
        )
    )
end

function _to_delayed_time_slice(m, conn, ng_out, ng_in, s, t)
    t0 = _analysis_time(m)
    to_time_slice(m; t=_delayed_t(conn, ng_out, ng_in, t0, s, t))
end

function _delayed_t(conn, ng_out, ng_in, t0, s, t)
    t - connection_flow_delay(connection=conn, node1=ng_out, node2=ng_in, analysis_time=t0, stochastic_scenario=s, t=t)
end

"""
    constraint_ratio_out_in_connection_flow_indices_filtered(m::Model, ratio_out_in; filtering_options...)

Form the stochastic indexing Array for the `:ratio_out_in_connection_flow` constraint for the desired `ratio_out_in`.

Uses stochastic path indices due to potentially different stochastic structures between `connection_flow` variables.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_out_in_connection_flow_indices_filtered(
    m::Model,
    ratio_out_in;
    connection=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; connection=connection, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ratio_out_in_connection_flow_indices(m, ratio_out_in))
end
