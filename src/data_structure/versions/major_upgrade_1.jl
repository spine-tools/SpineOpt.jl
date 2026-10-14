#############################################################################
# Copyright (C) 2017 - 2021  Spine Project
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
"""
    major_upgrade_1(db_url, log_level; force::Bool=false, kwargs...)

Run several migrations to update the class structure and to rename, modify and move parameters.
"""
function major_upgrade_1(db_url, log_level; force::Bool=false, kwargs...)
    @log log_level 0 string(
        "Running several migrations to update the class structure and to rename, modify and move parameters..."
    )
    # (original class, new class, dimensions, mapping of dimensions, print errors)
    classes_to_be_updated = [
        ("unit__from_node", "node__to_unit", ["node", "unit"], [2, 1], true),
        ("unit__to_node_", "unit__to_node", ["unit", "node"], [1, 2], true), # Tasku: This is apparently a trick useful for superclass creation later.
        ("unit__from_node__investment_group", "unit_flow__investment_group", ["node", "unit", "investment_group"], [2, 1, 3], true),
        ("unit__from_node__user_constraint", "unit_flow__user_constraint", ["node", "unit", "user_constraint"], [2, 1, 3], true),
        ("unit__to_node__investment_group", "unit_flow__investment_group", ["unit", "node", "investment_group"], [1, 2, 3], false),
        ("unit__to_node__user_constraint", "unit_flow__user_constraint", ["unit", "node", "user_constraint"], [1, 2, 3], false),
    ]
    # (original class, original parameter name), new parameter name, merge method("sum")
    parameters_to_be_renamed = [
        # unit
        (("unit", "number_of_units"), "existing_units", ""),
        # unit availability and outages
        (("unit", "fix_units_out_of_service"), "out_of_service_count_fix", ""),
        (("unit", "initial_units_out_of_service"), "out_of_service_count_initial", ""),
        (("unit", "scheduled_outage_duration"), "outage_scheduled_duration", ""),
        (("unit", "unit_availability_factor"), "availability_factor", ""),
        (("unit", "units_unavailable"), "out_of_service_count_fix", "sum"),
        # unit online
        (("unit", "fix_units_on"), "online_count_fix", ""),
        (("unit", "initial_units_on"), "online_count_initial", ""),
        # unit installing and decommissioning
        (("unit", "unit_decommissioning_time"), "decommissioning_time", ""),
        (("unit", "unit_discount_rate_technology_specific"), "discount_rate_technology_specific", ""),
        (("unit", "unit_investment_econ_lifetime"), "lifetime_economic", ""),
        (("unit", "unit_investment_tech_lifetime"), "lifetime_technical", ""),
        (("unit", "unit_investment_lifetime_sense"), "lifetime_constraint_sense", ""),
        (("unit", "unit_investment_variable_type"), "investment_variable_type", ""),
        (("unit", "unit_lead_time"), "lead_time", ""),
        # unit investment limits
        (("unit", "candidate_units"), "investment_count_max_cumulative", ""),
        (("unit", "fix_units_invested"), "investment_count_fix_new", ""),
        (("unit", "fix_units_invested_available"), "investment_count_fix_cumulative", ""),
        (("unit", "initial_units_invested"), "investment_count_initial_new", ""),
        (("unit", "initial_units_invested_available"), "investment_count_initial_cumulative", ""),
        # unit mga
        (("unit", "units_invested_big_m_mga"), "mga_investment_big_m", ""),
        (("unit", "units_invested_mga"), "mga_investment_active", ""),
        (("unit", "units_invested_mga_weight"), "mga_investment_weight", ""),

        # node
        (("node", "has_state"), "storage_active", ""),
        (("node", "fractional_demand"), "demand_fraction", ""),
        (("node", "min_capacity_margin"), "capacity_margin_min", ""),
        (("node", "min_capacity_margin_penalty"), "capacity_margin_penalty", ""),
        (("node", "nodal_balance_sense"), "balance_sense", ""),
        (("node", "node_slack_penalty"), "balance_penalty", ""),
        # node storage other parameters
        (("node", "frac_state_loss"), "storage_self_discharge", ""),
        (("node", "number_of_storages"), "existing_storages", ""),
        (("node", "state_coeff"), "storage_state_coefficient", ""),
        (("node", "storage_fom_cost"), "storage_fixed_annual_cost", ""),
        (("node", "is_longterm_storage"), "storage_longterm_active", ""),
        # node storage limits
        (("node", "fix_node_state"), "storage_state_fix", ""),
        (("node", "initial_node_state"), "storage_state_initial", ""),
        (("node", "node_state_cap"), "storage_state_max", ""),
        (("node", "node_state_min"), "storage_state_min", ""),
        (("node", "node_availability_factor"), "storage_state_max_fraction", ""),
        (("node", "node_state_min_factor"), "storage_state_min_fraction", ""),
        # node pressure limits
        (("node", "fix_node_pressure"), "pressure_fix", ""),
        (("node", "initial_node_pressure"), "pressure_initial", ""),
        (("node", "max_node_pressure"), "pressure_max", ""),
        (("node", "min_node_pressure"), "pressure_min", ""),
        # node voltage angle limits
        (("node", "fix_node_voltage_angle"), "voltage_angle_fix", ""),
        (("node", "initial_node_voltage_angle"), "voltage_angle_initial", ""),
        (("node", "max_voltage_angle"), "voltage_angle_max", ""),
        (("node", "min_voltage_angle"), "voltage_angle_min", ""),
        # node storage installing and decommissioning # Tasku: Storage investments named different to separate potential investments into demand scaling from storage.
        (("node", "storage_investment_econ_lifetime"), "storage_lifetime_economic", ""),
        (("node", "storage_investment_tech_lifetime"), "storage_lifetime_technical", ""),
        (("node", "storage_investment_lifetime_sense"), "storage_lifetime_constraint_sense", ""),
        # node storage investment limits
        (("node", "candidate_storages"), "storage_investment_count_max_cumulative", ""),
        (("node", "fix_storages_invested"), "storage_investment_count_fix_new", ""),
        (("node", "fix_storages_invested_available"), "storage_investment_count_fix_cumulative", ""),
        (("node", "initial_storages_invested"), "storage_investment_count_initial_new", ""),
        (("node", "initial_storages_invested_available"), "storage_investment_count_initial_cumulative", ""),
        # node storage mga
        (("node", "storages_invested_big_m_mga"), "mga_storage_investment_big_m", ""),
        (("node", "storages_invested_mga"), "mga_storage_investment_active", ""),
        (("node", "storages_invested_mga_weight"), "mga_storage_investment_weight", ""),
        # node reserves
        (("node", "downward_reserve"), "reserve_downward", ""),
        (("node", "upward_reserve"), "reserve_upward", ""),
        (("node", "is_reserve_node"), "reserve_active", ""),

        # connection
        (("connection", "connection_availability_factor"), "availability_factor", ""),
        (("connection", "connection_contingency"), "contingency_active", ""),
        (("connection", "connection_monitored"), "monitoring_active", ""),
        (("connection", "connection_reactance"), "reactance", ""),
        (("connection", "connection_reactance_base"), "reactance_base", ""),
        (("connection", "connection_resistance"), "resistance", ""),
        (("connection", "number_of_connections"), "existing_connections", ""),
        (("connection", "has_binary_gas_flow"), "binary_gas_flow_active", ""),
        # connection installing and decommissioning
        (("connection", "connection_decommissioning_cost"), "decommissioning_cost", ""),
        (("connection", "connection_decommissioning_time"), "decommissioning_time", ""),
        (("connection", "connection_discount_rate_technology_specific"), "discount_rate_technology_specific", ""),
        (("connection", "connection_investment_econ_lifetime"), "lifetime_economic", ""),
        (("connection", "connection_investment_lifetime_sense"), "lifetime_constraint_sense", ""),
        (("connection", "connection_investment_tech_lifetime"), "lifetime_technical", ""),
        (("connection", "connection_investment_variable_type"), "investment_variable_type", ""),
        (("connection", "connection_lead_time"), "lead_time", ""),
        # connection investment limits
        (("connection", "candidate_connections"), "investment_count_max_cumulative", ""),
        (("connection", "fix_connections_invested"), "investment_count_fix_new", ""),
        (("connection", "fix_connections_invested_available"), "investment_count_fix_cumulative", ""),
        (("connection", "initial_connections_invested"), "investment_count_initial_new", ""),
        (("connection", "initial_connections_invested_available"), "investment_count_initial_cumulative", ""),
        # connection mga
        (("connection", "connections_invested_big_m_mga"), "mga_investment_big_m", ""),
        (("connection", "connections_invested_mga"), "mga_investment_active", ""),
        (("connection", "connections_invested_mga_weight"), "mga_investment_weight", ""),

        # commodity
        (("commodity", "commodity_lodf_tolerance"), "lodf_tolerance", ""),
        (("commodity", "commodity_physics"), "physics_type", ""),
        (("commodity", "commodity_physics_duration"), "physics_duration", ""),
        (("commodity", "commodity_ptdf_threshold"), "ptdf_threshold", ""),

        # investment_group
        (("investment_group", "equal_investments"), "equal_investments_active", ""),
        (("investment_group", "maximum_capacity_invested_available"), "investment_capacity_total_max_cumulative", ""),
        (("investment_group", "maximum_entities_invested_available"), "investment_count_total_max_cumulative", ""),
        (("investment_group", "minimum_capacity_invested_available"), "investment_capacity_total_min_cumulative", ""),
        (("investment_group", "minimum_entities_invested_available"), "investment_count_total_min_cumulative", ""),

        # model
        (("model", "db_lp_solver"), "solver_lp", ""),
        (("model", "db_lp_solver_options"), "solver_lp_options", ""),
        (("model", "db_mip_solver"), "solver_mip", ""),
        (("model", "db_mip_solver_options"), "solver_mip_options", ""),
        (("model", "max_gap"), "decomposition_max_gap", ""),
        (("model", "max_iterations"), "decomposition_max_iterations", ""),
        (("model", "max_mga_iterations"), "mga_max_iterations", ""),
        (("model", "max_mga_slack"), "mga_max_slack", ""),
        (("model", "min_iterations"), "decomposition_min_iterations", ""),
        (("model", "report_benders_iterations"), "benders_iterations_reporting_active", ""),
        (("model", "use_connection_intact_flow"), "connection_investment_power_flow_impact_active", ""),
        (("model", "use_highest_resolution_constraint_ratio_out_in_connection_flow"), "connection_flow_highest_resolution_active", ""),
        (("model", "use_tight_compact_formulations"), "tight_compact_formulations_active", ""),

        # node__node
        (("node__node", "diff_coeff"), "diffusion_coefficient", ""),

        # node__user_constraint
        (("node__user_constraint", "demand_coefficient"), "coefficient_for_demand", ""),
        (("node__user_constraint", "node_state_coefficient"), "coefficient_for_node_state", ""),
        (("node__user_constraint", "storages_invested_available_coefficient"), "coefficient_for_storages_invested_available", ""),
        (("node__user_constraint", "storages_invested_coefficient"), "coefficient_for_storages_invested", ""),

        # unit__to_node and node__to_unit
        (("unit__to_node", "fix_unit_flow"), "flow_limits_fix", ""),
        (("node__to_unit", "fix_unit_flow"), "flow_limits_fix", ""),
        (("unit__to_node", "fix_unit_flow_op"), "flow_limits_fix_op", ""),
        (("node__to_unit", "fix_unit_flow_op"), "flow_limits_fix_op", ""),
        (("unit__to_node", "initial_unit_flow"), "flow_limits_initial", ""),
        (("node__to_unit", "initial_unit_flow"), "flow_limits_initial", ""),
        (("unit__to_node", "initial_unit_flow_op"), "flow_limits_initial_op", ""),
        (("node__to_unit", "initial_unit_flow_op"), "flow_limits_initial_op", ""),
        (("node__to_unit", "max_total_cumulated_unit_flow_from_node"), "flow_limits_max_cumulative", ""),
        (("node__to_unit", "min_total_cumulated_unit_flow_from_node"), "flow_limits_min_cumulative", ""),
        (("unit__to_node", "min_unit_flow"), "flow_limits_min", ""),
        (("node__to_unit", "min_unit_flow"), "flow_limits_min", ""),
        (("unit__to_node", "ramp_down_limit"), "ramp_limits_down", ""),
        (("node__to_unit", "ramp_down_limit"), "ramp_limits_down", ""),
        (("unit__to_node", "ramp_up_limit"), "ramp_limits_up", ""),
        (("node__to_unit", "ramp_up_limit"), "ramp_limits_up", ""),
        (("unit__to_node", "shut_down_limit"), "ramp_limits_shutdown", ""),
        (("node__to_unit", "shut_down_limit"), "ramp_limits_shutdown", ""),
        (("unit__to_node", "start_up_limit"), "ramp_limits_startup", ""),
        (("node__to_unit", "start_up_limit"), "ramp_limits_startup", ""),
        (("unit__to_node", "unit_capacity"), "capacity_per_unit", ""),
        (("node__to_unit", "unit_capacity"), "capacity_per_unit", ""),
        (("unit__to_node", "unit_conv_cap_to_flow"), "capacity_to_flow_conversion_factor", ""),
        (("node__to_unit", "unit_conv_cap_to_flow"), "capacity_to_flow_conversion_factor", ""),

        # unit__user_constraint
        (("unit__user_constraint", "units_invested_available_coefficient"), "coefficient_for_units_invested_available", ""),
        (("unit__user_constraint", "units_invested_coefficient"), "coefficient_for_units_invested", ""),
        (("unit__user_constraint", "units_on_coefficient"), "coefficient_for_units_on", ""),
        (("unit__user_constraint", "units_started_up_coefficient"), "coefficient_for_units_started_up", ""),

        # unit_flow__user_constraint (These renamings happen after the class updates defined above)
        (("unit_flow__user_constraint", "unit_flow_coefficient"), "coefficient_for_unit_flow", ""),

        # connection__from_node and # connection__to_node #TODO: These might be reworked into node__connection__node later.
        (("connection__from_node", "fix_binary_gas_connection_flow"), "binary_gas_flow_limits_fix", ""),
        (("connection__to_node", "fix_binary_gas_connection_flow"), "binary_gas_flow_limits_fix", ""),
        (("connection__from_node", "initial_binary_gas_connection_flow"), "binary_gas_flow_limits_initial", ""),
        (("connection__to_node", "initial_binary_gas_connection_flow"), "binary_gas_flow_limits_initial", ""),
        (("connection__from_node", "fix_connection_flow"), "flow_limits_fix", ""),
        (("connection__to_node", "fix_connection_flow"), "flow_limits_fix", ""),
        (("connection__from_node", "fix_connection_intact_flow"), "flow_limits_fix_intact", ""),
        (("connection__to_node", "fix_connection_intact_flow"), "flow_limits_fix_intact", ""),
        (("connection__from_node", "initial_connection_flow"), "flow_limits_initial", ""),
        (("connection__to_node", "initial_connection_flow"), "flow_limits_initial", ""),
        (("connection__from_node", "initial_connection_intact_flow"), "flow_limits_initial_intact", ""),
        (("connection__to_node", "initial_connection_intact_flow"), "flow_limits_initial_intact", ""),
        (("connection__from_node", "connection_capacity"), "capacity_per_connection", ""),
        (("connection__to_node", "connection_capacity"), "capacity_per_connection", ""),
        (("connection__from_node", "connection_conv_cap_to_flow"), "capacity_to_flow_conversion_factor", ""),
        (("connection__to_node", "connection_conv_cap_to_flow"), "capacity_to_flow_conversion_factor", ""),

        # connection__from_node__user_constraint #TODO: These might be reworked into node__connection__node later.
        (("connection__from_node__user_constraint", "connection_flow_coefficient"), "coefficient_for_connection_flow", ""),
        (("connection__to_node__user_constraint", "connection_flow_coefficient"), "coefficient_for_connection_flow", ""),

        # connection__user_constraint
        (("connection__user_constraint", "connections_invested_available_coefficient"), "coefficient_for_connections_invested_available", ""),
        (("connection__user_constraint", "connections_invested_coefficient"), "coefficient_for_connections_invested", ""),

        # temporal_block
        (("temporal_block", "representative_period_index"), "representative_block_index", ""),
        (("temporal_block", "representative_periods_mapping"), "representative_blocks_by_period", ""),
    ]

    # ((class, parameter name before renaming), multiplication factor)
    # Scaling happens before renaming so that only the migrated values are scaled,
    # not any values of an already existing (e.g. hand-made) new parameter.
    parameters_to_be_scaled = [
        (("node", "storage_fom_cost"), 8760), # per-hour cost -> per-year cost (storage_fixed_annual_cost)
    ]

    # original class, new class
    classes_to_be_renamed = [
        ("commodity", "grid")
    ]

    # (original class, original parameter name), (new class, list of dimensions, new parameter name, mapping of dimensions)
    parameters_to_multidimensional_classes = [
        # Unit__node1__node2 --> unit__node1, unit__node2 ratios
        (("unit__node__node", "fix_ratio_out_in_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_coefficient", [1, 2, 3, 1])),
        (("unit__node__node", "fix_ratio_in_out_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_coefficient", [2, 1, 1, 3])),
        (("unit__node__node", "fix_ratio_in_in_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_coefficient", [2, 1, 3, 1])),
        (("unit__node__node", "fix_ratio_out_out_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_coefficient", [1, 2, 1, 3])),
        (("unit__node__node", "min_ratio_out_in_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_coefficient", [1, 2, 3, 1])),
        (("unit__node__node", "min_ratio_in_out_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_coefficient", [2, 1, 1, 3])),
        (("unit__node__node", "min_ratio_in_in_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_coefficient", [2, 1, 3, 1])),
        (("unit__node__node", "min_ratio_out_out_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_coefficient", [1, 2, 1, 3])),
        (("unit__node__node", "max_ratio_out_in_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_coefficient", [1, 2, 3, 1])),
        (("unit__node__node", "max_ratio_in_out_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_coefficient", [2, 1, 1, 3])),
        (("unit__node__node", "max_ratio_in_in_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_coefficient", [2, 1, 3, 1])),
        (("unit__node__node", "max_ratio_out_out_unit_flow"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_coefficient", [1, 2, 1, 3])),

        # Unit__node1__node2 --> unit__node1, unit__node2 coefficients
        (("unit__node__node", "fix_units_on_coefficient_out_in"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_online_coefficient", [1, 2, 3, 1])),
        (("unit__node__node", "fix_units_on_coefficient_in_out"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_online_coefficient", [2, 1, 1, 3])),
        (("unit__node__node", "fix_units_on_coefficient_in_in"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_online_coefficient", [2, 1, 3, 1])),
        (("unit__node__node", "fix_units_on_coefficient_out_out"), 
            ("unit_flow__unit_flow", "flow_ratio_equality_online_coefficient", [1, 2, 1, 3])),
        (("unit__node__node", "min_units_on_coefficient_out_in"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_online_coefficient", [1, 2, 3, 1])),
        (("unit__node__node", "min_units_on_coefficient_in_out"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_online_coefficient", [2, 1, 1, 3])),
        (("unit__node__node", "min_units_on_coefficient_in_in"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_online_coefficient", [2, 1, 3, 1])),
        (("unit__node__node", "min_units_on_coefficient_out_out"), 
            ("unit_flow__unit_flow", "flow_ratio_greater_than_online_coefficient", [1, 2, 1, 3])),
        (("unit__node__node", "max_units_on_coefficient_out_in"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_online_coefficient", [1, 2, 3, 1])),
        (("unit__node__node", "max_units_on_coefficient_in_out"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_online_coefficient", [2, 1, 1, 3])),
        (("unit__node__node", "max_units_on_coefficient_in_in"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_online_coefficient", [2, 1, 3, 1])),
        (("unit__node__node", "max_units_on_coefficient_out_out"), 
            ("unit_flow__unit_flow", "flow_ratio_less_than_online_coefficient", [1, 2, 1, 3])),

        # unit__node__node startup flows
        # This parameter was only ever apparantly meant for input-output dimensions:
        (("unit__node__node", "unit_start_flow"),
            ("unit_flow__unit_flow", "flow_ratio_start_flow", [2, 1, 1, 3])),
        #=
        # Uncomment in case anyone ever needs to enable the "full migration" despite resulting in duplicate values.
        (("unit__node__node", "unit_start_flow"),
            ("unit_flow__unit_flow", "flow_ratio_start_flow", [2, 1, 3, 1])),
        (("unit__node__node", "unit_start_flow"),
            ("unit_flow__unit_flow", "flow_ratio_start_flow", [1, 2, 3, 1])),
        (("unit__node__node", "unit_start_flow"),
            ("unit_flow__unit_flow", "flow_ratio_start_flow", [1, 2, 1, 3])),
        =#
    ]

    # original class,
    classes_to_be_removed = [ # These happen after other processing has already been done.
        "unit__commodity",
        "unit__node__node"
    ]
    # Remove obsolete parameters, (<class>, <parameter_name>)
    parameters_to_be_removed = [
        ("user_constraint", "include_in_non_representative_periods"),
    ]
    # (original parameter value list, new parameter value list)
    lists_to_be_renamed = [
        ("commodity_physics_list", "grid_physics_list"),
        ("db_lp_solver_list", "solver_lp_list"),
        ("db_mip_solver_list", "solver_mip_list")
    ]

    # (parameter value list, Dict of renamings)
    list_values_to_be_renamed = [
        (
            "grid_physics_list", Dict(
                "commodity_physics_lodf" => "lodf_physics",
                "commodity_physics_none" => "none",
                "commodity_physics_ptdf" => "ptdf_physics"
            )
        )
        (
            "balance_type_list", Dict(
                "balance_type_none" => "none",
                "balance_type_node" => "node_balance",
                "balance_type_group" => "group_balance"
            )
        )
    ]
    @log log_level 0 string("Creating superclasses...")
    @log log_level 0 string("Note: Check entity alternatives in classes related to the unit_flow superclass...")
    # Move `unit__to_node` aside, so that it can be recreated as a subclass of `unit_flow`.
    # NOTE: Copied instead of renamed, since spinedb_api may keep finding the entities of a renamed class under its
    # old name (e.g. if they were looked up before, as when importing a template), blocking their re-addition.
    update_ordering_of_multidimensional_classes(
        db_url, [("unit__to_node", "unit__to_node_", ["unit", "node"], [1, 2], true)], log_level
    )
    create_superclasses_and_subclasses(db_url, log_level)
    @log log_level 0 string("Update ordering of multidimensional classes...")
    update_ordering_of_multidimensional_classes(db_url, classes_to_be_updated, log_level)
    @log log_level 0 string("Scaling parameter values...")
    scale_parameter_values(db_url, parameters_to_be_scaled, log_level)
    @log log_level 0 string("Renaming parameters...")
    rename_parameters(db_url, parameters_to_be_renamed, log_level)
    @log log_level 0 string("Renaming classes...")
    rename_classes(db_url, classes_to_be_renamed, log_level)
    @log log_level 0 string("Moving parameters to multidimensional classes...")
    @log log_level 0 string("Note: Pay attention to the error messages. Some old databases may include mistakes where \
        unit__node__node entities do not have the corresponding unit__to_node or unit__from_node entities. In that case, \
        fix the database manually after noting the problematic entities from the error messages, and then try again.")
    move_parameters_to_multidimensional_classes(db_url, parameters_to_multidimensional_classes, log_level)
    @log log_level 0 string("Removing classes...")
    remove_classes(db_url, classes_to_be_removed, log_level)
    @log log_level 0 string("Removing parameters...")
    remove_parameters(db_url, parameters_to_be_removed, log_level)
    @log log_level 0 string("Renaming parameter value lists...")
    rename_parameter_value_lists(db_url, lists_to_be_renamed, log_level)
    @log log_level 0 string("Renaming list values...")
    rename_list_values(db_url, list_values_to_be_renamed, log_level)
    @log log_level 0 string("Merging variable type lists...")
    merge_variable_type_lists(db_url, log_level)
    @log log_level 0 string("Move node physics parameters to grid physics...")
    move_parameters(db_url, log_level)
    true
end

# Always check the last item
function check_run_request_return_value(value_to_be_checked, log_level, print_value=true)
    if !isnothing(value_to_be_checked[end]) && value_to_be_checked[end] != ""
        if print_value
            @log log_level 0 string(value_to_be_checked[end])
        end
        throw(error())
    end
end

# Add parameter values from a parameter value item list to a dictionary
function create_dict_from_parameter_value_items(db_url, pvals)
    existing_values = Dict{Any, Vector{Tuple{Any, Any}}}()
    for pval in pvals
        entity = pval["entity_byname"]
        # Values from a parameter value list are resolved via the list value,
        # since `pval["value"]` is not updated when the list value is renamed
        if pval["type"] == "list_value_ref" || !isnothing(get(pval, "list_value_id", nothing))
            list_value = run_request(db_url, "call_method", ("get_list_value_item",), Dict(
                "id" => pval["list_value_id"])
            )
            parsed_value = parse_db_value(list_value["value"], list_value["type"])
        else
            parsed_value = parse_db_value(pval["value"], pval["type"])
        end
        if !haskey(existing_values, entity)
            existing_values[entity] = [(pval["alternative_name"], parsed_value)]
        else
            push!(existing_values[entity], (pval["alternative_name"], parsed_value))
        end
    end
    return existing_values
end

# For each alternative, find the first value of related entities' specific set of parameters
# (take the multiplicative inverse)
function find_multiplier_first(db_url, entity_item, multiplier_items, vals)
    multipliers = Dict()
    added_alternatives = Array{String}(undef, 0)
    # For each class in multiplier_items, find the items where entity_item is in the correct position	
    for multiplier_item in multiplier_items
        related_entities = find_related_entities(db_url, multiplier_item[1], entity_item, multiplier_item[3])
        # Go through the items, check if they have the correct parameter
        for related_entity in related_entities
            if haskey(vals, related_entity["element_name_list"])
                val_list = vals[related_entity["element_name_list"]]
                # Go through the parameter alternatives and add to multipliers if the same alternative is not yet there
                for (alternative_name, val) in val_list
                    if !(alternative_name in added_alternatives)
                        if !haskey(multipliers, (multiplier_item[1], related_entity))
                            multipliers[(multiplier_item[1], related_entity)] = [(alternative_name, 1 / val)]
                        else
                            push!(multipliers[(multiplier_item[1], related_entity)], (alternative_name, 1 / val))
                        end
                        push!(added_alternatives, alternative_name)
                    end
                end
            end
        end
    end
    return multipliers
end

# Find entities in class_name which have entity_item in the linking_dimension dimension
function find_related_entities(db_url, class_name, entity_item, linking_dimension)
    related_entities = Array{Any}(undef, 0)
    entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict(
        "entity_class_name" => class_name)
    )
    for entity in entity_items
        if entity["element_name_list"][linking_dimension] == entity_item[1]
            push!(related_entities, entity)
        end
    end
    return related_entities
end

# Check if alternatives are the same and add a combination to the database if not. 
# Return the updated alternative and boolean describing if original alternatives were the same.
function add_merged_alternative(db_url, alternative_name_1, alternative_name_2, log_level)
    alternatives_the_same = false
    if alternative_name_1 == alternative_name_2
        alternative_updated = alternative_name_1
        alternatives_the_same = true
    else
        # Create a new alternative based on the two and add
        alternative_updated = string(alternative_name_1, "__", alternative_name_2)
        try
            @log log_level 0 string("Warning: Creating a new alternative $alternative_updated, add manually to \
                the scenarios.")
            check_run_request_return_value(run_request(
                db_url, "call_method", ("add_alternative_item",), Dict(
                    "name" => alternative_updated)
                ), log_level
            )
        catch
            @log log_level 0 string("Warning: Could not create alternative $alternative_updated.")
        end
    end
    return alternative_updated, alternatives_the_same
end


# Create specific new classes as superclasses and subclasses
function create_superclasses_and_subclasses(db_url, log_level)
    # Ensure existence of `investment_group` and `user_constraint`
    for required_class in ("user_constraint", "investment_group")
        class_item = run_request(db_url, "call_method", ("get_entity_class_item",), Dict("name" => required_class))
        if length(class_item) == 0
            @log log_level 0 string("`$required_class` not found! -> Creating it as an empty class.")
            check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
                "name" => required_class, "dimension_name_list" => [])), log_level
            )
        end
    end
    # Add new classes, each separately so that already existing (e.g. hand-made) ones don't stop the others
    new_classes = (
        ("unit__to_node", ["unit", "node"]),
        ("node__to_unit", ["node", "unit"]),
        ("unit_flow", []),
        ("unit_flow__unit_flow", ["unit_flow", "unit_flow"]),
        ("unit_flow__investment_group", ["unit_flow", "investment_group"]),
        ("unit_flow__user_constraint", ["unit_flow", "user_constraint"]),
    )
    for (class_name, dimension_name_list) in new_classes
        try
            add_entity_class_if_missing(db_url, class_name, dimension_name_list, log_level)
        catch
            @log log_level 0 string("Could not add class $class_name.")
        end
    end
    for subclass_name in ("node__to_unit", "unit__to_node")
        try
            add_superclass_subclass_if_missing(db_url, "unit_flow", subclass_name, log_level)
        catch
            @log log_level 0 string("Could not add $subclass_name as a subclass of unit_flow.")
        end
    end
end

# Add an entity class unless it already exists with the same dimensions.
# An existing class with different dimensions is replaced, since dimensions cannot be updated.
function add_entity_class_if_missing(db_url, class_name, dimension_name_list, log_level)
    class_item = run_request(db_url, "call_method", ("get_entity_class_item",), Dict("name" => class_name))
    if length(class_item) > 0
        collect(class_item["dimension_name_list"]) == collect(dimension_name_list) && return
        @log log_level 0 string("Warning: Replacing the existing class $class_name with dimensions ",
            "$(class_item["dimension_name_list"]) by one with dimensions $dimension_name_list.")
        check_run_request_return_value(run_request(
            db_url, "call_method", ("remove_entity_class_item", class_item["id"])), log_level
        )
    end
    check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
        "name" => class_name, "dimension_name_list" => dimension_name_list)), log_level
    )
end

# Make `subclass_name` a subclass of `superclass_name`, also if it is already a subclass of another superclass
function add_superclass_subclass_if_missing(db_url, superclass_name, subclass_name, log_level)
    item = run_request(db_url, "call_method", ("get_item", "superclass_subclass"), Dict("subclass_name" => subclass_name))
    if length(item) > 0
        item["superclass_name"] == superclass_name && return
        check_run_request_return_value(run_request(
            db_url, "call_method", ("remove_superclass_subclass_item", item["id"])), log_level
        )
    end
    check_run_request_return_value(run_request(db_url, "call_method", ("add_superclass_subclass_item",), Dict(
        "superclass_name" => superclass_name, "subclass_name" => subclass_name)), log_level
    )
end

# Go through the classes, update ordering of their dimensions and commit session
function update_ordering_of_multidimensional_classes(db_url, classes_to_be_updated, log_level)
    for (old_class, new_class, dimensions, mapping, print_errors) in classes_to_be_updated
        # Check if old class exists to be updated
        class_item = run_request(db_url, "call_method", ("get_entity_class_item",), Dict("name" => old_class))
        if length(class_item) > 0
            # Create (update) new class
            update_ordering_of_multidimensional_class(
                db_url, old_class, new_class, dimensions, mapping, print_errors, log_level
            )
            # Remove old class
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_entity_class_item", class_item["id"])), log_level
            )
        end
    end
end

# Update ordering of class dimensions, add as a new class
function update_ordering_of_multidimensional_class(
    db_url, old_class, new_class, dimensions, mapping, print_errors, log_level
)
    try
        # Create new class
        check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
            "name" => new_class, "dimension_name_list" => dimensions)), log_level, false
        )
    catch
    end
    # Add parameter definitions
    pdefs = run_request(db_url, "call_method", ("get_parameter_definition_items",), Dict(
        "entity_class_name" => old_class)
    )
    for pdef in pdefs
        existing_pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
            "entity_class_name" => new_class, "name" => pdef["name"])
        )
        try
            if length(existing_pdef) > 0
                # E.g. hand-made or from another old class: the definition of the migrated class takes precedence
                update_parameter_definition_attributes(db_url, existing_pdef, pdef, log_level)
            else
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("add_parameter_definition_item",), Dict(
                        "entity_class_name" => new_class,
                        "name" => pdef["name"],
                        "default_value" => pdef["default_value"],
                        "default_type" => pdef["default_type"],
                        "parameter_value_list_name" => pdef["parameter_value_list_name"],
                        "description" => pdef["description"])
                    ), log_level, print_errors
                )
            end
        catch
        end
    end
    # Add the entities into the database if they are not there already (e.g. hand-made)
    entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict(
        "entity_class_name" => old_class)
    )
    existing_bynames = entity_bynames(db_url, new_class)
    for entity_item in entity_items
        # The byname of a 0-D entity is its name (and its mapping is [1])
        element_name_list = isempty(entity_item["element_name_list"]) ?
            [entity_item["name"]] : entity_item["element_name_list"]
        new_element_name_list = [element_name_list[i] for i in mapping]
        try
            add_entity_if_missing(db_url, new_class, new_element_name_list, log_level;
                description=entity_item["description"], existing_bynames
            )
        catch
            @log log_level 0 string("Could not add entity $new_element_name_list into $new_class.")
        end
    end
    for pdef in pdefs
        # Find old parameters in all entities and alternatives
        pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
            "entity_class_name" => old_class, "parameter_definition_name" => pdef["name"])
        )
        vals = create_dict_from_parameter_value_items(db_url, pvals)
        for (old_entity, val_list) in vals
            # Determine element name list
            new_element_name_list = [old_entity[i] for i in mapping]
            for (alternative, val) in val_list
                db_value, db_type = unparse_db_value(val)
                # Migrated values overwrite existing (e.g. hand-made) ones
                try
                    check_run_request_return_value(run_request(
                        db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                            "entity_class_name" => new_class,
                            "entity_byname" => new_element_name_list,
                            "alternative_name" => alternative,
                            "parameter_definition_name" => pdef["name"],
                            "value" => db_value,
                            "type" => db_type)
                        ), log_level
                    )
                catch
                    @log log_level 0 string("Could not move value of `$(pdef["name"])` ",
                        "for $new_element_name_list in alternative `$alternative` into $new_class.")
                end
            end
        end
    end
end

# The bynames of the entities of the given class, e.g. ["n"] for a 0-D entity and ["u", "n"] for a 2-D one
function entity_bynames(db_url, class_name)
    entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict("entity_class_name" => class_name))
    Set(isempty(x["element_name_list"]) ? [x["name"]] : collect(x["element_name_list"]) for x in entity_items)
