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
    _constraint_unit_flow_capacity_indices(m::Model, unit, node, direction, t)

An iterator that concatenates `unit_flow_indices` and `units_on_indices` for the given inputs.
"""
function _constraint_unit_flow_capacity_indices(m::Model, unit, node, direction, t)
    Iterators.flatten((
        unit_flow_indices(m; unit=unit, node=node, direction=direction, t=t),
        units_on_indices(m; unit=unit, t=t_in_t(m; t_long=t)),
    ))
end
