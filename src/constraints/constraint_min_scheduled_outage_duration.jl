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
Schedules maintenance outages for each [unit](@ref) with [outage\_scheduled\_duration](@ref) defined.
Over the optimisation window, the unit must spend in total the scheduled outage duration out of service,
once for each of its units. The constraint sets both a lower and an upper bound:

```math
\begin{aligned}
& \sum_{t} v^{units\_out\_of\_service}_{(u,s_t,t)} \cdot \Delta t
\geq D_u \\
& \sum_{t} v^{units\_out\_of\_service}_{(u,s_t,t)} \cdot \Delta t
\leq D_u + \Delta t^{max}_u \\
& \forall u \in indices(p^{outage\_scheduled\_duration})
\end{aligned}
```

where
- the sums run over the time slices ``t`` of the optimisation window, and ``s_t`` is the scenario
  of the stochastic path that is active at ``t``,
- ``D_u = p^{outage\_scheduled\_duration}_{(u)} \cdot \left(p^{existing\_units}_{(u)} + p^{investment\_count\_max\_cumulative}_{(u)}\right)``,
  with the number of units rounded to an integer and the largest value taken over the scenarios of the path,
- ``\Delta t`` is the duration of time slice ``t``,
- ``\Delta t^{max}_u`` is the longest resolution among the unit's [units\_on\_\_temporal\_block](@ref)s,
  which leaves room for outages that do not line up exactly with the time slices.

The model decides when the outages take place within the window.

See also
[outage\_scheduled\_duration](@ref),
[outage\_variable\_type](@ref)
"""
function add_constraint_min_scheduled_outage_duration!(m::Model)
    _add_constraint!(
        m,
        :min_scheduled_outage_duration,
        constraint_min_scheduled_outage_duration_indices,
        _build_constraint_min_scheduled_outage_duration,
    )
end

function _build_constraint_min_scheduled_outage_duration(m::Model, u, s_path, t, bound)
    _build_constraint_min_scheduled_outage_duration(m::Model, u, s_path, t, Val(bound.name))
end

function _build_constraint_min_scheduled_outage_duration(m::Model, u, s_path, t, ::Val{:lb})
    max_sch_out_dur = _max_sch_out_dur(m, u, s_path, t)
    @build_constraint(
        + (max_sch_out_dur / _model_duration_unit(m.ext[:spineopt].instance)(1))
        <=
        + _units_out_of_service_sum(m, u, s_path, t)
    )
end

function _build_constraint_min_scheduled_outage_duration(m::Model, u, s_path, t, ::Val{:ub})
    max_sch_out_dur = _max_sch_out_dur(m, u, s_path, t)
    max_err = maximum(_maximum(resolution(temporal_block=tb)) for tb in units_on__temporal_block(unit=u))
    @build_constraint(
        + _units_out_of_service_sum(m, u, s_path, t)
        <=
        + (_minute(max_sch_out_dur) + _minute(max_err)) / _model_duration_unit(m.ext[:spineopt].instance)(1)
    )
end

_minute(x::Call) = Call(_minute, [x])
_minute(x) = Minute(x)

function _units_out_of_service_sum(m::Model, u, s_path, t)
    @fetch units_out_of_service = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            units_out_of_service[u, s, t] * duration(t)
            for (u, s, t) in units_out_of_service_indices(m; unit=u, stochastic_scenario=s_path);
            init=0,
        )
    )
end

function _max_sch_out_dur(m::Model, u, s_path, t)
    maximum(
        (
            + outage_scheduled_duration(m; unit=u, stochastic_scenario=s, t=t)
            * round(
                + existing_units(m; unit=u, stochastic_scenario=s, t=t, _default=_default_nb_of_units(u))
                + investment_count_max_cumulative(m; unit=u, stochastic_scenario=s, t=t, _default=0)
            )
        )
        for s in s_path
    )
end

_maximum(x::T) where T<:Vector = maximum(x)
_maximum(x) = x

"""
    constraint_scheduled_outage_duration_indices(m::Model, unit, t)
    
Creates all indices required to include units, stochastic paths and a reference temporal for `add_constraint_scheduled_outage_duration!`
constraint generation.
"""
function constraint_min_scheduled_outage_duration_indices(m::Model)
    (
        (unit=u, stochastic_path=path, t=current_window(m), bound=bound)
        for u in indices(outage_scheduled_duration)
        for path in active_stochastic_paths(m, units_out_of_service_indices(m; unit=u))
        for bound in (Object(:lb, :bound), Object(:ub, :bound))
    )
end
