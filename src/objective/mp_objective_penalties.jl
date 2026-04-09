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
    objective_penalties(m::Model)

Create an expression for objective penalties.
"""
# TODO: find a better name for this; objective penalities is not self-speaking
function mp_objective_penalties(m::Model, t_range)
    mp_min_res_gen_to_demand_ratio_slack = get(
        m.ext[:spineopt].variables, :mp_min_res_gen_to_demand_ratio_slack, nothing
    )  # Currently, mp_min_res_gen_to_demand_ratio_slack is only for the benders master problem
    mp_min_res_gen_to_demand_ratio_slack === nothing && return 0
    @expression(
        m,
        sum(
            mp_min_res_gen_to_demand_ratio_slack_penalty(commodity=comm) * mp_min_res_gen_to_demand_ratio_slack[comm]
            for (comm,) in mp_min_res_gen_to_demand_ratio_slack_indices(m);
            init=0,
        )
    )
end
