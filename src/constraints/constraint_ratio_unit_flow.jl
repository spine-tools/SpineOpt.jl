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
By specifying the parameters [fix\_ratio\_out\_in\_unit\_flow](@ref),
[fix\_ratio\_in\_out\_unit\_flow](@ref), [fix\_ratio\_in\_in\_unit\_flow](@ref),
and/or [fix\_ratio\_out\_out\_unit\_flow](@ref),
a **fix** ratio can be set between, respectively,
**out**going and **in**coming flows from and to a unit,
**in**coming and **out**going flows to and from a unit,
two **in**coming flows to a unit,
and/or two **out**going flows from a unit.

Similary, a **minimum** ratio between flows can be set by specifying [min\_ratio\_out\_in\_unit\_flow](@ref),
[min\_ratio\_in\_out\_unit\_flow](@ref), [min\_ratio\_in\_in\_unit\_flow](@ref),
and/or [min\_ratio\_out\_out\_unit\_flow](@ref).

Finally, a **maximum** ratio can be set by specifying [max\_ratio\_out\_in\_unit\_flow](@ref),
[max\_ratio\_in\_out\_unit\_flow](@ref), [max\_ratio\_in\_in\_unit\_flow](@ref),
and/or [max\_ratio\_out\_out\_unit\_flow](@ref).

For example, whenever there is only a single input node and a single output node,
[fix\_ratio\_out\_in\_unit\_flow](@ref) relates to the notion of efficiency.
Also, [fix\_ratio\_in\_out\_unit\_flow](@ref) can for instance be used to relate emissions to input primary fuel flows.

The constraint below is written for [fix\_ratio\_out\_in\_unit\_flow](@ref), but equivalent formulations
exist for the other 11 cases described above.


```math
\begin{aligned}
& \sum_{n \in ng_{out}} v^{unit\_flow}_{(u,n,from\_node,s,t)} \\
& = \\
& p^{fix\_ratio\_out\_in\_unit\_flow}_{(u, ng_{out}, ng_{in},s,t)}
\cdot \sum_{n \in ng_{in}} v^{unit\_flow}_{(u,n,to\_node,s,t)} \\
& + p^{fix\_units\_on\_coefficient\_out\_in}_{(u,ng_{out},ng_{in},s,t)} \cdot v^{units\_on}_{(u,s,t)}  \\
& \forall (u, ng_{out}, ng_{in}) \in indices(p^{fix\_ratio\_out\_in\_unit\_flow}) \\
& \forall (s,t)
\end{aligned}
```

!!! note
    If any of the above mentioned ratio parameters is specified for a node group,
    then the ratio is enforced over the *sum* of flows from or to that group.
    In this case, there remains a degree of freedom regarding the composition of flows within the group.

See also [fix\_ratio\_out\_in\_unit\_flow](@ref), [fix\_units\_on\_coefficient\_out\_in](@ref).
"""
function add_constraint_ratio_unit_flow!(m::Model, ratio, units_on_coefficient, sense, d1, d2)
    # NOTE: that the `<sense>_ratio_<directions>_unit_flow` parameter uses the stochastic dimensions of the second
    # <direction>!
    @fetch unit_flow = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[ratio.name] = Dict(
        (unit=u, node1=ng1, node2=ng2, stochastic_path=s_path, t=t) => sense_constraint(
            m,
            + sum(
                get(unit_flow, (u, n1, d1, s, t_short), 0)
                * duration(t_short)
                for n1 in members(ng1), s in s_path, t_short in t_in_t(m; t_long=t);
                init=0,
            ),
            sense,
            + sum(
                get(unit_flow, (u, n2, d2, s, t_short), 0)
                * duration(t_short)
                * ratio(m; unit=u, node1=ng1, node2=ng2, stochastic_scenario=s, analysis_time=t0, t=t)
                for n2 in members(ng2), s in s_path, t_short in t_in_t(m; t_long=t);
                init=0,
            )
            + sum(
                _get_units_on(m, u, s, t1)
                * min(duration(t1), duration(t))
                * units_on_coefficient(m; unit=u, node1=ng1, node2=ng2, stochastic_scenario=s, analysis_time=t0, t=t)
                for (u, s, t1) in unit_stochastic_time_indices(
                    m; unit=u, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
                );
                init=0,
            )
        )
        for (u, ng1, ng2, s_path, t) in constraint_ratio_unit_flow_indices(m, ratio, d1, d2)
    )
end

"""
    add_constraint_fix_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_out_in_unit_flow, fix_units_on_coefficient_out_in, ==, direction(:to_node), direction(:from_node)
    )
end

"""
    add_constraint_max_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_out_in_unit_flow, max_units_on_coefficient_out_in, <=, direction(:to_node), direction(:from_node)
    )
end

"""
    add_constraint_min_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_out_in_unit_flow, min_units_on_coefficient_out_in, >=, direction(:to_node), direction(:from_node)
    )
end

"""
    add_constraint_fix_ratio_in_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_in_in_unit_flow, fix_units_on_coefficient_in_in, ==, direction(:from_node), direction(:from_node)
    )
end

"""
    add_constraint_max_ratio_in_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_in_in_unit_flow, max_units_on_coefficient_in_in, <=, direction(:from_node), direction(:from_node)
    )
end

"""
    add_constraint_min_ratio_in_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_in_in_unit_flow, min_units_on_coefficient_in_in, >=, direction(:from_node), direction(:from_node)
    )
end

"""
    add_constraint_max_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_out_out_unit_flow, fix_units_on_coefficient_out_out, ==, direction(:to_node), direction(:to_node)
    )
end

"""
    add_constraint_max_ratio_out_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_out_out_unit_flow, max_units_on_coefficient_out_out, <=, direction(:to_node), direction(:to_node)
    )
end

"""
    add_constraint_min_ratio_out_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_out_out_unit_flow, min_units_on_coefficient_out_out, >=, direction(:to_node), direction(:to_node)
    )
end

"""
    add_constraint_fix_ratio_in_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_in_out_unit_flow, fix_units_on_coefficient_in_out, ==, direction(:from_node), direction(:to_node)
    )
end

"""
    add_constraint_max_ratio_in_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_in_out_unit_flow, max_units_on_coefficient_in_out, <=, direction(:from_node), direction(:to_node)
    )
end

"""
    add_constraint_min_ratio_in_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_in_out_unit_flow, min_units_on_coefficient_in_out, >=, direction(:from_node), direction(:to_node)
    )
end

function constraint_ratio_unit_flow_indices(m::Model, ratio, d1, d2)
    (
        (unit=u, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (u, n1, n2) in indices(ratio)
        for (t, path) in t_lowest_resolution_path(
            m,
            unit_flow_indices(m; unit=u, node=[n1, n2]),
            unit_flow_indices(m; unit=u, node=n1, direction=d1),
            unit_flow_indices(m; unit=u, node=n2, direction=d2),
            units_on_indices(m; unit=u),
        )
    )
end

"""
    constraint_ratio_unit_flow_indices_filtered(m::Model, ratio, d1, d2; filtering_options...)

Form the stochastic indexing Array for the `:ratio_unit_flow` constraint for the desired `ratio` and direction pair
`d1` and `d2`.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and
`units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_unit_flow_indices_filtered(
    m::Model,
    ratio,
    d1,
    d2;
    unit=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; unit=unit, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ratio_unit_flow_indices(m, ratio, d1, d2))
end