end

# Add an entity unless it already exists. `existing_bynames` can be given to avoid querying the class repeatedly.
function add_entity_if_missing(
    db_url, class_name, entity_byname, log_level;
    description=nothing, existing_bynames=entity_bynames(db_url, class_name)
)
    collect(entity_byname) in existing_bynames && return
    check_run_request_return_value(run_request(
        db_url, "call_method", ("add_entity_item",), Dict(
            "entity_class_name" => class_name, "entity_byname" => entity_byname, "description" => description)
        ), log_level
    )
    push!(existing_bynames, collect(entity_byname))
end

# Go through the parameters, rename them and commit session
function rename_parameters(db_url, parameters_to_be_renamed, log_level)
    for (old_par_def, new_par_name, merge_method) in parameters_to_be_renamed
        rename_parameter(db_url, old_par_def[1], old_par_def[2], new_par_name, merge_method, log_level)
    end
end

# Find the parameter id and rename the parameter
function rename_parameter(db_url, class_name, old_par_name, new_par_name, merge_method, log_level)
    pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
        "entity_class_name" => class_name, "name" => old_par_name)
    )
    if length(pdef) > 0
        if merge_method == "sum"
            sum_to_existing_parameter(db_url, class_name, old_par_name, new_par_name, log_level)
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_parameter_definition_item", pdef["id"])), log_level
            )
        else
            new_pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
                "entity_class_name" => class_name, "name" => new_par_name)
            )
            if length(new_pdef) > 0
                merge_parameter_definition(db_url, class_name, pdef, new_pdef, log_level)
            else
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("update_item", "parameter_definition"), Dict(
                    "id" => pdef["id"], "name" => new_par_name)
                    ), log_level
                )
            end
        end
    end
