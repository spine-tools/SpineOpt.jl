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

const invest_terms = [:unit_investment_costs, :connection_investment_costs, :storage_investment_costs]
const op_terms = [
    :variable_om_costs,
    :fixed_om_costs,
    :taxes,
    :fuel_costs,
    :start_up_costs,
    :shut_down_costs,
    :objective_penalties,
    :connection_flow_costs,
    :renewable_curtailment_costs,
    :res_proc_costs,
    :ramp_costs,
    :units_on_costs,
]
const all_objective_terms = [op_terms; invest_terms]

"""
    total_costs(m::Model, t_range::Array{TimeSlice,1})

Expression corresponding to the sume of all cost terms for given model, and up until the given date time.
"""
function total_costs(m, t_range; invesments_only=false)
    sum(eval(term)(m, t_range) for term in objective_terms(m; invesments_only=invesments_only))
end

objective_terms(m; invesments_only=false) = invesments_only ? invest_terms : all_objective_terms
