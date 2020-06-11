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
	_nonempty_t_before_t(t_after)

A guaranteed non-empty `Array` of `TimeSlice`s that come `before` the given `t_after`.
"""
function _nonempty_t_before_t(t_after)
	std_t_before_t = t_before_t(t_after=t_after)
	isempty(std_t_before_t) || return std_t_before_t
    duration_unit = _model_duration_unit()
    to_time_slice(t_after - duration_unit(duration(t_after)))
end

"""
	_take_one_t_before_t(t_after)

An iterator that produces the first `TimeSlice` that comes `before` the given `t_after`
"""
_take_one_t_before_t(t_after) = Iterators.take(_nonempty_t_before_t(t_after), 1)


"""
    _constraint_unit_flow_capacity_indices(unit, node, direction, t)

An iterator that concatenates `unit_flow_indices` and `units_on_indices` for the given inputs.
"""
function _constraint_unit_flow_capacity_indices(unit, node, direction, t)
    Iterators.flatten(
        (
            unit_flow_indices(unit=unit, node=node, direction=direction, t=t), 
            units_on_indices(unit=unit, t=t_in_t(t_long=t))
        )
    )
end

function save_all_marginals(m::Model)
    save_marginals!(m, :units_available)
end

function save_marginals!(m::Model, name::Symbol)
    inds = keys(m.ext[:constraints][name])
    con = m.ext[:constraints][name]

    m.ext[:marginals][name] = Dict(
        ind => JuMP.shadow_price(con[ind]) for ind in inds if end_(ind.t) <= end_(current_window)
    )
end