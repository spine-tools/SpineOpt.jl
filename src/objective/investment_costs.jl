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
    investment_costs(m::Model)
"""
function investment_costs(m::Model, t1)
    @fetch units_invested = m.ext[:variables]
    @expression(
        m,
        + expr_sum(
            units_invested[u, s, t] * unit_investment_cost[(unit=u, t=t)]
            for (u,) in indices(unit_investment_cost)
            for (u, s, t) in units_invested_available_indices(unit=u)
            if end_(t) <= t1;
            init=0
        )
    )
end