end

# Merge the old parameter definition into an already existing (e.g. hand-made) new one and remove the old one.
# The old definition's attributes and values take precedence; other existing values are kept.
function merge_parameter_definition(db_url, class_name, old_pdef, new_pdef, log_level)
    existing_pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => class_name, "parameter_definition_name" => new_pdef["name"])
    )
    # Only worth a warning if there is existing data, not e.g. for an empty definition from an imported template
    if !isempty(existing_pvals)
        @log log_level 0 string("Warning: `$(new_pdef["name"])` already exists in `$class_name` with values. ",
            "Merging `$(old_pdef["name"])` into it; migrated values overwrite existing ones in the same alternative.")
    end
    update_parameter_definition_attributes(db_url, new_pdef, old_pdef, log_level)
    pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => class_name, "parameter_definition_name" => old_pdef["name"])
    )
    vals = create_dict_from_parameter_value_items(db_url, pvals)
    for (entity, val_list) in vals
        for (alternative, val) in val_list
            pval_value, pval_type = unparse_db_value(val)
            check_run_request_return_value(run_request(
                db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                    "entity_class_name" => class_name, "parameter_definition_name" => new_pdef["name"],
                    "entity_byname" => entity, "alternative_name" => alternative,
                    "value" => pval_value, "type" => pval_type)
                ), log_level
            )
        end
    end
    check_run_request_return_value(run_request(
        db_url, "call_method", ("remove_parameter_definition_item", old_pdef["id"])), log_level
    )
