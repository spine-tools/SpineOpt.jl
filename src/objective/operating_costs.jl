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
    objective_minimize_production_cost(m::Model, flow)

Minimize the `production_cost` correspond to the sum over all
`conversion_cost` of each `unit`.
"""
function operating_costs(flow)
    @butcher let op_costs = zero(AffExpr)
        for (c,u,d) in operating_cost_keys()
            op_costs +=
            sum(
                flow[u, n, c, d, t] * duration(t) * operating_cost(commodity=c, unit=u, direction=d, t=t)
                for (u,n,c,d,t) in flow_indices(unit=u,commodity=c,direction=d)
            )
        end
        op_costs
    end
end
