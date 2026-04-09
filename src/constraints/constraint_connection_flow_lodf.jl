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

@doc raw"""
The N-1 security constraint for the post-contingency flow on monitored connection, ``c_{mon}``,
upon the outage of a contingency connection, ``c_{cont}``, is formed using line outage distribution factors (LODF).
``p^{lodf}_{(c_{cont}, c_{mon})}`` represents the fraction of the pre-contingency flow on connection ``c_{cont}`` that will flow
on ``c_{mon}`` if the former is disconnected.
If [connection](@ref) ``c_{cont}`` is disconnected, the post-contingency flow on the monitored connection
[connection](@ref) ``c_{mon}`` is the pre-contingency [connection\_flow](@ref) on ``c_{mon}`` plus the LODF
times the pre-contingency [connection\_flow](@ref) on ``c_{cont}``.
This post-contingency flow should be less than the [connection\_emergency\_capacity](@ref) of ``c_{mon}``.

```math
\begin{aligned}
& v^{connection\_flow}_{(c_{mon}, n_{mon\_to}, to\_node, s, t)}
- v^{connection\_flow}_{(c_{mon}, n_{mon\_to}, from\_node, s, t)} \\
& + p^{lodf}_{(c_{cont}, c_{mon})} \cdot \left(             
v^{connection\_flow}_{(c_{cont}, n_{cont\_to}, to\_node, s, t)}
- v^{connection\_flow}_{(c_{cont}, n_{cont\_to}, from\_node, s, t)}
\right) \\
& \leq min \left(
    p^{connection\_emergency\_capacity}_{(c_{mon}, n_{cont\_to}, to\_node, s, t)},
    p^{connection\_emergency\_capacity}_{(c_{mon}, n_{cont\_to}, from\_node,s ,t)}
\right) \\
& \forall (c_{mon}, c_{cont}) \in connection \times connection :
p^{is\_monitored}_{(c_{mon})} \land p^{is\_contingency}_{(c_{cont})} \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_connection_flow_lodf!(m::Model)
    rpts = join(report__output(output=output(:contingency_is_binding)), ", ", " and ")
    if !isempty(rpts)
        @info "skipping constraint connection_flow_lodf - instead will report contingency_is_binding in $rpts"
        return
    end
    _add_constraint!(
        m, :connection_flow_lodf, constraint_connection_flow_lodf_indices, _build_constraint_connection_flow_lodf
    )
end

function _build_constraint_connection_flow_lodf(m::Model, conn_cont, conn_mon, s_path, t)
    @fetch connection_flow = m.ext[:spineopt].variables
    @build_constraint(
        - connection_minimum_emergency_capacity(m, conn_mon, s_path, t)
        <=
        + connection_post_contingency_flow(m, connection_flow, conn_cont, conn_mon, s_path, t, sum)
        * maximum(connection_availability_factor(m; connection=conn_mon, stochastic_scenario=s, t=t) for s in s_path)
        <=
        + connection_minimum_emergency_capacity(m, conn_mon, s_path, t)
    )
end

function connection_post_contingency_flow(m, connection_flow, conn_cont, conn_mon, s_path, t, sum=sum)
    (
        # flow on monitored connection
        sum(
            + connection_flow[conn_mon, n_mon_to, direction(:to_node), s, t_short]
            - connection_flow[conn_mon, n_mon_to, direction(:from_node), s, t_short]
            for (conn_mon, n_mon_to, d, s, t_short) in connection_flow_indices(
                m;
                connection=conn_mon,
                last(connection__from_node(connection=conn_mon))...,
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            ); # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
            init=0,
        )
        # excess flow due to outage on contingency connection
        + lodf(m; connection1=conn_cont, connection2=conn_mon, t=t)
        * sum(
            + connection_flow[conn_cont, n_cont_to, direction(:to_node), s, t_short]
            - connection_flow[conn_cont, n_cont_to, direction(:from_node), s, t_short]
            for (conn_cont, n_cont_to, d, s, t_short) in connection_flow_indices(
                m;
                connection=conn_cont,
                last(connection__from_node(connection=conn_cont))...,
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );  # NOTE: always assume the second (last) node in `connection__from_node` is the 'to' node
            init=0,
        )
    )
end

function connection_minimum_emergency_capacity(m, conn_mon, s_path, t)
    minimum(
        + connection_emergency_capacity(m; connection=conn_mon, node=n_mon, direction=d, stochastic_scenario=s, t=t)
        * connection_availability_factor(m; connection=conn_mon, stochastic_scenario=s, t=t)
        * connection_conv_cap_to_flow(m; connection=conn_mon, node=n_mon, direction=d, stochastic_scenario=s, t=t)
        for (conn_mon, n_mon, d) in indices(connection_emergency_capacity; connection=conn_mon)
        for s in s_path
    )
end

function constraint_connection_flow_lodf_indices(m::Model)
    (
        (connection_contingency=conn_cont, connection_monitored=conn_mon, stochastic_path=path, t=t)
        for (conn_cont, conn_mon) in lodf_connection__connection()
        if all(
            [
                connection_contingency(connection=conn_cont, _default=false),
                connection_monitored(connection=conn_mon, _default=false),
                has_lodf(connection=conn_cont),
                has_lodf(connection=conn_mon)
            ]
        )
        for (t, path) in t_lowest_resolution_path(
            m, 
            x
            for conn in (conn_cont, conn_mon)
            for x in connection_flow_indices(m; connection=conn, last(connection__from_node(connection=conn))...)
            if _check_ptdf_duration(m, x.t, conn_cont, conn_mon)
        )
    )
end

"""
    constraint_connection_flow_lodf_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:connection_flow_lodf` constraint.

Uses stochastic path indices due to potentially different stochastic structures between `connection_flow` variables.
Keyword arguments can be used for filtering the resulting Array.
"""
function constraint_connection_flow_lodf_indices_filtered(
    m::Model;
    connection_contingency=anything,
    connection_monitored=anything,
    stochastic_path=anything,
    t=anything,
)
    function f(ind)
        _index_in(
            ind;
            connection_contingency=connection_contingency,
            connection_monitored=connection_monitored,
            stochastic_path=stochastic_path,
            t=t,
        )
    end
    filter(f, constraint_connection_flow_lodf_indices(m))
end
