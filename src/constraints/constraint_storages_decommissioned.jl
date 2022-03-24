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
    add_constraint_storages_decommissioned_vintage!(m::Model)

Link storages_decommissioned to the sum of all storages_decommissioned_vintage, i.e. all investments differentiated by their investment year that are not decomissioned.
"""
function add_constraint_storages_decommissioned!(m::Model)
    @fetch storages_decommissioned, storages_decommissioned_vintage = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:storages_decommissioned] = Dict(
        (node=n, stochastic_path=s, t=t) => @constraint(
            m,
            + storages_decommissioned[n, s, t]
            ==
            + expr_sum(
                storages_decommissioned_vintage[n, s, t_v, t]
                for (n, s, t_v, t) in storages_invested_available_vintage_indices(
                            m;
                            node=n,
                            stochastic_scenario=s,
                            t=t,
                            t_vintage = to_time_slice(
                                m;
                                t=TimeSlice(start(t - storage_investment_tech_lifetime(node=n)), end_(t))
                                )
                            )
                ; init=0
                )
        ) for (n, s, t) in storages_invested_available_indices(m)
    )
end
