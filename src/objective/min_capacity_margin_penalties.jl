#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    min_capacity_margin_penalty(m::Model)

Create an expression for min_capacity_margin_penalty.
"""

function min_capacity_margin_penalties(m::Model, t_range)
    @fetch min_capacity_margin_slack = m.ext[:spineopt].variables
    @expression(
        m,
        + sum(
            min_capacity_margin_slack[n, s, t]
            * (!isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
               node_discounted_duration[(node=n, stochastic_scenario=s, t=t)] : 1
            ) 
            * duration(t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * min_capacity_margin_penalty(m; node=n, stochastic_scenario=s, t=t)
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (n, s, t) in min_capacity_margin_slack_indices(m; t=t_range);
            init=0,
        )        
    )
end