end

# Overwrite the default value, value list and description of a parameter definition with those of `source_pdef`
function update_parameter_definition_attributes(db_url, pdef, source_pdef, log_level)
    if pdef["parameter_value_list_name"] != source_pdef["parameter_value_list_name"]
        set_parameter_value_list(db_url, pdef, source_pdef["parameter_value_list_name"], log_level)
    end
    check_run_request_return_value(run_request(
        db_url, "call_method", ("update_item", "parameter_definition"), Dict(
            "id" => pdef["id"],
            "default_value" => source_pdef["default_value"],
            "default_type" => source_pdef["default_type"],
            "description" => source_pdef["description"])
        ), log_level
    )
end

# Set the value list of a parameter definition.
# The list of a definition with values cannot be changed, so its values are removed first and then added back;
# values (and the default value) that are not in the new list are dropped with a warning.
function set_parameter_value_list(db_url, pdef, list_name, log_level)
    class_name, par_name = pdef["entity_class_name"], pdef["name"]
    pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => class_name, "parameter_definition_name" => par_name)
    )
    vals = create_dict_from_parameter_value_items(db_url, pvals)
    for pval in pvals
        check_run_request_return_value(run_request(
            db_url, "call_method", ("remove_parameter_value_item", pval["id"])), log_level
        )
    end
    old_list_name = pdef["parameter_value_list_name"]
    try
        # The default value is dropped first, since it may not be in the new list
        check_run_request_return_value(run_request(
            db_url, "call_method", ("update_item", "parameter_definition"), Dict(
                "id" => pdef["id"], "parameter_value_list_name" => list_name,
                "default_value" => nothing, "default_type" => nothing)
            ), log_level
        )
    catch
        add_parameter_values(db_url, class_name, par_name, vals, old_list_name, log_level) # Restore
        rethrow()
    end
    try
        check_run_request_return_value(run_request(
            db_url, "call_method", ("update_item", "parameter_definition"), Dict(
                "id" => pdef["id"], "default_value" => pdef["default_value"], "default_type" => pdef["default_type"])
            ), log_level, false
        )
    catch
        @log log_level 0 string("Warning: Dropped the default value of `$par_name` in $class_name, ",
            "since it is not in the parameter value list `$list_name` ",
            "(the default value of the latest template is applied at the end of the migration).")
    end
    add_parameter_values(db_url, class_name, par_name, vals, list_name, log_level)
