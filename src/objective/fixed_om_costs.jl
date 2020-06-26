#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    fixed_om_costs(m)

Create an expression for fixed operation costs of units.
"""
function fixed_om_costs(m, t1)
    @expression(
        m,
        expr_sum(
            + unit_capacity[(unit=u, node=ng, direction=d, t=t)]
            * number_of_units[(unit=u, t=t)]
            * fom_cost[(unit=u, t=t)]
            * duration(t)
            for (u, ng, d) in indices(unit_capacity; unit=indices(fom_cost))
            for t in unique(ind.t for ind in units_on_indices(unit=u))
            if end_(t) <= t1;
            init=0
        )
    )
end
#TODO: scenario tree?
