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
    objective_penalties(m::Model)

Create an expression for objective penalties.
"""
# TODO: find a better name for this; objective penalities is not self-speaking
function objective_penalties(m::Model, t1)
    @fetch node_slack_pos, node_slack_neg = m.ext[:variables]
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            (node_slack_neg[n, s, t] + node_slack_pos[n, s, t])
            * duration(t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_slack_penalty[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for (n, s, t) in node_slack_indices(m) if end_(t) <= t1;
            init=0,
        )
    )
end