end

# Add the given values (as from `create_dict_from_parameter_value_items`) to a parameter;
# values that are not in its parameter value list are dropped with a warning.
function add_parameter_values(db_url, class_name, par_name, vals, list_name, log_level)
    # NOTE: Checked explicitly, since adding a value that is not in the list doesn't always return an error
    list_values = isnothing(list_name) ? nothing : [
        parse_db_value(x["value"], x["type"])
        for x in run_request(db_url, "call_method", ("find_list_values",), Dict("parameter_value_list_name" => list_name))
    ]
    for (entity, val_list) in vals
        for (alternative, val) in val_list
            if !isnothing(list_values) && !(val in list_values)
                @log log_level 0 string("Warning: Dropped value `$val` of `$par_name` for $entity in alternative ",
                    "`$alternative`, since it is not in the parameter value list `$list_name`.")
                continue
            end
            pval_value, pval_type = unparse_db_value(val)
            check_run_request_return_value(run_request(
                db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                    "entity_class_name" => class_name, "parameter_definition_name" => par_name,
                    "entity_byname" => entity, "alternative_name" => alternative,
                    "value" => pval_value, "type" => pval_type)
                ), log_level
            )
        end
    end
end

# Multiply the values (and the default value) of each given parameter by the given factor
function scale_parameter_values(db_url, parameters_to_be_scaled, log_level)
    for ((class_name, par_name), factor) in parameters_to_be_scaled
        pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
            "entity_class_name" => class_name, "name" => par_name)
        )
        length(pdef) > 0 || continue
        # Find parameters in all entities and alternatives
        pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
            "entity_class_name" => class_name, "parameter_definition_name" => par_name)
        )
        vals = create_dict_from_parameter_value_items(db_url, pvals)
        for (entity, val_list) in vals
            for (alternative, val) in val_list
                pval_value, pval_type = unparse_db_value(val * factor)
                # Update the parameter value in the database
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                        "entity_class_name" => class_name, "parameter_definition_name" => par_name,
                        "entity_byname" => entity, "alternative_name" => alternative,
                        "value" => pval_value, "type" => pval_type)
                    ), log_level
                )
            end
        end
        # Scale the default value too, if any
        default_value = parse_db_value(pdef["default_value"], pdef["default_type"])
        if !isnothing(default_value)
            default_value, default_type = unparse_db_value(default_value * factor)
            check_run_request_return_value(run_request(
                db_url, "call_method", ("update_item", "parameter_definition"), Dict(
                    "id" => pdef["id"], "default_value" => default_value, "default_type" => default_type)
                ), log_level
            )
        end
    end
