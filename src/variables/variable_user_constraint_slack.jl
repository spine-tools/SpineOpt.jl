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
    user_constraint_slack_indices(filtering_options...)
"""
function user_constraint_slack_indices(
    m::Model;
    user_constraint=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    (
        (user_constraint=uc, stochastic_scenario=ind.stochastic_scenario, t=ind.t)
        for uc in indices(user_constraint_slack_penalty; user_constraint=user_constraint)
        for inds in user_constraint_all_indices(
            m; user_constraint=uc, stochastic_scenario=stochastic_scenario, t=t, temporal_block=temporal_block
        )
        for ind in inds
    )
end

"""
    add_variable_user_constraint_slack_pos!(m::Model)
"""
function add_variable_user_constraint_slack_pos!(m::Model)
    add_variable!(m, :user_constraint_slack_pos, user_constraint_slack_indices; lb=constant(0))
end

"""
    add_variable_user_constraint_slack_neg!(m::Model)
"""
function add_variable_user_constraint_slack_neg!(m::Model)
    add_variable!(m, :user_constraint_slack_neg, user_constraint_slack_indices; lb=constant(0))
end
