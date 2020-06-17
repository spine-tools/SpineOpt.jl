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
    add_constraint_split_ramps!(m::Model)

Split delta(`unit_flow`) in `ramp_up_unit_flow and` `start_up_unit_flow`. This is
required to enforce separate limitations on these two ramp types.
"""
#TODO add scenario tree!!!
function add_constraint_split_ramps!(m::Model)
    @fetch unit_flow, ramp_up_unit_flow, start_up_unit_flow, nonspin_ramp_up_unit_flow = m.ext[:variables]
    @warn "stochastic_path still missing"
    constr_dict = m.ext[:constraints][:split_ramp_up] = Dict()
        # @warn "instead of only ramp_up it should be Iterators.flatten(ramp_up & start_up)"
        @warn "changed ramp_up from t_before tp t_after"
        @warn "flows need to be summed over groups!!!!"
    for (u, n, d, s, t_after) in unique(Iterators.flatten([ramp_up_unit_flow_indices(),start_up_unit_flow_indices(),nonspin_ramp_up_unit_flow_indices()]))
        constr_dict[u, n, d, s, t_after] = @constraint(
            m,
            unit_flow[u, n, d, s, t_after]
            -
            expr_sum(
            + unit_flow[u, n, d, s, t_before]
                for (u, n, d, s, t_before) in unit_flow_indices(unit=u,node=n,direction=d,stochastic_scenario=s,t=t_before_t(t_after=t_after))
                if is_reserve_node(node=n) == :is_reserve_node_false;
                    init=0
            )
            #TODO: this needs to sum over u,n,d,
            #maybe have on unit__to_node relationship has ramps and then only trigger these constraints
            #only excludes non_spinning reserves from these flows
            <=
            get(ramp_up_unit_flow,(u, n, d, s, t_after),0)
            +
            get(start_up_unit_flow,(u, n, d, s, t_after),0)
            +
            get(nonspin_ramp_up_unit_flow,(u, n, d, s, t_after),0)
        )
    end
end
