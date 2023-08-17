#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
function mp_objective_penalties(m::Model, t_range)
    @fetch mp_min_res_gen_to_demand_ratio_slack = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    @expression(
        m,
        expr_sum(
            mp_min_res_gen_to_demand_ratio_slack_penalty(commodity=comm) * mp_min_res_gen_to_demand_ratio_slack[comm, t1]
            for (comm, t1) in mp_min_res_gen_to_demand_ratio_slack_indices(m);
            init=0,
        )
    )
end
