#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    fixed_om_costs(m)

Create an expression for fixed operation costs of storages.
"""
function storage_fixed_om_costs(m, t1)
    t0 = _analysis_time(m)
    @fetch storages_invested_available = m.ext[:variables]
    @expression(
        m,
        expr_sum(
            + node_state_cap[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * (!isnothing(candidate_storages(node=n)) ? storages_invested_available[n, s, t] : 1)
            * storage_fom_cost[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)] #should be given as costs per year?
            * node_discounted_duration[(node=n, stochastic_scenario=s,t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            for ng in intersect(indices(node_state_cap),indices(storage_fom_cost))
            for (n, s, t) in storages_invested_available_indices(m; node=ng) if end_(t) <= t1;
            init=0,
        )
    )
end
#TODO: scenario tree?
