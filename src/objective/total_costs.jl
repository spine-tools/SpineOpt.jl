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

function objective_terms()
    [
        :variable_om_costs,
        :fixed_om_costs,
        :taxes,
        :operating_costs,
        :fuel_costs,
        :investment_costs,
        :start_up_costs,
        :shut_down_costs,
        :objective_penalties,
        :connection_flow_costs,
        :renewable_curtailment_costs,
        :res_proc_costs,
        :ramp_costs,
        :res_start_up_costs
    ]
end

"""
    total_costs(m::Model, t::DateTime)

Expression corresponding to the sume of all cost terms for given model, and up until the given date time.
"""
total_costs(m, t) = sum(eval(term)(m, t) for term in objective_terms())
