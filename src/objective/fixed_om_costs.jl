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
    fixed_om_costs(m::Model, flow)

Variable operation costs defined on flows.
"""
function fixed_om_costs(m::Model)
    #@butcher
    let fom_costs = zero(AffExpr)
        for (u,) in param_keys(fom_cost()), c in param_keys(unit_capacity(), unit=u)
                fom_costs +=
                + reduce(
                    +,
                    (u,c) in param_keys(unit_capacity()) ? unit_capacity(unit=u,commodity=c) : 0 * number_of_units(unit=u) * fom_cost(unit=u);
                    init=0
                )
        end
        fom_costs
    end
end
