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
    for (c,n) in commodity__node(), t=1:number_of_timesteps(time=:timer)
        @butcher @constraint(
            m,
            # Change in the state commodity content
            + ( state_commodity_content(commodity=c, node=n) != nothing &&
                state_commodity_content(commodity=c, node=n)
                    * (state[c, n, t] - state[c, n, t-1])
                )
            ==
            # Commodity state discharge and diffusion
            + ( state_commodity_content(commodity=c, node=n) != nothing &&
                # Commodity self-discharge
                - ( state_commodity_discharge_rate(commodity=c, node=n) != nothing &&
                    state_commodity_discharge_rate(commodity=c, node=n)
                        * state[c, n, t]
                    )
                # Commodity diffusion between nodes
                # Diffusion into this node
                + sum(  + ( state_commodity_diffusion_rate(commodity=c, node1=nn, node2=n) != nothing &&
                            state_commodity_diffusion_rate(commodity=c, node1=nn, node2=n)
                                * state[c, nn, t]
                            )
                        for nn in commodity__node__node(commodity=c, node2=n)
                        )
                # Diffusion from this node
                - sum(  + ( state_commodity_diffusion_rate(commodity=c, node1=n, node2=nn) != nothing &&
                            state_commodity_diffusion_rate(commodity=c, node1=n, node2=nn)
                                * state[c, n ,t]
                            )
                        for nn in commodity__node__node(commodity=c, node1=n)
                        )
                )
            # Demand for the commodity
            - ( demand(commodity=c, node=n, t=t) != nothing &&
                demand(commodity=c, node=n, t=t)
                )
            # Output of units into this node, and their input from this node
            + sum(flow[c, n, u, :out, t] for u in commodity__node__unit__direction(commodity=c, node=n, direction=:out))
            - sum(flow[c, n, u, :in, t] for u in commodity__node__unit__direction(commodity=c, node=n, direction=:in))
            # Transfer of commodities between nodes
            - sum(trans[conn, n, t] for conn in connection__node(commodity=c, node=n))
        )
    end
end
