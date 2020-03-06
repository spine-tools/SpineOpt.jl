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
    fixed_om_costs(m)

Variable operation costs defined on flows.
"""
function fixed_om_costs(m)
    @expression(
        m,
        reduce(
            +,
            + unit_capacity[(unit=u, direction=d, t=t)] 
            * number_of_units[(unit=u, t=t)] 
            * fom_cost[(unit=u, t=t)]
            for (u, d) in indices(unit_capacity; unit=indices(fom_cost))
            for t in time_slice();
            init=0
        )
    )
end
