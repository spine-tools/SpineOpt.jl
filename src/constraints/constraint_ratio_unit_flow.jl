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


If an array type [fix\_ratio\_in\_out\_unit\_flow](@ref) is defined, the constraint implements a standard piecewise
linear ratio (incremental heat rate):

```math
\begin{aligned}
& v^{unit\_flow}_{(u, n_{in}, d, s, t)} \\
& = \sum_{op=1}^{\left\|p^{operating\_points}_{(u,n,d)}\right\|} p^{fix\_ratio\_in\_out\_unit\_flow}_{(u, n_{in}, n_{out}, op, s, t)}
\cdot v^{unit\_flow\_op}_{(u, n_{out}, d, op, s, t)} \\
& + p^{fix\_units\_on\_coefficient\_in\_out}_{(u, n_{in}, n_{out}, s, t)} \cdot v^{units\_on}_{(u, s, t)} \\
& + p^{unit\_start\_flow}_{(u, n_{in}, n_{out}, s, t)} \cdot v^{units\_started\_up}_{(u, s, t)} \\
& \forall (u,n_{in},n_{out}) \in indices(p^{fix\_ratio\_in\_out\_unit\_flow}) \\
& \forall (s,t)
\end{aligned}
```
See also [fix\_ratio\_in\_out\_unit\_flow](@ref), [fix\_units\_on\_coefficient\_in\_out](@ref).
"""
function add_constraint_ratio_unit_flow!(m::Model, ratio)
    _add_constraint!(
        m,
        ratio.name,
        m -> constraint_ratio_unit_flow_indices(m, ratio),
        (m, ind...) -> _build_constraint_ratio_unit_flow(m, ind..., ratio),
    )
end

function _build_constraint_ratio_unit_flow(m::Model, u1, ng1, d1, u2, ng2, d2, s_path, t, ratio)
    # NOTE: that the `<sense>_ratio_<directions>_unit_flow` parameter uses the stochastic dimensions of the second
    # <direction>!
    sense = _ratio_to_sense(ratio)
    units_on_coeff = _ratio_to_units_on_coeff(ratio)
    start_flow_sign = _ratio_and_directions_to_start_flow_sign(ratio, d1, d2)
    @fetch unit_flow, unit_flow_op = m.ext[:spineopt].variables
    build_sense_constraint(
        + sum(
            get(unit_flow, (u1, n1, d1, s, t_short), 0)
            * duration(t_short)
            for n1 in members(ng1), s in s_path, t_short in t_in_t(m; t_long=t);
            init=0,
        ),
        sense,
        + sum(
            get(unit_flow_op, (u2, n2, d2, op, s, t_short), 0)
            * duration(t_short)
            * ratio(
                m; 
                unit1=u1, node1=ng1, direction1=d1, 
                unit2=u2, node2=ng2, direction2=d2, 
                i=op, stochastic_scenario=s, t=t
            )
            for (u2, n2, d2, op, s, t_short) in unit_flow_op_indices(
                m;
                unit=u2,
                node=members(ng2),
                direction=d2,
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            );
            init=0,
        )
        + sum(
            get(unit_flow, (u2, n2, d2, s, t_short), 0)
            * duration(t_short)
            * ratio(
                m; 
                unit1=u1, node1=ng1, direction1=d1, 
                unit2=u2, node2=ng2, direction2=d2, 
                stochastic_scenario=s, t=t
            )
            for (u2, n2, d2, s, t_short) in unit_flow_indices(
                m;
                unit=u2,
                node=members(ng2),
                direction=d2,
                stochastic_scenario=s_path,
                t=t_in_t(m; t_long=t),
            )
            if isempty(unit_flow_op_indices(m; unit=u2, node=n2, direction=d2));
            init=0,
        )
        + sum(
            _get_units_on(m, u2, s, t1)
            * min(duration(t1), duration(t))
            * units_on_coeff(
                m; 
                unit1=u1, node1=ng1, direction1=d1, 
                unit2=u2, node2=ng2, direction2=d2, 
                stochastic_scenario=s, t=t
            )
            + start_flow_sign
            * _get_units_started_up(m, u2, s, t1)
            * min(duration(t1), duration(t))
            * unit_start_flow(
                m; 
                unit1=u1, node1=ng1, direction1=d1, 
                unit2=u2, node2=ng2, direction2=d2, 
                stochastic_scenario=s, t=t
            )
            for (u2, s, t1) in unit_stochastic_time_indices(
                m; unit=u2, stochastic_scenario=s_path, t=t_overlaps_t(m; t=t)
            );
            init=0,
        )
    )
end

"""
    add_constraint_fix_ratio_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter.
"""
function add_constraint_fix_ratio_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(m, constraint_equality_flow_ratio)
end


"""
    add_constraint_min_ratio_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter.
"""
function add_constraint_min_ratio_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(m, constraint_greater_than_flow_ratio)
end

"""
    add_constraint_max_ratio_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter.
"""
function add_constraint_max_ratio_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(m, constraint_less_than_flow_ratio)
end


function constraint_ratio_unit_flow_indices(m::Model, ratio)
    (
        (unit1=u1, node1=n1, direction1=d1, unit2=u2, node2=n2, direction2=d2, stochastic_path=path, t=t)
        for (u1, n1, d1, u2, n2, d2) in indices(ratio)
        if !_has_simple_fix_ratio_unit_flow(m, u1, n1, d1, u2, n2, d2, ratio)
        for (t, path) in t_lowest_resolution_path(
            m,
            unit_flow_indices(m; unit=u1, node=[n1, n2]), # What is this doing?
            unit_flow_indices(m; unit=u2, node=[n1, n2]), # What is this doing?
            unit_flow_indices(m; unit=u1, node=n1, direction=d1),
            unit_flow_indices(m; unit=u2, node=n2, direction=d2),
            units_on_indices(m; unit=u2),
        )
    )
end

function _ratio_to_units_on_coeff(ratio)
    Dict(
        constraint_equality_flow_ratio => constraint_equality_online_coefficient,
        constraint_less_than_flow_ratio => constraint_less_than_online_coefficient,
        constraint_greater_than_flow_ratio => constraint_greater_than_online_coefficient,
    )[ratio]
end

function _ratio_to_sense(ratio)
    Dict(
        constraint_equality_flow_ratio => ==,
        constraint_less_than_flow_ratio => <=,
        constraint_greater_than_flow_ratio => >=,
    )[ratio]
end

function _ratio_and_directions_to_start_flow_sign(ratio::Parameter, d1::Object, d2::Object)
    if ratio === constraint_equality_flow_ratio
        flow_signs = Dict((:to_node, :from_node) => -1, (:from_node, :to_node) => 1)
        get(flow_signs, (d1.name, d2.name), 0)
    else 
        0
    end
end

"""
    constraint_ratio_unit_flow_indices_filtered(m::Model, ratio, d1, d2; filtering_options...)

Form the stochastic indexing Array for the `:ratio_unit_flow` constraint for the desired `ratio`.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and
`units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_unit_flow_indices_filtered(
    m::Model,
    ratio;
    unit1=anything,
    node1=anything,
    d1=anything,
    unit2=anything,
    node2=anything,
    d2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(
        ind; 
        unit1=unit1, node1=node1, direction1=d1, 
        unit2=unit2, node2=node2, direction2=d2,
        stochastic_path=stochastic_path, t=t
    )
    filter(f, constraint_ratio_unit_flow_indices(m, ratio))
end
