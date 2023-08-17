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
mp_min_res_gen_to_demand_ratio_slack_indices(commodity=anything, temporal_block=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `mp_min_res_gen_to_demand_ratio_slack` variable where the keyword arguments act as filters
for each dimension.
"""
function mp_min_res_gen_to_demand_ratio_slack_indices(
    m::Model;
    commodity=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (commodity=comm, t=first(time_slice(m)))
        for comm in indices(mp_min_res_gen_to_demand_ratio_slack_penalty)        
    )
end

"""
    add_variable_units_on!(m::Model)

Add `units_on` variables to model `m`.
"""
add_variable_mp_min_res_gen_to_demand_ratio_slack!(m::Model) = add_variable!(m, :mp_min_res_gen_to_demand_ratio_slack, mp_min_res_gen_to_demand_ratio_slack_indices; lb=Constant(0))