end

# Sum old_par_name values to new_par_name values
function sum_to_existing_parameter(db_url, class_name, old_par_name, new_par_name, log_level)
    # Find old parameters in all entities and alternatives
    pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => class_name, "parameter_definition_name" => old_par_name)
    )
    vals = create_dict_from_parameter_value_items(db_url, pvals)
    # Find existing parameters in all entities and alternatives
    pvals_existing = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => class_name, "parameter_definition_name" => new_par_name)
    )
    existing_values = create_dict_from_parameter_value_items(db_url, pvals_existing)
    for (entity, val_list) in vals
        for (alternative, val) in val_list
            base_alternative_added = false
            # Find if entity in existing_values
            if haskey(existing_values, entity)
                summed_parsed_pval = val
                # Loop over alternatives in existing_values[entity]
                for existing_value in existing_values[entity]
                    alternative_updated, base_alternative_added = add_merged_alternative(
                        db_url, alternative, existing_value[1], log_level
                    )
                    summed_parsed_pval += existing_value[2]
                    summed_pval_value, summed_pval_type = unparse_db_value(summed_parsed_pval)
                    # Add the new parameter value into the database
                    check_run_request_return_value(run_request(
                        db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                            "entity_class_name" => class_name, "parameter_definition_name" => new_par_name, 
                            "entity_byname" => entity, 
                            "alternative_name" => alternative_updated, 	
                            "value" => summed_pval_value, "type" => summed_pval_type)
                        ), log_level
                    )
                end
            end
            pval_value, pval_type = unparse_db_value(val)
            if !base_alternative_added
                # Add the new parameter value into the database
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                        "entity_class_name" => class_name, "parameter_definition_name" => new_par_name, 
                        "entity_byname" => entity, "alternative_name" => alternative, 
                        "value" => pval_value, "type" => pval_type)
                    ), log_level
                )
            end						
        end
    end
end

# Go through the classes, rename them and commit session
function rename_classes(db_url, classes_to_be_renamed, log_level)
	for (old_class_name, new_class_name) in classes_to_be_renamed
		class_item = run_request(db_url, "call_method", ("get_item", "entity_class"), Dict(
			"name" => old_class_name)
		)
		length(class_item) > 0 || continue
		dimension_name_list = collect(class_item["dimension_name_list"])
		new_class_item = run_request(db_url, "call_method", ("get_item", "entity_class"), Dict(
			"name" => new_class_name)
		)
		if length(new_class_item) > 0 && collect(new_class_item["dimension_name_list"]) == dimension_name_list
			# Merge into the already existing (e.g. hand-made) class, migrated data taking precedence
			@log log_level 0 string("Warning: Class $new_class_name already exists. Merging $old_class_name into it; ",
				"migrated values overwrite existing ones in the same alternative.")
			update_ordering_of_multidimensional_classes(db_url, [
				(old_class_name, new_class_name, dimension_name_list, 1:max(length(dimension_name_list), 1), true)
			], log_level)
			continue
		elseif length(new_class_item) > 0
			@log log_level 0 string("Warning: Replacing the existing class $new_class_name with different ",
				"dimensions by $old_class_name.")
			check_run_request_return_value(run_request(
				db_url, "call_method", ("remove_entity_class_item", new_class_item["id"])), log_level
			)
		end
		check_run_request_return_value(run_request(db_url, "call_method", ("update_item", "entity_class"), Dict(
			"id" => class_item["id"], "name" => new_class_name)), log_level
		)
	end
end

# Go through the parameters and move to other classes depending on dimension list
function move_parameters_to_multidimensional_classes(db_url, parameters_to_multidimensional_classes, log_level)
    for (old_par_def, new_par_def) in parameters_to_multidimensional_classes
        move_parameter_to_multidimensional_class(db_url, old_par_def[1], old_par_def[2], new_par_def[1], 
            new_par_def[2], new_par_def[3], log_level
        )
        # Remove old parameter definition
        pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
            "entity_class_name" => old_par_def[1], "name" => old_par_def[2])
        )
        if length(pdef) > 0
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_parameter_definition_item", pdef["id"])), log_level
            )
        end
    end
end

