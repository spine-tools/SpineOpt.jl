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
    fuel_costs(m::Model)
"""
function fuel_costs(m::Model)
    @fetch flow = m.ext[:variables]
    @expression(
        m,
        reduce(
            +,
            flow[u, n, c, d, t] * duration(t) * fuel_cost[(unit=u_, commodity=c_, direction=d_, t=t)]
            for (u_, c_, d_) in indices(fuel_cost)
            for (u, n, c, d, t) in flow_indices(unit=u_, commodity=c_, direction=d_);
            init=0
        )
    )
end
