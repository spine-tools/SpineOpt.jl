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
# __precompile__()

module SpineModel

# Load packages
using JuMP
using Clp
using Cbc
using Dates
using TimeZones
using SpineInterface
using Suppressor
using JSON

# Export utility
export run_spinemodel
export @fetch
export or

# Export indices functions
export unit_flow_indices
export connection_flow_indices
export node_state_indices
export units_on_indices

include("temporals/generate_time_slice.jl")
include("temporals/generate_time_slice_relationships.jl")

include("util/missing_item_handlers.jl")
include("util/misc.jl")
include("util/run_spinemodel.jl")
include("util/update_model.jl")
include("util/preprocess_data_structure.jl")
include("util/network_functions.jl")

include("variables/variable_common.jl")
include("variables/variable_unit_flow.jl")
include("variables/variable_connection_flow.jl")
include("variables/variable_node_state.jl")
include("variables/variable_units_on.jl")
include("variables/variable_units_available.jl")
include("variables/variable_units_started_up.jl")
include("variables/variable_units_shut_down.jl")
include("variables/variable_node_slack_pos.jl")
include("variables/variable_node_slack_neg.jl")

include("objective/set_objective.jl")
include("objective/variable_om_costs.jl")
include("objective/fixed_om_costs.jl")
include("objective/taxes.jl")
include("objective/operating_costs.jl")
include("objective/start_up_costs.jl")
include("objective/shut_down_costs.jl")
include("objective/fuel_costs.jl")
include("objective/objective_penalties.jl")

include("constraints/constraint_max_cum_in_unit_flow_bound.jl")
include("constraints/constraint_unit_flow_capacity.jl")
include("constraints/constraint_nodal_balance.jl")
include("constraints/constraint_group_balance.jl")
include("constraints/constraint_node_state_capacity.jl")
include("constraints/constraint_ratio_unit_flow.jl")
include("constraints/constraint_ratio_out_in_connection_flow.jl")
include("constraints/constraint_connection_flow_capacity.jl")
include("constraints/constraint_connection_flow_ptdf.jl")
include("constraints/constraint_connection_flow_lodf.jl")
include("constraints/constraint_units_on.jl")
include("constraints/constraint_units_available.jl")
include("constraints/constraint_minimum_operating_point.jl")
include("constraints/constraint_min_up_time.jl")
include("constraints/constraint_min_down_time.jl")
include("constraints/constraint_unit_state_transition.jl")


function __init__()
	generate_missing_item_handlers()
end

end
