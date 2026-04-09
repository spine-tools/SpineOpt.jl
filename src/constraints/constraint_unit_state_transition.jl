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
The units on status is constrained by shutting down and starting up actions. This transition is defined as follows:

```math
\begin{aligned}
& v^{units\_on}_{(u,s,t)} - v^{units\_started\_up}_{(u,s,t)} + v^{units\_shut\_down}_{(u,s,t)} = v^{units\_on}_{(u,s,t-1)} \\
& \forall u \in unit \\
& \forall (s,t)
\end{aligned}
```
"""
function add_constraint_unit_state_transition!(m::Model)
    _add_constraint!(
        m, :unit_state_transition, constraint_unit_state_transition_indices, _build_constraint_unit_state_transition
    )
end

function _build_constraint_unit_state_transition(m::Model, u, s_path, t_before, t_after)
    @fetch units_on, units_started_up, units_shut_down = m.ext[:spineopt].variables
    # TODO: add support for units that start_up over multiple timesteps?
    # TODO: use :integer, :binary, :linear as parameter values -> reusable for other pruposes
    @build_constraint(
        sum(
            + units_on[u, s, t_after] - units_started_up[u, s, t_after] + units_shut_down[u, s, t_after]
            for (u, s, t_after) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_after);
            init=0,
        )
        ==
        sum(
            + units_on[u, s, t_before]
            for (u, s, t_before) in units_on_indices(m; unit=u, stochastic_scenario=s_path, t=t_before);
            init=0,
        )
    )
end

function constraint_unit_state_transition_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t_before=t_before, t_after=t_after)
        for (u, t_before, t_after) in unit_dynamic_time_indices(m; unit=_unit_with_switched_variable())
        for path in active_stochastic_paths(m, units_on_indices(m; unit=u, t=[t_before, t_after]))
    )
end

"""
    constraint_unit_state_transition_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:unit_state_transition` constraint.

Uses stochastic path indices due to potentially different stochastic scenarios between `t_after` and `t_before`.
Keyword arguments can be used to filter the resulting Array.
"""
function constraint_unit_state_transition_indices_filtered(
    m::Model;
    unit=anything,
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    f(ind) = _index_in(ind; unit=unit, stochastic_path=stochastic_path, t_before=t_before, t_after=t_after)
    filter(f, constraint_unit_state_transition_indices(m))
end
