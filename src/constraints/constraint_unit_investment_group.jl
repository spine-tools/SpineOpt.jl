#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
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
    add_constraint_unit_investment_groups!(m::Model)

Force investment variables for all units and nodes in the group to be equal
"""
function add_constraint_unit_investment_group!(m::Model)
    @fetch units_invested_available, storages_invested_available = m.ext[:spineopt].variables
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:unit_investment_group] = Dict(
        (investment_group=ig, unit=u, stochastic_scenario=s, t=t) => @constraint(
            m,
            + units_invested_available[u, s, t]           
            ==            
            + get(units_invested_available, (first_entity(ig), s, t), 0)
            + get(storages_invested_available, (first_entity(ig), s, t), 0)
        )
        for (u, ig) in unit__investment_group()        
        for (u, s, t) in units_invested_available_indices(m; unit=u)
        if u !== first_entity(ig)
    )
end

function first_entity(ig)
    first(union(unit__investment_group(investment_group=ig),node__investment_group(investment_group=ig)))
end
