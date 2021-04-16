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
    add_constraint_max_cum_in_unit_flow_bound!(m::Model)

Set upperbound `max_cum_in_flow_bound `to the cumulated inflow into a `unit_group ug`
if `max_cum_in_unit_flow_bound` exists.
"""
function add_constraint_max_cum_in_unit_flow_bound!(m::Model)
    @fetch unit_flow = m.ext[:variables]
    m.ext[:constraints][:max_cum_in_unit_flow_bound] = Dict(
        (unit_group=ug,) => @constraint( # TODO: How to turn this one into stochastical one? Path indexing over the whole `unit_group`?
            m,
            + sum(
                unit_flow[u, n, d, s, t] * node_stochastic_weight[(node=n, stochastic_scenario=s)]
                for (u, n, d, s, t) in unit_flow_indices(direction=direction(:from_node), unit=ug)
            )
            <=
            + max_cum_in_unit_flow_bound(unit=ug)
        ) for (ug,) in indices(max_cum_in_unit_flow_bound)
    )
end

# TODO: Calling `max_cum_in_unit_flow_bound[(unit=ug)]` fails.
