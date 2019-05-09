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
    objective_minimize_total_discounted_costs(m::Model)

Minimize the `total_discounted_costs` corresponding to the sum over all
cost terms.
"""
function objective_minimize_total_discounted_costs(m::Model)
    vom_costs = variable_om_costs(m)
    fom_costs = fixed_om_costs()
    tax_costs = taxes(m)
    op_costs = operating_costs(m)
    suc_costs = start_up_costs(m)
    sdc_costs = shut_down_costs(m)
    total_discounted_costs = vom_costs + fom_costs + tax_costs + op_costs +
                                +suc_costs + sdc_costs
    @objective(m, Min, total_discounted_costs)
end
