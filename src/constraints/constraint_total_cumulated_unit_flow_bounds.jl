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


function add_constraint_total_cumulated_unit_flow!(m::Model, bound,sense,d)
    @fetch unit_flow = m.ext[:variables]
    m.ext[:constraints][bound.name] = Dict(
        (unit=ug, node= ng, stochastic_path = s,t=t ) => sense_constraint( # TODO: How to turn this one into stochastical one? Path indexing over the whole `unit_group`?
            m,
            + expr_sum(#TODO check if expression sum is needed here
                unit_flow[u, n, d, s, t] * duration(t) # * node_stochastic_weight[(node=n, stochastic_scenario=s)]
                for (u, n, d, s, t) in unit_flow_indices(
                    m;
                    unit=ug,
                    node = ng,
                    direction=d,
                    stochastic_scenario = s);
                    init = 0
            ),
            sense,
            bound(unit = ug, node = ng)
            #TODO Should this be time-varying, and stochastical?
        ) for (ug,ng,s) in constraint_total_cumulated_unit_flow_indices(m,bound,d)
    )
end

# TODO: Calling `max_cum_in_unit_flow_bound[(unit=ug)]` fails.


function constraint_total_cumulated_unit_flow_indices(m::Model,bound,d)
    unique(
        (unit = ug, node = ng, stochastic_path = s) for (ug,ng) in indices(bound)
        for s in active_stochastic_paths(
            unique(
            ind.stochastic_scenario for ind in unit_flow_indices(m,direction = d, unit = ug,node = ng)
            )
        )
    )
end

function add_constraint_max_total_cumulated_unit_flow_from_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m::Model,max_total_cumulated_unit_flow_from_node,<=,direction(:from_node))
end

function add_constraint_min_total_cumulated_unit_flow_from_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m::Model,min_total_cumulated_unit_flow_from_node,>=,direction(:from_node))
end

function add_constraint_max_total_cumulated_unit_flow_to_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m::Model,max_total_cumulated_unit_flow_to_node,<=,direction(:to_node))
end

function add_constraint_min_total_cumulated_unit_flow_to_node!(m::Model)
    add_constraint_total_cumulated_unit_flow!(m::Model,min_total_cumulated_unit_flow_to_node,>=,direction(:to_node))
end