# Find parameter values and move them into another class
function move_parameter_to_multidimensional_class(db_url, old_class_name, old_par_name, new_class_name, 
    new_par_name, mapping, log_level)
    # Add new parameter definition unless it already exists
    new_def = Dict("entity_class_name" => new_class_name, "name" => new_par_name)
    if isempty(run_request(db_url, "call_method", ("get_parameter_definition_item",), new_def))
        try
            check_run_request_return_value(
                run_request(db_url, "call_method", ("add_parameter_definition_item",), new_def),
                log_level
            )
        catch
        end
    end
    # Find old parameters in all entities and alternatives
    pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => old_class_name, "parameter_definition_name" => old_par_name)
    )
    vals = create_dict_from_parameter_value_items(db_url, pvals)
    # Find all entities to get entity descriptions
    entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict(
        "entity_class_name" => old_class_name)
    )
    entities = Dict()
    for entity_item in entity_items
        entities[entity_item["element_name_list"]] = entity_item
    end
    for (old_entity, val_list) in vals
        # Determine element name list
        old_entity_item = entities[old_entity]
        new_element_name_list = [old_entity[i] for i in mapping]
        # Add the entity into the database if it is not there already
        run_request(
            db_url, "call_method", ("add_entity_item",), Dict(
                "entity_class_name" => new_class_name, 
                "entity_byname" => new_element_name_list,
                "description" => old_entity_item["description"])
        )
        for (alternative, val) in val_list
            db_value, db_type = unparse_db_value(val)
            # Add the new parameter value into the database
            check_run_request_return_value(run_request(
                db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                    "entity_class_name" => new_class_name, 
                    "parameter_definition_name" => new_par_name, 
                    "entity_byname" => new_element_name_list, 
                    "alternative_name" => alternative, 
                    "value" => db_value, 
                    "type" => db_type)
                ), log_level
            )
        end
    end
end

# Remove classes and commit session
function remove_classes(db_url, classes_to_be_removed, log_level)
    for class_name in classes_to_be_removed
        try
            entity_class = run_request(db_url, "call_method", ("get_entity_class_item",), Dict(
                "name" => class_name)
            )
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_entity_class_item", entity_class["id"])), log_level
            )
        catch
            @log log_level 0 string("Could not remove class $class_name.")
        end
    end
end

# Remove parameters and commit session
function remove_parameters(db_url, parameters_to_be_removed, log_level)
    for (class_name, parameter_name) in parameters_to_be_removed
        try
            pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
                "entity_class_name" => class_name, "name" => parameter_name)
            )
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_parameter_definition_item", pdef["id"])), log_level
            )
        catch
            @log log_level 0 string("Could not remove parameter $parameter_name from $class_name.")
        end
    end
end

# Rename a parameter value list, or merge it into an already existing (e.g. hand-made) list with the new name
function rename_pval_list(db_url, old_name, new_name, log_level)
    pval_list_item = run_request(db_url, "call_method", ("get_item", "parameter_value_list"), Dict("name" => old_name))
    length(pval_list_item) > 0 || return
    new_pval_list_item = run_request(db_url, "call_method", ("get_item", "parameter_value_list"), Dict(
        "name" => new_name)
    )
    try
        if length(new_pval_list_item) > 0
            merge_pval_list(db_url, old_name, new_name, log_level)
        else
            check_run_request_return_value(run_request(
                db_url, "call_method", ("update_parameter_value_list_item",), Dict(
                    "id" => pval_list_item["id"], "name" => new_name)), log_level
            )
        end
    catch
        @log log_level 0 string("Could not rename list $old_name.")
    end
end

# Merge a parameter value list into another existing one and remove it:
# the values of the old list are appended to the new list (unless there already),
# and the parameter definitions using the old list are switched to the new list, keeping their values.
function merge_pval_list(db_url, old_name, new_name, log_level)
    @log log_level 0 string("Warning: Parameter value list $new_name already exists. Merging $old_name into it.")
    new_list_values = [
        parse_db_value(x["value"], x["type"])
        for x in run_request(db_url, "call_method", ("find_list_values",), Dict("parameter_value_list_name" => new_name))
    ]
    old_list_value_items = run_request(db_url, "call_method", ("find_list_values",), Dict(
        "parameter_value_list_name" => old_name)
    )
    for x in sort(old_list_value_items; by=x -> x["index"])
        val = parse_db_value(x["value"], x["type"])
        val in new_list_values && continue
        list_value, list_value_type = unparse_db_value(val)
        check_run_request_return_value(run_request(
            db_url, "call_method", ("add_list_value_item",), Dict(
                "parameter_value_list_name" => new_name, "value" => list_value, "type" => list_value_type,
                "index" => length(new_list_values))
            ), log_level
        )
        push!(new_list_values, val)
    end
    for pdef in pdefs_using_pval_list(db_url, old_name)
        set_parameter_value_list(db_url, pdef, new_name, log_level)
    end
    old_list = run_request(db_url, "call_method", ("get_item", "parameter_value_list"), Dict("name" => old_name))
    check_run_request_return_value(run_request(
        db_url, "call_method", ("remove_parameter_value_list_item", old_list["id"])), log_level
    )
end

# Rename parameter value list values, each separately. Values not in the mapping are left as they are.
# If the new value is already in the list (e.g. hand-made), the parameter values referring to the old value are
# moved to the existing one and the old value is removed.
function rename_pval_list_values(db_url, list_name, name_mapping, log_level)
    list_value_items = run_request(db_url, "call_method", ("find_list_values",), Dict(
        "parameter_value_list_name" => list_name)
    )
    # NOTE: An item's value can only be parsed once
    parsed_list_values = [parse_db_value(x["value"], x["type"]) for x in list_value_items]
    existing_values = Set(parsed_list_values)
    for (list_value_item, old_name) in zip(list_value_items, parsed_list_values)
        haskey(name_mapping, old_name) || continue
        new_name = name_mapping[old_name]
        try
            if new_name in existing_values
                @log log_level 0 string("Warning: `$new_name` already exists in the parameter value list ",
                    "$list_name. Merging `$old_name` into it.")
                replace_list_value_in_parameter_values(db_url, list_name, list_value_item["id"], new_name, log_level)
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("remove_list_value_item", list_value_item["id"])), log_level
                )
            else
                new_name_value, new_name_type = unparse_db_value(new_name)
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("update_list_value_item",), Dict(
                        "id" => list_value_item["id"], "value" => new_name_value, "type" => new_name_type)
                    ), log_level
                )
                push!(existing_values, new_name)
            end
        catch
            @log log_level 0 string("Could not rename value `$old_name` of list $list_name.")
        end
    end
end

# Make the parameter values that refer to the given list value refer to `new_value` (of the same list) instead
function replace_list_value_in_parameter_values(db_url, list_name, list_value_id, new_value, log_level)
    new_pval_value, new_pval_type = unparse_db_value(new_value)
    for pdef in pdefs_using_pval_list(db_url, list_name)
        pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
            "entity_class_name" => pdef["entity_class_name"], "parameter_definition_name" => pdef["name"])
        )
        for pval in pvals
            pval["list_value_id"] == list_value_id || continue
            check_run_request_return_value(run_request(
                db_url, "call_method", ("update_parameter_value_item",), Dict(
                    "id" => pval["id"], "value" => new_pval_value, "type" => new_pval_type)
                ), log_level
            )
        end
    end
end

# The parameter definitions that use the given parameter value list
function pdefs_using_pval_list(db_url, list_name)
    pdefs = run_request(db_url, "call_method", ("find_parameter_definitions",), Dict())
    [pdef for pdef in pdefs if pdef["parameter_value_list_name"] == list_name]
end

# Rename lists and commit session
function rename_parameter_value_lists(db_url, lists_to_be_renamed, log_level)
    for (old_list_name, new_list_name) in lists_to_be_renamed
        rename_pval_list(db_url, old_list_name, new_list_name, log_level)
    end
end

# Rename list values and commit session
function rename_list_values(db_url, list_values_to_be_renamed, log_level)
    for (list_name, name_mapping) in list_values_to_be_renamed
        rename_pval_list_values(db_url, list_name, name_mapping, log_level)
    end
end

