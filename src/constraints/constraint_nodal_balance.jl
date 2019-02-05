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
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
TODO: for electrical lines this constraint is obsolete unless
a trade based representation is used.
"""
function constraint_nodal_balance(m::Model, state, flow, trans)
    @butcher for (c, n) in commodity__node(), t=1:number_of_timesteps(time=:timer)
        @constraint(
            m,
            # Change in the state commodity content
            ( state_commodity_content(node=n, commodity=c) != nothing &&
                + state_commodity_content(node=n, commodity=c)
                    * (state[c, n, t] - state[c, n, t-1]) )
            ==
            ( state_commodity_content(node=n, commodity=c) != nothing &&
                # Commodity self-discharge
                ( state_commodity_discharge_rate(node=n, commodity=c) != nothing &&
                    - state_commodity_discharge_rate(node=n, commodity=c)
                        * state[c, n, t] )
                # Commodity diffusion between nodes
                + sum(  ( state_commodity_diffusion_rate(from_node=m, to_node=n) != nothing &&
                            + state_commodity_diffusion_rate(from_node=m, to_node=n) * state[c, m, t] )
                        ( state_commodity_diffusion_rate(from_node=n, to_node=m) != nothing &&
                            - state_commodity_diffusion_rate(from_node=n, to_node=m) * state[c, n ,t] )
                        for m in commodity__node(commodity=c, node=m)
                    ) )
            # Demand for the commodity
            ( demand(commodity=c, node=n, t=t) != nothing &&
                - demand(commodity=c, node=n, t=t) )
            # Output of units into this node, and their input from this node
            + sum(flow[c, n, u, :out, t] for u in commodity__node__unit__direction(commodity=c, node=n, direction=:out))
            - sum(flow[c, n, u, :in, t] for u in commodity__node__unit__direction(commodity=c, node=n, direction=:in))
            # Transfer of commodities between nodes
            - sum(trans[c, conn, n, t] for conn in commodity__connection__node(commodity=c, node=n))
        )
    end
end
