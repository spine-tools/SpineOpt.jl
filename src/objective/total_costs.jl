#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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

const mp_terms = [
    :unit_investment_costs, :connection_investment_costs, :storage_investment_costs, :mp_objective_penalties
]
const sp_terms = [
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
    :units_on_costs,
    :min_capacity_margin_penalties,
]
const all_objective_terms = unique!([mp_terms; sp_terms])

"""
    total_costs(m::Model, t_range::Union{Anything,Vector{TimeSlice}})

Expression corresponding to the sume of all cost terms for given model, and within the given range of time.
"""
function total_costs(m, t_range; benders_master=true, benders_subproblem=true)
    sum(
        getproperty(SpineOpt, term)(m, t_range)
        for term in objective_terms(m; benders_master=benders_master, benders_subproblem=benders_subproblem)
    )
end

function objective_terms(m; benders_master=true, benders_subproblem=true)
    obj_terms = []
    benders_master && append!(obj_terms, mp_terms)
    benders_subproblem && append!(obj_terms, sp_terms)
    unique!(obj_terms)
end
