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

function objective_terms(m::Model)
    # if we have a decomposed structure, master problem costs (investments) should not be included
    if model_type(model=m.ext[:instance]) == :spineopt_operations
        if m.ext[:is_subproblem]
            [
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
            ]
        else
            [
                :variable_om_costs,
                :fixed_om_costs,
                :taxes,
                :fuel_costs,
                :unit_investment_costs,
                :connection_investment_costs,
                :storage_investment_costs,
                :start_up_costs,
                :shut_down_costs,
                :objective_penalties,
                :connection_flow_costs,
                :renewable_curtailment_costs,
                :res_proc_costs,
                :ramp_costs,
            ]
        end
    elseif model_type(model=m.ext[:instance]) == :spineopt_master
        [:unit_investment_costs, :connection_investment_costs, :storage_investment_costs]
    end
end

"""
    total_costs(m::Model, t::DateTime)

Expression corresponding to the sume of all cost terms for given model, and up until the given date time.
"""
total_costs(m, t) = sum(eval(term)(m, t) for term in objective_terms(m))
