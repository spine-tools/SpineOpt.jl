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
    storage_mothballing_costs(m::Model)

Create and expression for storage mothballing costs.
"""
function storage_mothballing_costs(m::Model, t1)
    @fetch storages_mothballed_vintage, storages_demothballed_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        + expr_sum(
            storages_mothballed_vintage[n, s, t_v, t]
            # * discount_factor(m,discount_rate(model=m.ext[:instance]),t.start)
            # * storage_mothballing_conversion_to_discounted_annuities[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * storage_mothballing_cost[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * reduce(+,
                node_state_cap[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
                for n in node(use_storage_capacity_for_investment_cost_scaling=true)
                ;init=1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * storage_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (n, s, t_v, t) in storages_mothballed_state_vintage_indices(m; node=indices(storage_mothballing_cost)) if end_(t) <= t1;
            init=0,
        )
        + expr_sum(
            storages_demothballed_vintage[n, s, t_v, t]
            # * discount_factor(m,discount_rate(model=m.ext[:instance]),t.start)
            # * storage_demothballing_cost[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * reduce(+,
                node_state_cap[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
                for n in node(use_storage_capacity_for_investment_cost_scaling=true)
                ;init=1
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * storage_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (n, s, t_v, t) in storages_mothballed_state_vintage_indices(m; node=indices(storage_demothballing_cost)) if end_(t) <= t1;
            init=0,
        )
    )
end
