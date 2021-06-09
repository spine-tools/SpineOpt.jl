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
    taxes(m::Model)

Create an expression for unit taxes.
"""
function taxes(m::Model, t1)
    @fetch unit_flow = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        + expr_sum(
            + unit_flow[u, n, d, s, t]
            * duration(t)
            * tax_net_unit_flow[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s) for (n,) in indices(tax_net_unit_flow)
            for (u, n, d, s, t) in unit_flow_indices(m; node=n, direction=direction(:to_node)) if end_(t) <= t1;
            init=0,
        ) - expr_sum(
            + unit_flow[u, n, d, s, t]
            * duration(t)
            * tax_net_unit_flow[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s) for (n,) in indices(tax_net_unit_flow)
            for (u, n, d, s, t) in unit_flow_indices(m; node=n, direction=direction(:from_node)) if end_(t) <= t1;
            init=0,
        )
        + expr_sum(
            + unit_flow[u, n, d, s, t]
            * duration(t)
            * tax_out_unit_flow[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s) for (n,) in indices(tax_out_unit_flow)
            for (u, n, d, s, t) in unit_flow_indices(m; node=n, direction=direction(:from_node)) if end_(t) <= t1;
            init=0,
        )
        + expr_sum(
            unit_flow[u, n, d, s, t]
            * duration(t)
            * tax_in_unit_flow[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s) for (n,) in indices(tax_in_unit_flow)
            for (u, n, d, s, t) in unit_flow_indices(m; node=n, direction=direction(:to_node)) if end_(t) <= t1;
            init=0,
        )
    )
end
