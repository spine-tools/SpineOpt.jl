#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
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
    storage_investment_costs(m::Model)

Create and expression for storage investment costs.
"""
function storage_investment_costs(m::Model, t_range)
    @fetch storages_invested = m.ext[:spineopt].variables
    node = indices(storage_investment_cost)
    @expression(
        m,
        + sum(
            + storages_invested[n, s, t]
            * storage_investment_cost(m; node=n, stochastic_scenario=s, t=t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (n, s, t) in storages_invested_available_indices(m; node=node, t=t_range);
            init=0,
        )
    )
end
