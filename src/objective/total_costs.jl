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
    vom_costs = variable_om_costs(m,t)
    fom_costs = fixed_om_costs(m,t)
    tax_costs = taxes(m,t)
    op_costs = operating_costs(m,t)
    fl_costs = fuel_costs(m,t)
    suc_costs = start_up_costs(m,t)
    sdc_costs = shut_down_costs(m,t)
    penalties = objective_penalties(m,t)
    @warn "to add" #rmp_costs = ramp_costs(m,t)
    ren_curt_costs = renewable_curtailment_costs(m,t)
    @warn "to add" #conn_flow_costs = connection_flow_costs(m,t)
    @warn "to add" #rs_prc_costs = res_proc_costs(m,t)
    total_costs =
        vom_costs + fom_costs + tax_costs + op_costs + fl_costs +
         + suc_costs + sdc_costs+ rmp_costs + penalties + ren_curt_cost +
            + conn_flow_costs + rs_prc_costs
    return total_costs
end
