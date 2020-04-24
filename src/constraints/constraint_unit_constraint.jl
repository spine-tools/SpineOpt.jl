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
    @fetch unit_flow_op, unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:unit_constraint] = Dict()
    for uc in unit_constraint()        
        involved_unit_flow_indices=[]
        for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
            append!(involved_unit_flow_indices, unit_flow_indices(unit=u, node=n))
        end
        for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
            append!(involved_unit_flow_indices, unit_flow_indices(unit=u, node=n))
        end
        for t in t_lowest_resolution(map(x -> x.t, involved_unit_flow_indices ))
            for s in map(x -> x.s, involved_unit_flow_indices)
                cons[uc, s, t] = sense_constraint( # TODO: Stochastic path indexing
                    m,
                    + reduce(
                        +,
                        + unit_flow_op[u_, n_, d_, op_, s_, t_] * unit_flow_coefficient[(unit=u_, node=n_, unit_constraint=uc, i=op_, t=t_)] * duration(t_) # TODO: Stochastic parameters
                        for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
                        for (u_, n_, d_, op_, s_, t_) in unit_flow_op_indices(
                            unit=u, node=n, direction=direction(:from_node), stochastic_scenario=s, t=t_in_t(t_long=t)
                        );
                        init=0
                    )
                    + reduce(
                        +,
                        + unit_flow[u_, n_, d_, s_, t_] * unit_flow_coefficient[(unit=u_, node=n_, unit_constraint=uc, i=1, t=t_)] * duration(t_)
                        for (u, n) in unit__from_node__unit_constraint(unit_constraint=uc)
                        for (u_, n_, d_, s_, t_) in unit_flow_indices(
                            unit=u, node=n, direction=direction(:from_node), stochastic_scenario=s, t=t_in_t(t_long=t)
                        )
                        if isempty(unit_flow_op_indices(unit=u_, node=n_, direction=d_, stochastic_scenario=s_, t=t_)) ;
                        init=0
                    )
                    + reduce(
                        +,
                        + unit_flow_op[u_, n_, d_, op_, s_, t_] * unit_flow_coefficient[(unit=u_, node=n_, unit_constraint=uc, i=op_, t=t_)] * duration(t_)
                        for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
                        for (u_, n_, d_, op_, s_, t_) in unit_flow_op_indices(
                            unit=u, node=n, direction=direction(:to_node), stochastic_scenario=s, t=t_in_t(t_long=t)
                        );
                        init=0
                    )
                    + reduce(
                        +,
                        + unit_flow[u_, n_, d_, t_] * unit_flow_coefficient[(unit=u_, node=n_, unit_constraint=uc, i=1, t=t_)] * duration(t_)
                        for (u, n) in unit__to_node__unit_constraint(unit_constraint=uc)
                        for (u_, n_, d_, s_, t_) in unit_flow_indices(
                            unit=u, node=n, direction=direction(:to_node), stochastic_scenario=s, t=t_in_t(t_long=t)
                        )
                        if isempty(unit_flow_op_indices(unit=u_, node=n_, direction=d_, s=s_, t=t_)) ;
                        init=0
                    )
                    + reduce(
                        +,
                        units_on[u_, t_] * units_on_coefficient[(unit_constraint=uc, unit=u_, t=t_)] * duration(t_) # TODO: Stochastic `unit` indexing
                        for u in unit__unit_constraint(unit_constraint=uc)
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
end
