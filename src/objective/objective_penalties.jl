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
    objective_penalties(m::Model)
"""
# TODO: find a better name for this; objective penalities is not self-speaking
function objective_penalties(m::Model,t1)
    @fetch node_slack_pos, node_slack_neg = m.ext[:variables]
    @expression(
        m,
        expr_sum(
            ( node_slack_neg[n, s, t] + node_slack_pos[n, s, t]) * duration(t)
            * node_slack_penalty[(node=n, t=t)]
            * node_stochastic_scenario_weight[(node=n, stochastic_scenario=s)]
            for (n, s, t) in node_slack_indices()
                if t <= t1;
            init=0
        )
    )
end
