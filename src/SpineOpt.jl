#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
# __precompile__()

module SpineOpt

# Load packages
using JuMP
using Clp
using Cbc
using Dates
using TimeZones
using SpineInterface
using Suppressor
using JSON
using PowerSystems

import Dates: CompoundPeriod
import DataStructures: OrderedDict
import LinearAlgebra: UniformScaling
import JuMP: MOI, MOIU

# Export utility
export run_spineopt
export rerun_spineopt
export run_spineopt_mp
export rerun_spineopt_mp
export @fetch

# Export indices functions
export unit_flow_indices
export unit_flow_op_indices
export connection_flow_indices
export node_state_indices
export units_on_indices
export units_invested_available_indices

include("util/misc.jl")
include("util/update_model.jl")
include("util/postprocess_results.jl")
include("util/write_information_files.jl")

include("run_spineopt.jl")
include("run_spineopt_mp.jl")

include("data_structure/benders_data.jl")
include("data_structure/temporal_structure.jl")
include("data_structure/stochastic_structure.jl")
include("data_structure/preprocess_data_structure.jl")
include("data_structure/generate_missing_items.jl")
include("data_structure/check_data_structure.jl")

include("variables/variable_common.jl")
include("variables/variable_unit_flow.jl")
include("variables/variable_unit_flow_op.jl")
include("variables/variable_connection_flow.jl")
include("variables/variable_node_state.jl")
include("variables/variable_units_on.jl")
include("variables/variable_units_invested.jl")
include("variables/variable_units_invested_available.jl")
include("variables/variable_units_mothballed.jl")
include("variables/variable_units_available.jl")
include("variables/variable_units_started_up.jl")
include("variables/variable_units_shut_down.jl")
include("variables/variable_node_slack_pos.jl")
include("variables/variable_node_slack_neg.jl")
include("variables/variable_node_injection.jl")

include("variables/variable_nonspin_units_starting_up.jl")
include("variables/variable_start_up_unit_flow.jl")
include("variables/variable_ramp_up_unit_flow.jl")
include("variables/variable_nonspin_ramp_up_unit_flow.jl")

include("variables/variable_mp_objective_lowerbound.jl")


include("objective/set_objective.jl")
include("objective/set_mp_objective.jl")
include("objective/variable_om_costs.jl")
include("objective/fixed_om_costs.jl")
include("objective/taxes.jl")
include("objective/operating_costs.jl")
include("objective/start_up_costs.jl")
include("objective/shut_down_costs.jl")
include("objective/fuel_costs.jl")
include("objective/investment_costs.jl")
include("objective/objective_penalties.jl")
include("objective/total_costs.jl")
include("objective/renewable_curtailment_costs.jl")
include("objective/connection_flow_costs.jl")
include("objective/res_proc_costs.jl")
include("objective/ramp_costs.jl")
include("objective/res_start_up_costs.jl")

include("constraints/constraint_common.jl")
include("constraints/constraint_max_cum_in_unit_flow_bound.jl")
include("constraints/constraint_unit_flow_capacity.jl")
include("constraints/constraint_operating_point_bounds.jl")
include("constraints/constraint_operating_point_sum.jl")
include("constraints/constraint_nodal_balance.jl")
include("constraints/constraint_node_injection.jl")
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
include("constraints/constraint_unit_constraint.jl")
include("constraints/constraint_units_invested_available.jl")
include("constraints/constraint_units_invested_transition.jl")
include("constraints/constraint_unit_lifetime.jl")
# TODO: include("constraints/constraint_ramp_cost.jl")
include("constraints/constraint_split_ramp_up.jl")
include("constraints/constraint_ramp_up.jl")
include("constraints/constraint_max_start_up_ramp.jl")
include("constraints/constraint_min_start_up_ramp.jl")
# TODO: include("constraints/constraint_ramp_down.jl")
include("constraints/constraint_max_nonspin_ramp_up.jl")
include("constraints/constraint_min_nonspin_ramp_up.jl")
include("constraints/constraint_res_minimum_node_state.jl")

include("constraints/constraint_mp_units_invested_cuts.jl")
#include("constraints/constraint_mp_unit_lifetime.jl")
#include("constraints/constraint_mp_units_invested_available.jl")
#include("constraints/constraint_mp_units_invested_transition.jl")


_template() = JSON.parsefile(joinpath(dirname(pathof(@__MODULE__)), "..", "data", "spineopt_template.json"))

end