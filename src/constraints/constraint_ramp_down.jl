#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

@doc raw"""
    add_constraint_ramp_down!(m::Model)

    #description
    Limit the decrease of `unit_flow` over a time period of one `duration_unit` according
    to the `shut_down_limit` and `ramp_down_limit` parameter values.
    #end description

    #formulation
    ```math
    \begin{aligned}
    & \sum_{
        \substack{
            (u,n,d,s,t) \in unit\_flow\_indices \\
            n \in ng, \, s \in s_{path}, \, t = t_{before} \\
            !p_{is\_reserve}(n)
        }
    }
    v_{unit\_flow}(u,n,d,s,t) \\
    & - \sum_{
        \substack{
            (u,n,d,s,t) \in unit\_flow\_indices \\
            n \in ng, \, s \in s_{path}, \, t = t_{after} \\
            !p_{is\_reserve}(n)
        }
    }
    v_{unit\_flow}(u,n,d,s,t) \\
    & + \sum_{
        \substack{
            (u,n,d,s,t) \in unit\_flow\_indices \\
            n \in ng, \, s \in s_{path}, \, t = t_{after} \\
            p_{is\_reserve}(n), \, p_{downward\_reserve}(n)
        }
    }
    v_{unit\_flow}(u,n,d,s,t) \\
    & <= ( \\
    & \sum_{
        \substack{
            (u,s,t) \in units\_on\_indices \\ s \in s_{path}, \, t = t_{after}
        }
    }
    (p_{shut\_down\_limit}(u,ng,d,s,t) - p_{minimum\_operating\_point}(u,ng,d,s,t) - p_{ramp\_down\_limit}(u,ng,d,s,t)) \cdot v_{units\_shut\_down}(u,s,t) \\
    & + \sum_{
        \substack{
            (u,s,t) \in units\_on\_indices \\ s \in s_{path}, \, t = t_{before}
        }
    }
    (p_{minimum\_operating\_point}(u,ng,d,s,t) + p_{ramp\_down\_limit}(u,ng,d,s,t)) \cdot v_{units\_on}(u,s,t) \\
    & - \sum_{
        \substack{
            (u,s,t) \in units\_on\_indices \\ s \in s_{path}, \, t = t_{after}
        }
    }
    p_{minimum\_operating\_point}(u,ng,d,s,t) \cdot v_{units\_on}(u,s,t) \\
    & ) \cdot p_{unit\_capacity}(u,ng,d,s,t_{after}) \cdot p_{conv\_cap\_to\_flow}(u,ng,d,s,t_{after}) \cdot \Delta t_{after} \\
    & \forall (u,ng,d) \in ind(p_{ramp\_down\_limit}) \cup ind(p_{shut\_down\_limit}), \\
    & \forall (ng,t_{before},t_{after}) \in node\_dynamic\_time\_indices(ng), \\
    & \forall s_{path} \in stochastic\_paths(t_{before},t_{after})
    \end{aligned}
    ```
    #end formulation
"""
function add_constraint_ramp_down!(m::Model)
    @fetch units_on, units_shut_down, unit_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:ramp_down] = Dict(
        (unit=u, node=ng, direction=d, stochastic_path=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            + expr_sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_before, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_before)
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            - expr_sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_after)
                )
                if !is_reserve_node(node=n);
                init=0,
            )
            + expr_sum(
                + unit_flow[u, n, d, s, t] * overlap_duration(t_after, t)
                for (u, n, d, s, t) in unit_flow_indices(
                    m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t_overlaps_t(m; t=t_after)
                )
                if _is_reserve_node(n, d; to_node=downward_reserve, from_node=upward_reserve)
                && !is_non_spinning(node=n);
                init=0,
            )
            <=
            + (
                + expr_sum(
                    + (
                        + _shut_down_limit(u, ng, d, s, t0, t_after)
                        - _minimum_operating_point(u, ng, d, s, t0, t_after)
                        - _ramp_down_limit(u, ng, d, s, t0, t_after)
                    )
                    * units_shut_down[u, s, t]
                    - _minimum_operating_point(u, ng, d, s, t0, t_after)
                    * units_on[u, s, t]
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_after);
                    init=0
                )
                + expr_sum(
                    + (_minimum_operating_point(u, ng, d, s, t0, t_after) + _ramp_down_limit(u, ng, d, s, t0, t_after))
                    * units_on[u, s, t]
                    for (u, s, t) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_before);
                    init=0
                )
            )
            * _unit_flow_capacity(u, ng, d, s, t0, t_after)
            * duration(t_after)
        )
        for (u, ng, d, s, t_before, t_after) in constraint_ramp_down_indices(m)
    )
end

function _ramp_down_limit(u, ng, d, s, t0, t)
    ramp_down_limit[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function constraint_ramp_down_indices(m::Model)
    unique(
        (unit=u, node=ng, direction=d, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, ng, d) in Iterators.flatten((indices(ramp_down_limit), indices(shut_down_limit)))
        for (u, t_before, t_after) in unit_dynamic_time_indices(m; unit=u)
        for path in active_stochastic_paths(
            m,
            [
                unit_flow_indices(m; unit=u, node=ng, direction=d, t=_overlapping_t(m, t_before, t_after));
                units_on_indices(m; unit=u, t=[t_before, t_after])
            ]
        )
    )
end

"""
    constraint_ramp_down_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:ramp_down` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ramp_down_indices_filtered(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    function f(ind)
        _index_in(
            ind;
            unit=unit,
            node=node,
            direction=direction,
            stochastic_path=stochastic_path,
            t_before=t_before,
            t_after=t_after,
        )
    end

    filter(f, constraint_ramp_down_indices(m))
end
