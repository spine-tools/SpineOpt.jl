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
    ramp_costs(m::Model, t)

Create an expression for unit ramp costs.
"""
# TODO: this
function ramp_costs(m::Model, t1)
    @fetch ramp_up_unit_flow, ramp_down_unit_flow = m.ext[:variables]
    t0 = start(current_window(m))
    @expression(
        m,
        expr_sum(
            ramp_up_unit_flow[u, n, d, s, t] *
            duration(t) *
            prod(weight(temporal_block=blk) for blk in blocks(t)) *
            ramp_up_cost[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)] *
            node_stochastic_scenario_weight(m; node=ng, stochastic_scenario=s) for (u, ng, d) in indices(ramp_up_cost)
            for (u, n, d, s, t) in ramp_up_unit_flow_indices(m; unit=u, node=ng, direction=d) if end_(t) <= t1;
            init=0,
        ) + expr_sum(
            ramp_down_unit_flow[u, n, d, s, t] *
            duration(t) *
            prod(weight(temporal_block=blk) for blk in blocks(t)) *
            ramp_down_cost[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)] *
            node_stochastic_scenario_weight(m; node=ng, stochastic_scenario=s) for (u, ng, d) in indices(ramp_down_cost)
            for (u, n, d, s, t) in ramp_down_unit_flow_indices(m; unit=u, node=ng, direction=d) if end_(t) <= t1;
            init=0,
        )
    )
end
