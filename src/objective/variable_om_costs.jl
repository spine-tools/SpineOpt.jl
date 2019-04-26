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
    variable_om_costs(m::Model, flow)

Variable operation costs defined on flows.
"""
function variable_om_costs(flow)
    let vom_costs = zero(AffExpr)
        for (u, n, d, block) in indices(vom_cost)
            vom_costs += reduce(
                +,
                flow[u, n, c, d, t] * vom_cost(unit=u, node=n, direction=d, temporal_block=block, t=t) * duration(t)
                for (u, n, c, d, t) in flow_indices(node=n, unit=u, direction=d);
                init=0
            )
        end
        vom_costs
    end
end