function merge_variable_type_lists(db_url, log_level)
    pval_list_old_name = "unit_online_variable_type_list"
    pval_list_new_name = "variable_type_list"
    name_mapping = Dict(
        "unit_online_variable_type_binary" => "binary",
        "unit_online_variable_type_integer" => "integer",
        "unit_online_variable_type_linear" => "linear",
        "unit_online_variable_type_none" => "none"
    )
    # Rename the values and the list itself.
    # An already existing (e.g. hand-made) `variable_type_list` is merged with the old list.
    rename_pval_list_values(db_url, pval_list_old_name, name_mapping, log_level)
    rename_pval_list(db_url, pval_list_old_name, pval_list_new_name, log_level)
    lists_to_be_updated = (
        ("connection", "investment_count_max_cumulative", "variable_type_list", 
            "investment_variable_type", "investment_variable_type2", "connection_investment_variable_type_list"),
        ("node", "storage_investment_count_max_cumulative", "variable_type_list", 
            "storage_investment_variable_type", "investment_variable_type2", "storage_investment_variable_type_list"),
        ("unit", "investment_count_max_cumulative", "variable_type_list", 
            "investment_variable_type", "investment_variable_type2", "unit_investment_variable_type_list")
    )
    old_default_mapping = Dict(
        "connection" => "integer",
        "node" => "integer",
        "unit" => "linear",
    )
    for (class_name, max_cum_par_name, type_list, old_par_name, temp_par_name, list_old) in lists_to_be_updated
        # Add new parameter for investment variable type, connect to value list
        try
            check_run_request_return_value(run_request(db_url, "call_method", ("add_parameter_definition_item",), Dict(
                "entity_class_name" => class_name, "name" => temp_par_name, 
                "parameter_value_list_name" => type_list)), log_level
            )
        catch
        end
        # Get investment_count_max_cumulative and old investment_variable_type parameter values
        pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
            "entity_class_name" => class_name, "parameter_definition_name" => max_cum_par_name)
        )
        vals_max = create_dict_from_parameter_value_items(db_url, pvals)
        pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
            "entity_class_name" => class_name, "parameter_definition_name" => old_par_name)
        )
        vals_type = create_dict_from_parameter_value_items(db_url, pvals)
        # Old default: if there is investment_count_max_cumulative, new investment variable is the old default
        # (or none if investment_count_max_cumulative set to none)
        for (entity, val_list) in vals_max
            for (alternative, val) in val_list
                if isnothing(val)
                    pval = "none"
                else
                    pval = old_default_mapping[class_name]
                end
                pval_value, pval_type = unparse_db_value(pval)
                # Add the new parameter value into the database
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                        "entity_class_name" => class_name, "parameter_definition_name" => temp_par_name, 
                        "entity_byname" => entity, 
                        "alternative_name" => alternative, 	
                        "value" => pval_value, "type" => pval_type)
                    ), log_level
                )
            end
        end
        # If investment_variable_type is specified, it overrides the old default
        for (entity, val_list) in vals_type
            for (alternative, val) in val_list
                if occursin("integer", val)
                    pval = "integer"
                else
                    pval = "linear"
                end
                pval_value, pval_type = unparse_db_value(pval)
                # Add the new parameter value into the database
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                        "entity_class_name" => class_name, "parameter_definition_name" => temp_par_name, 
                        "entity_byname" => entity, 
                        "alternative_name" => alternative, 	
                        "value" => pval_value, "type" => pval_type)
                    ), log_level
                )
            end
        end
        # Merged alternatives are created for those investment_variable_types that don't have 
        # investment_count_max_cumulative directly associated to them
        pvals_existing = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
            "entity_class_name" => class_name, "parameter_definition_name" => max_cum_par_name)
        )
        existing_values = create_dict_from_parameter_value_items(db_url, pvals_existing)
        existing_types = Dict()
        for (entity, val_list) in vals_type
            for (alternative, val) in val_list
                existing_types[(entity, alternative)] = val
            end
        end
        existing_values2 = Dict()
        for (entity, val_list) in existing_values
            for (alternative, val) in val_list
                existing_values2[(entity, alternative)] = val
            end
        end
        for (entity, val_list) in vals_type
            for (alternative, val) in val_list
                # Find if entity in existing_values
                if !haskey(existing_values2, (entity, alternative))
                    # Loop over alternatives in existing_values[entity]
                    # (the entity may have no investment_count_max_cumulative value at all, e.g. a non-candidate)
                    for existing_value in get(existing_values, entity, ())
                        if !haskey(existing_types, (entity, existing_value[1]))
                            alternative_updated, base_alternative_added = add_merged_alternative(
                                db_url, alternative, existing_value[1], log_level
                            )
                            if occursin("integer", val)
                                pval = "integer"
                            else
                                pval = "linear"
                            end
                            pval_value, pval_type = unparse_db_value(pval)
                            # Add the new parameter value into the database
                            check_run_request_return_value(run_request(
                                db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                                    "entity_class_name" => class_name, "parameter_definition_name" => temp_par_name, 
                                    "entity_byname" => entity, 
                                    "alternative_name" => alternative_updated, 	
                                    "value" => pval_value, "type" => pval_type)
                                ), log_level
                            )
                        end
                    end
                end			
            end
        end
        # Remove old parameter definition and list
        pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
            "entity_class_name" => class_name, "name" => old_par_name)
        )
        if length(pdef) > 0
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_parameter_definition_item", pdef["id"])), log_level
            )
        end
        # Remove old parameter definition
        pval_list = run_request(db_url, "call_method", ("get_parameter_value_list_item",), Dict("name" => list_old))
        if length(pval_list) > 0
            check_run_request_return_value(run_request(
                db_url, "call_method", ("remove_parameter_value_list_item", pval_list["id"])), log_level
            )
        end
        # Rename the parameter
        pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
            "entity_class_name" => class_name, "name" => temp_par_name)
        )
        if length(pdef) > 0
            check_run_request_return_value(run_request(
                db_url, "call_method", ("update_parameter_definition_item",), Dict(
                    "id" => pdef["id"], "name" => old_par_name)), log_level
            )
        end
    end
end

function move_parameters(db_url, log_level)
    node_parameters_to_be_moved = [
        ("has_voltage_angle", "voltage_angle_physics", 3),
        ("has_pressure", "pressure_physics", 4)
    ]
    for (old_par_name, new_list_value, idx) in node_parameters_to_be_moved
        move_parameter(db_url, log_level, old_par_name, new_list_value, idx)
    end
end

function move_parameter(db_url, log_level, old_par_name, new_list_value, idx)
    pval_value, pval_type = unparse_db_value(new_list_value)
    try
        check_run_request_return_value(run_request(
            db_url, "call_method", ("add_update_list_value_item",), Dict(
                "parameter_value_list_name" => "grid_physics_list", 
                "value" => pval_value, "type" => pval_type,
                "index" => idx)
            ), log_level
        )
    catch
    end
    # Find old parameters in all entities and alternatives
    pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => "node", "parameter_definition_name" => old_par_name)
    )
    vals = create_dict_from_parameter_value_items(db_url, pvals)
    for (entity, val_list) in vals
        try
            # Add the grid and grid__node entities into the database unless they exist already
            add_entity_if_missing(db_url, "grid", entity, log_level)
            add_entity_if_missing(db_url, "node__grid", [entity..., entity...], log_level)
            for (alternative, val) in val_list
                # Add the new parameter value into the database
                if val
                    pval_value, pval_type = unparse_db_value(new_list_value)
                else
                    pval_value, pval_type = unparse_db_value("none")
                end
                check_run_request_return_value(run_request(
                    db_url, "call_method", ("add_update_parameter_value_item",), Dict(
                        "entity_class_name" => "grid", "parameter_definition_name" => "physics_type", 
                        "entity_byname" => entity, 
                        "alternative_name" => alternative, 	
                        "value" => pval_value, "type" => pval_type)
                    ), log_level
                )
            end
        catch
        end
    end
    # Remove old parameter definition
    pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
        "entity_class_name" => "node", "name" => old_par_name)
    )
    if length(pdef) > 0
        check_run_request_return_value(run_request(
            db_url, "call_method", ("remove_parameter_definition_item", pdef["id"])), log_level
        )
    end
end
