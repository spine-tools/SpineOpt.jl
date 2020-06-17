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
    total_costs(m::Model, t::RefDateTime)

Expression of all cost terms. t indicates the end of the last timeslice that is
included in the expression.
"""

function total_costs(m,t)
    total_cost = sum(
            + eval(cost_terms)(m,t)
            for cost_terms in filter(x -> x != :total_costs, keys(m.ext[:cost_terms]))
        )
    # for name in filter(x -> x != total_costs, keys(m.ext[:cost_terms])
    #     total_cost += name(m,t)
    # end
    # # total_costs =
    # #     vom_costs + fom_costs + tax_costs + op_costs + fl_costs +
    # #      + suc_costs + sdc_costs#+ rmp_costs + penalties + ren_curt_cost #+
    # #         #TODO: + conn_flow_costs + rs_prc_costs
    # return total_costs
end
