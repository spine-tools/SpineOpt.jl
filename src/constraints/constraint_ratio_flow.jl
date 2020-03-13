#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
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

"""
    add_constraint_ratio_flow!(m, ratio, sense, d1, d2)

Ratio of `flow` variables.
"""
function add_constraint_ratio_flow!(m::Model, ratio, sense, d1, d2)
    @fetch flow = m.ext[:variables]
    cons = m.ext[:constraints][ratio.name] = Dict()
    for (u, n1, n2) in indices(ratio)
        for t in t_lowest_resolution(map(x -> x.t, flow_indices(unit=u, node=[n1, n2])))
            cons[u, n1, n2, t] = sense_constraint(
                m,
                + reduce(
                    +,
                    flow[u_, n1_, d1_, t_] * duration(t_)
                    for (u_, n1_, d1_, t_) in flow_indices(
                        unit=u, node=n1, direction=d1, t=t_in_t(t_long=t)
                    );
                    init=0
                ),
                sense,
                + ratio[(unit=u, node1=n1, node2=n2, t=t)]
                * reduce(
                    +,
                    flow[u_, n2_, d2_, t_] * duration(t_)
                    for (u_, n2_, d2_, t_) in flow_indices(
                        unit=u, node=n2, direction=d2, t=t_in_t(t_long=t)
                    );
                    init=0
                )
            )
        end
    end
end

function add_constraint_fix_ratio_out_in_flow!(m::Model)
    add_constraint_ratio_flow!(m, fix_ratio_out_in_flow, ==, direction(:to_node), direction(:from_node))
end
function add_constraint_max_ratio_out_in_flow!(m::Model)
    add_constraint_ratio_flow!(m, max_ratio_out_in_flow, <=, direction(:to_node), direction(:from_node))
end
function add_constraint_min_ratio_out_in_flow!(m::Model)
    add_constraint_ratio_flow!(m, min_ratio_out_in_flow, >=, direction(:to_node), direction(:from_node))
end
function add_constraint_fix_ratio_in_in_flow!(m::Model)
    add_constraint_ratio_flow!(m, fix_ratio_in_in_flow, ==, direction(:from_node), direction(:from_node))
end
function add_constraint_max_ratio_in_in_flow!(m::Model)
    add_constraint_ratio_flow!(m, max_ratio_in_in_flow, <=, direction(:from_node), direction(:from_node))
end
function add_constraint_fix_ratio_out_out_flow!(m::Model)
    add_constraint_ratio_flow!(m, fix_ratio_out_out_flow, ==, direction(:to_node), direction(:to_node))
end
function add_constraint_max_ratio_out_out_flow!(m::Model)
    add_constraint_ratio_flow!(m, max_ratio_out_out_flow, <=, direction(:to_node), direction(:to_node))
end