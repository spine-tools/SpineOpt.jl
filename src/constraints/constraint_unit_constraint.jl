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
    add_constraint_ratio_unit_flow!(m, ratio, sense, d1, d2)

Ratio of `unit_flow` variables.
"""
function add_constraint_unit_constraint!(m::Model)
    @fetch unit_flow_op, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:unit_constraint] = Dict()
    for (u,uc) in unit__unit_constraint()
        involved_nodes=[]
        for n in unit_constraint__to_node(unit_constraint=uc)
            push!(involved_nodes, n)
        end
        for n in unit_constraint__from_node(unit_constraint=uc)
            push!(involved_nodes, n)
        end
        for t in t_lowest_resolution(map(x -> x.t, unit_flow_indices(unit=u, node=involved_nodes)))
            cons[uc, t] = sense_constraint(
                m,
                + reduce(
                    +,
                    + unit_flow_op[u_, n_, d_, op_, t_] * unit_flow_from_node_coefficient[(unit_constraint=uc, node=n_, i=op_, t=t_)] * duration(t_)
                    for n in unit_constraint__from_node(unit_constraint=uc)
                    for (u_, n_, d_, op_, t_) in unit_flow_op_indices(
                        unit=u, node=n, direction=direction(:from_node), t=t_in_t(t_long=t)
                    );
                    init=0
                )
                + reduce(
                    +,
                    + unit_flow_op[u_, n_, d_, op_, t_] * unit_flow_to_node_coefficient[(unit_constraint=uc, node=n_, i=op_, t=t_)] * duration(t_)
                    for n in unit_constraint__from_node(unit_constraint=uc)
                    for (u_, n_, d_, op_, t_) in unit_flow_op_indices(
                        unit=u, node=n, direction=direction(:to_node), t=t_in_t(t_long=t)
                    );
                    init=0
                )
                + reduce(
                    +,
                    + unit_flow_op[u_, n_, d_, op_, t_] * unit_flow_from_node_coefficient[(unit_constraint=uc, node=n_, i=op_, t=t_)] * duration(t_)
                    for n in unit_constraint__to_node(unit_constraint=uc)
                    for (u_, n_, d_, op_, t_) in unit_flow_op_indices(
                        unit=u, node=n, direction=direction(:from_node), t=t_in_t(t_long=t)
                    );
                    init=0
                )
                + reduce(
                    +,
                    + unit_flow_op[u_, n_, d_, op_, t_] * unit_flow_to_node_coefficient[(unit_constraint=uc, node=n_, i=op_, t=t_)] * duration(t_)
                    for n in unit_constraint__to_node(unit_constraint=uc)
                    for (u_, n_, d_, op_, t_) in unit_flow_op_indices(
                        unit=u, node=n, direction=direction(:to_node), t=t_in_t(t_long=t)
                    );
                    init=0
                )
                + units_on_coefficient[(unit_constraint=uc, unit=u, t=t)]
                * reduce(
                    +,
                    units_on[u_, t_] * duration(t_)
                    for (u_, t_) in units_on_indices(
                        unit=u, t=t_in_t(t_long=t)
                    );
                    init=0
                )
                ,
                constraint_sense(unit_constraint=uc),
                + right_hand_side(unit_constraint=uc, t=t),
            )
        end
    end
end
