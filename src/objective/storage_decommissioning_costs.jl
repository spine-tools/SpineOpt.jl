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
    storage_decommissioning_costs(m::Model)

Create and expression for node decommissioning costs.
"""
function storage_decommissioning_costs(m::Model, t1)
    @fetch storages_decommissioned = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        + expr_sum(
            storages_decommissioned[n, s, t]
            # * storage_decommissioning_conversion_to_discounted_annuities[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * storage_decommissioning_cost[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * reduce(+,
                node_state_cap[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
                for n in node(use_storage_capacity_for_investment_cost_scaling=true)
                ;init=1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (n, s, t) in storages_invested_available_indices(m; node=indices(storage_decommissioning_cost))
                if end_(t) <= t1;
            init=0,
        )
    )
end
