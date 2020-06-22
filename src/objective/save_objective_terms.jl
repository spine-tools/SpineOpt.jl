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
    initialize_cost_terms!(m::Model)

Initialize cost terms to stor them in m.ext[:cost_terms] dictionary.
"""
function initialize_cost_terms!(m::Model)
    m.ext[:cost_terms] = Dict()
    m.ext[:cost_terms_fun] = Dict()
    cost_terms = [
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
        # TODO: :ramp_costs,
        :total_costs
    ]
    for cost_term in cost_terms
        m.ext[:cost_terms][cost_term] = Dict()
    end
end

"""
    save_objective_values!(m::Model)

Save all cost values to previously initialized Dict m.ext[:cost_terms] after optimization.
Not that only time_slices within the current window are taken into account.
"""
function save_objective_values!(m::Model)
    ind = (model=model()[1], t=current_window)
    for key in keys(m.ext[:cost_terms])
        save_cost_term!(m, key, ind)
    end
end

"""
    save_cost_term!(m::Model, name::Symbol,ind::NamedTuple{(:model, :t),Tuple{Object,TimeSlice}})

Save individual cost term.
"""
function save_cost_term!(m::Model, name::Symbol,ind::NamedTuple{(:model, :t),Tuple{Object,TimeSlice}})
    fun = eval(name)
    m.ext[:cost_terms][name] = Dict(
        ind => value(realize(fun(m,end_(ind.t))))
    )
end
