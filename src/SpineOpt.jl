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
using Dates
using SpineInterface
using JSON
using Printf
using Requires

import Dates: CompoundPeriod
import LinearAlgebra: BLAS.gemm, LAPACK.getri!, LAPACK.getrf!

export run_spineopt
export rerun_spineopt
export @fetch

include("run_spineopt.jl")
include("data_structure/generate_missing_items.jl")
include("util/docs_utils.jl")
include("data_structure/migration.jl")

_lazy_include_file_paths = [
	"run_spineopt_sp.jl",
	"run_spineopt_mp.jl",
	"util/misc.jl",
	"util/postprocess_results.jl",
	"util/write_information_files.jl",
	"data_structure/benders_data.jl",
	"data_structure/temporal_structure.jl",
	"data_structure/stochastic_structure.jl",
	"data_structure/preprocess_data_structure.jl",
	"data_structure/check_data_structure.jl",
	"variables/variable_common.jl",
	"variables/variable_unit_flow.jl",
	"variables/variable_unit_flow_op.jl",
	"variables/variable_connection_flow.jl",
	"variables/variable_connection_intact_flow.jl",
	"variables/variable_connections_invested.jl",
	"variables/variable_connections_invested_available.jl",
	"variables/variable_connections_decommissioned.jl",
	"variables/variable_storages_invested.jl",
	"variables/variable_storages_invested_available.jl",
	"variables/variable_storages_decommissioned.jl",
	"variables/variable_node_state.jl",
	"variables/variable_units_on.jl",
	"variables/variable_units_invested.jl",
	"variables/variable_units_invested_available.jl",
	"variables/variable_units_mothballed.jl",
	"variables/variable_units_available.jl",
	"variables/variable_units_started_up.jl",
	"variables/variable_units_shut_down.jl",
	"variables/variable_node_slack_pos.jl",
	"variables/variable_node_slack_neg.jl",
	"variables/variable_node_injection.jl",
	"variables/variable_nonspin_units_started_up.jl",
	"variables/variable_start_up_unit_flow.jl",
	"variables/variable_ramp_up_unit_flow.jl",
	"variables/variable_nonspin_ramp_up_unit_flow.jl",
	"variables/variable_shut_down_unit_flow.jl",
	"variables/variable_ramp_down_unit_flow.jl",
	"variables/variable_nonspin_ramp_down_unit_flow.jl",
	"variables/variable_nonspin_units_shut_down.jl",
	"variables/variable_node_pressure.jl",
	"variables/variable_node_voltage_angle.jl",
	"variables/variable_binary_gas_connection_flow.jl",
	"variables/variable_mp_objective_lowerbound.jl",
	"objective/set_objective.jl",
	"objective/set_mp_objective.jl",
	"objective/variable_om_costs.jl",
	"objective/fixed_om_costs.jl",
	"objective/taxes.jl",
	"objective/start_up_costs.jl",
	"objective/shut_down_costs.jl",
	"objective/fuel_costs.jl",
	"objective/unit_investment_costs.jl",
	"objective/connection_investment_costs.jl",
	"objective/storage_investment_costs.jl",
	"objective/objective_penalties.jl",
	"objective/total_costs.jl",
	"objective/renewable_curtailment_costs.jl",
	"objective/connection_flow_costs.jl",
	"objective/res_proc_costs.jl",
	"objective/ramp_costs.jl",
	"constraints/constraint_common.jl",
	"constraints/constraint_max_cum_in_unit_flow_bound.jl",
	"constraints/constraint_unit_flow_capacity.jl",
	"constraints/constraint_unit_flow_capacity_w_ramps.jl",
	"constraints/constraint_operating_point_bounds.jl",
	"constraints/constraint_operating_point_sum.jl",
	"constraints/constraint_nodal_balance.jl",
	"constraints/constraint_node_injection.jl",
	"constraints/constraint_node_state_capacity.jl",
	"constraints/constraint_cyclic_node_state.jl",
	"constraints/constraint_ratio_unit_flow.jl",
	"constraints/constraint_ratio_out_in_connection_flow.jl",
	"constraints/constraint_ratio_out_in_connection_intact_flow.jl",
	"constraints/constraint_connection_flow_capacity.jl",
	"constraints/constraint_connection_intact_flow_capacity.jl",
	"constraints/constraint_connection_flow_intact_flow.jl",
	"constraints/constraint_connection_intact_flow_ptdf.jl",
	"constraints/constraint_candidate_connection_flow_ub.jl",
	"constraints/constraint_candidate_connection_flow_lb.jl",
	"constraints/constraint_connection_flow_lodf.jl",
	"constraints/constraint_connections_invested_available.jl",
	"constraints/constraint_connections_invested_transition.jl",
	"constraints/constraint_connection_lifetime.jl",
	"constraints/constraint_storages_invested_available.jl",
	"constraints/constraint_storages_invested_transition.jl",
	"constraints/constraint_storage_lifetime.jl",
	"constraints/constraint_units_on.jl",
	"constraints/constraint_units_available.jl",
	"constraints/constraint_minimum_operating_point.jl",
	"constraints/constraint_min_up_time.jl",
	"constraints/constraint_min_down_time.jl",
	"constraints/constraint_unit_state_transition.jl",
	"constraints/constraint_user_constraint.jl",
	"constraints/constraint_units_invested_available.jl",
	"constraints/constraint_units_invested_transition.jl",
	"constraints/constraint_unit_lifetime.jl",
	"constraints/constraint_split_ramps.jl",
	"constraints/constraint_unit_pw_heat_rate.jl",
	"constraints/constraint_ramp_up.jl",
	"constraints/constraint_max_start_up_ramp.jl",
	"constraints/constraint_min_start_up_ramp.jl",
	"constraints/constraint_max_nonspin_ramp_up.jl",
	"constraints/constraint_min_nonspin_ramp_up.jl",
	"constraints/constraint_ramp_down.jl",
	"constraints/constraint_max_shut_down_ramp.jl",
	"constraints/constraint_min_shut_down_ramp.jl",
	"constraints/constraint_max_nonspin_ramp_down.jl",
	"constraints/constraint_min_nonspin_ramp_down.jl",
	"constraints/constraint_res_minimum_node_state.jl",
	"constraints/constraint_fix_node_pressure_point.jl",
	"constraints/constraint_compression_ratio.jl",
	"constraints/constraint_storage_line_pack.jl",
	"constraints/constraint_connection_flow_gas_capacity.jl",
	"constraints/constraint_max_node_pressure.jl",
	"constraints/constraint_min_node_pressure.jl",
	"constraints/constraint_max_node_voltage_angle.jl",
	"constraints/constraint_min_node_voltage_angle.jl",
	"constraints/constraint_node_voltage_angle.jl",
	"constraints/constraint_connection_unitary_gas_flow.jl",
	"constraints/constraint_mp_any_invested_cuts.jl",
]

function __init__()
	@require JuMP="4076af6c-e467-56ae-b986-b466b2749572" begin
		export unit_flow_indices
		export unit_flow_op_indices
		export connection_flow_indices
		export node_state_indices
		export units_on_indices
		export units_invested_available_indices
		using .JuMP
		for file_path in _lazy_include_file_paths
			include(file_path)
	    end
		@require Revise="295af30f-e4ad-537b-8983-00126c2a3abe" begin
			import .Revise
			for file_path in _lazy_include_file_paths
			    Revise.track(@__MODULE__, joinpath(@__DIR__, file_path))
			end
		end
	end
end

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
