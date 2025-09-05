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
# __precompile__()

module SpineOpt

# Load packages
using Dates
using SpineInterface
using JSON
using Printf
using Requires
using JuMP
using HiGHS
using Arrow
import TOML
import DataStructures: OrderedDict
import Dates: CompoundPeriod
import LibGit2
import LinearAlgebra: BLAS.gemm, LAPACK.getri!, LAPACK.getrf!

# Resolve JuMP and SpineInterface `Parameter` and `parameter_value` conflicts.
import SpineInterface: Parameter, parameter_value

export SpineOptExt
export run_spineopt
export prepare_spineopt
export run_spineopt!
export add_event_handler!
export create_model
export build_model!
export solve_model!
export generate_temporal_structure!
export generate_economic_structure!
export roll_temporal_structure!
export rewind_temporal_structure!
export time_slice
export t_before_t
export t_in_t
export t_in_t_excl
export t_overlaps_t
export to_time_slice
export current_window
export generate_stochastic_structure!
export active_stochastic_paths
export write_report
export write_report_from_intermediate_results
export generate_forced_outages
export forced_outage_time_series
export master_model
export stage_model
export write_model_file
export @fetch
export @log
export @timelog

# Util
include("util/misc.jl")
include("util/write_information_files.jl")
include("util/promise.jl")
# Main stage
include("run_spineopt.jl")
include("generate_forced_outages.jl")
include("run_spineopt_basic.jl")
include("run_spineopt_mga.jl")
include("run_spineopt_hsj_mga.jl")
include("run_spineopt_monte_carlo.jl")
include("benders.jl")
# Data structure
include("data_structure/economic_structure.jl")
include("data_structure/migration.jl")
include("data_structure/temporal_structure.jl")
include("data_structure/stochastic_structure.jl")
include("data_structure/preprocess_data_structure.jl")
include("data_structure/check_data_structure.jl")
include("data_structure/postprocess_results.jl")
include("data_structure/diagnose.jl")
# Variables
include("variables/variable_binary_gas_connection_flow.jl")
include("variables/variable_common.jl")
include("variables/variable_connection_flow.jl")
include("variables/variable_connection_intact_flow.jl")
include("variables/variable_connections_decommissioned.jl")
include("variables/variable_connections_invested.jl")
include("variables/variable_connections_invested_available.jl")
include("variables/variable_min_capacity_margin_slack.jl")
include("variables/variable_mp_min_res_gen_to_demand_ratio_slack.jl")
include("variables/variable_node_injection.jl")
include("variables/variable_node_pressure.jl")
include("variables/variable_node_slack_neg.jl")
include("variables/variable_node_slack_pos.jl")
include("variables/variable_node_state.jl")
include("variables/variable_node_voltage_angle.jl")
include("variables/variable_nonspin_units_shut_down.jl")
include("variables/variable_nonspin_units_started_up.jl")
include("variables/variable_sp_objective_upperbound.jl")
include("variables/variable_storages_decommissioned.jl")
include("variables/variable_storages_invested.jl")
include("variables/variable_storages_invested_available.jl")
include("variables/variable_unit_flow.jl")
include("variables/variable_unit_flow_op.jl")
include("variables/variable_unit_flow_op_active.jl")
include("variables/variable_units_invested.jl")
include("variables/variable_units_invested_available.jl")
include("variables/variable_units_mothballed.jl")
include("variables/variable_units_on.jl")
include("variables/variable_units_out_of_service.jl")
include("variables/variable_units_returned_to_service.jl")
include("variables/variable_units_shut_down.jl")
include("variables/variable_units_started_up.jl")
include("variables/variable_units_taken_out_of_service.jl")
include("variables/variable_user_constraint_slack.jl")
# Expressions
include("expressions/capacity_margin.jl")
# Objective
include("objective/connection_flow_costs.jl")
include("objective/connection_investment_costs.jl")
include("objective/fixed_om_costs.jl")
include("objective/fuel_costs.jl")
include("objective/min_capacity_margin_penalties.jl")
include("objective/mp_objective_penalties.jl")
include("objective/objective_penalties.jl")
include("objective/renewable_curtailment_costs.jl")
include("objective/res_proc_costs.jl")
include("objective/shut_down_costs.jl")
include("objective/start_up_costs.jl")
include("objective/storage_investment_costs.jl")
include("objective/taxes.jl")
include("objective/total_costs.jl")
include("objective/unit_investment_costs.jl")
include("objective/units_on_costs.jl")
include("objective/variable_om_costs.jl")
# Constraints
include("constraints/constraint_candidate_connection_flow_lb.jl")
include("constraints/constraint_candidate_connection_flow_ub.jl")
include("constraints/constraint_common.jl")
include("constraints/constraint_compression_ratio.jl")
include("constraints/constraint_connection_flow_capacity.jl")
include("constraints/constraint_connection_flow_gas_capacity.jl")
include("constraints/constraint_connection_flow_intact_flow.jl")
include("constraints/constraint_connection_flow_lodf.jl")
include("constraints/constraint_connection_intact_flow_capacity.jl")
include("constraints/constraint_connection_intact_flow_ptdf.jl")
include("constraints/constraint_connection_lifetime.jl")
include("constraints/constraint_connection_min_flow.jl")
include("constraints/constraint_connection_unitary_gas_flow.jl")
include("constraints/constraint_connections_invested_available.jl")
include("constraints/constraint_connections_invested_transition.jl")
include("constraints/constraint_cyclic_node_state.jl")
include("constraints/constraint_fix_node_pressure_point.jl")
include("constraints/constraint_investment_group_capacity_invested_available.jl")
include("constraints/constraint_investment_group_entities_invested_available.jl")
include("constraints/constraint_investment_group_equal_investments.jl")
include("constraints/constraint_max_node_pressure.jl")
include("constraints/constraint_max_node_voltage_angle.jl")
include("constraints/constraint_min_capacity_margin.jl")
include("constraints/constraint_min_down_time.jl")
include("constraints/constraint_min_node_pressure.jl")
include("constraints/constraint_min_node_state.jl")
include("constraints/constraint_min_node_voltage_angle.jl")
include("constraints/constraint_min_scheduled_outage_duration.jl")
include("constraints/constraint_min_up_time.jl")
include("constraints/constraint_minimum_operating_point.jl")
include("constraints/constraint_mp_any_invested_cuts.jl")
include("constraints/constraint_mp_min_res_gen_to_demand_ratio_cuts.jl")
include("constraints/constraint_nodal_balance.jl")
include("constraints/constraint_node_injection.jl")
include("constraints/constraint_node_state_capacity.jl")
include("constraints/constraint_node_voltage_angle.jl")
include("constraints/constraint_non_spinning_reserves_bounds.jl")
include("constraints/constraint_operating_point_bounds.jl")
include("constraints/constraint_operating_point_rank.jl")
include("constraints/constraint_ramp_down.jl")
include("constraints/constraint_ramp_up.jl")
include("constraints/constraint_ratio_out_in_connection_flow.jl")
include("constraints/constraint_ratio_out_in_connection_intact_flow.jl")
include("constraints/constraint_ratio_unit_flow.jl")
include("constraints/constraint_storage_lifetime.jl")
include("constraints/constraint_storage_line_pack.jl")
include("constraints/constraint_storages_invested_available.jl")
include("constraints/constraint_storages_invested_transition.jl")
include("constraints/constraint_total_cumulated_unit_flow_bounds.jl")
include("constraints/constraint_unit_flow_capacity.jl")
include("constraints/constraint_unit_flow_op_bounds.jl")
include("constraints/constraint_unit_flow_op_rank.jl")
include("constraints/constraint_unit_flow_op_sum.jl")
include("constraints/constraint_unit_lifetime.jl")
include("constraints/constraint_unit_state_transition.jl")
include("constraints/constraint_units_available.jl")
include("constraints/constraint_units_invested_available.jl")
include("constraints/constraint_units_invested_transition.jl")
include("constraints/constraint_units_out_of_service_contiguity.jl")
include("constraints/constraint_units_out_of_service_transition.jl")
include("constraints/constraint_user_constraint.jl")


export unit_flow_indices
export unit_flow_op_indices
export connection_flow_indices
export node_state_indices
export units_on_indices
export units_invested_available_indices

const _template = JSON.parsefile(joinpath(@__DIR__, "..", "templates", "spineopt_template.json"))

function template()
    try
        JSON.parsefile(joinpath(@__DIR__, "..", "templates", "spineopt_template.json"))
    catch
        # Template file not found, use _template constant instead.
        # This will happen in the SpineOpt app
        _template
    end
end

end
