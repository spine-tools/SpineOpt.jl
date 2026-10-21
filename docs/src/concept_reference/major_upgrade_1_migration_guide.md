# SpineOpt `major_upgrade_1` migration reference

## Scope and interpretation

This document records the migrations declared and performed by `major_upgrade_1` in the supplied Julia script. It distinguishes **simple renaming** (same class/dimensions, parameter or class/list name changes) from **restructuring** (dimension reordering, moving parameters to new classes, superclass creation, and changes to value-list semantics). It is based on the script, not on a comparison of a particular database before and after migration.

Migration order matters: the script creates superclasses/subclasses, reorders classes, scales selected values, renames parameters/classes, moves multidimensional parameters, removes obsolete classes/parameters, renames lists and list values, merges variable-type lists, moves node physics settings to grid physics, then checks values against the latest template lists.

## 1. Simple renaming

### 1.1 Parameter renames

Unless noted, each mapping renames a parameter definition and its values in the same entity class. If the target parameter already exists, the script merges the old definition into it; migrated attributes and values take precedence, while other existing values are retained. Values in the same alternative are overwritten by migrated values.

#### Class `unit`

| Old parameter | New parameter | Notes |
|---|---|---|
| `number_of_units` | `existing_units` |  |
| `fix_units_out_of_service` | `out_of_service_count_fix` |  |
| `initial_units_out_of_service` | `out_of_service_count_initial` |  |
| `scheduled_outage_duration` | `outage_scheduled_duration` |  |
| `unit_availability_factor` | `availability_factor` |  |
| `units_unavailable` | `out_of_service_count_fix` | Values are summed into the target parameter, then the old parameter is removed. |
| `fix_units_on` | `online_count_fix` |  |
| `initial_units_on` | `online_count_initial` |  |
| `unit_decommissioning_time` | `decommissioning_time` |  |
| `unit_discount_rate_technology_specific` | `discount_rate_technology_specific` |  |
| `unit_investment_econ_lifetime` | `lifetime_economic` |  |
| `unit_investment_tech_lifetime` | `lifetime_technical` |  |
| `unit_investment_lifetime_sense` | `lifetime_constraint_sense` |  |
| `unit_investment_variable_type` | `investment_variable_type` |  |
| `unit_lead_time` | `lead_time` |  |
| `candidate_units` | `investment_count_max_cumulative` |  |
| `fix_units_invested` | `investment_count_fix_new` |  |
| `fix_units_invested_available` | `investment_count_fix_cumulative` |  |
| `initial_units_invested` | `investment_count_initial_new` |  |
| `initial_units_invested_available` | `investment_count_initial_cumulative` |  |
| `units_invested_big_m_mga` | `mga_investment_big_m` |  |
| `units_invested_mga` | `mga_investment_active` |  |
| `units_invested_mga_weight` | `mga_investment_weight` |  |

#### Class `node`

| Old parameter | New parameter | Notes |
|---|---|---|
| `has_state` | `storage_active` |  |
| `fractional_demand` | `demand_fraction` |  |
| `min_capacity_margin` | `capacity_margin_min` |  |
| `min_capacity_margin_penalty` | `capacity_margin_penalty` |  |
| `nodal_balance_sense` | `balance_sense` |  |
| `node_slack_penalty` | `balance_penalty` |  |
| `frac_state_loss` | `storage_self_discharge` |  |
| `number_of_storages` | `existing_storages` |  |
| `state_coeff` | `storage_state_coefficient` |  |
| `storage_fom_cost` | `storage_fixed_annual_cost` |  |
| `is_longterm_storage` | `storage_longterm_active` |  |
| `fix_node_state` | `storage_state_fix` |  |
| `initial_node_state` | `storage_state_initial` |  |
| `node_state_cap` | `storage_state_max` |  |
| `node_state_min` | `storage_state_min` |  |
| `node_availability_factor` | `storage_state_max_fraction` |  |
| `node_state_min_factor` | `storage_state_min_fraction` |  |
| `fix_node_pressure` | `pressure_fix` |  |
| `initial_node_pressure` | `pressure_initial` |  |
| `max_node_pressure` | `pressure_max` |  |
| `min_node_pressure` | `pressure_min` |  |
| `fix_node_voltage_angle` | `voltage_angle_fix` |  |
| `initial_node_voltage_angle` | `voltage_angle_initial` |  |
| `max_voltage_angle` | `voltage_angle_max` |  |
| `min_voltage_angle` | `voltage_angle_min` |  |
| `storage_investment_econ_lifetime` | `storage_lifetime_economic` |  |
| `storage_investment_tech_lifetime` | `storage_lifetime_technical` |  |
| `storage_investment_lifetime_sense` | `storage_lifetime_constraint_sense` |  |
| `candidate_storages` | `storage_investment_count_max_cumulative` |  |
| `fix_storages_invested` | `storage_investment_count_fix_new` |  |
| `fix_storages_invested_available` | `storage_investment_count_fix_cumulative` |  |
| `initial_storages_invested` | `storage_investment_count_initial_new` |  |
| `initial_storages_invested_available` | `storage_investment_count_initial_cumulative` |  |
| `storages_invested_big_m_mga` | `mga_storage_investment_big_m` |  |
| `storages_invested_mga` | `mga_storage_investment_active` |  |
| `storages_invested_mga_weight` | `mga_storage_investment_weight` |  |
| `downward_reserve` | `reserve_downward` |  |
| `upward_reserve` | `reserve_upward` |  |
| `is_reserve_node` | `reserve_active` |  |

#### Class `connection`

| Old parameter | New parameter | Notes |
|---|---|---|
| `connection_availability_factor` | `availability_factor` |  |
| `connection_contingency` | `contingency_active` |  |
| `connection_monitored` | `monitoring_active` |  |
| `connection_reactance` | `reactance` |  |
| `connection_reactance_base` | `reactance_base` |  |
| `connection_resistance` | `resistance` |  |
| `number_of_connections` | `existing_connections` |  |
| `has_binary_gas_flow` | `binary_gas_flow_active` |  |
| `connection_decommissioning_cost` | `decommissioning_cost` |  |
| `connection_decommissioning_time` | `decommissioning_time` |  |
| `connection_discount_rate_technology_specific` | `discount_rate_technology_specific` |  |
| `connection_investment_econ_lifetime` | `lifetime_economic` |  |
| `connection_investment_lifetime_sense` | `lifetime_constraint_sense` |  |
| `connection_investment_tech_lifetime` | `lifetime_technical` |  |
| `connection_investment_variable_type` | `investment_variable_type` |  |
| `connection_lead_time` | `lead_time` |  |
| `candidate_connections` | `investment_count_max_cumulative` |  |
| `fix_connections_invested` | `investment_count_fix_new` |  |
| `fix_connections_invested_available` | `investment_count_fix_cumulative` |  |
| `initial_connections_invested` | `investment_count_initial_new` |  |
| `initial_connections_invested_available` | `investment_count_initial_cumulative` |  |
| `connections_invested_big_m_mga` | `mga_investment_big_m` |  |
| `connections_invested_mga` | `mga_investment_active` |  |
| `connections_invested_mga_weight` | `mga_investment_weight` |  |

#### Class `commodity`

| Old parameter | New parameter | Notes |
|---|---|---|
| `commodity_lodf_tolerance` | `lodf_tolerance` |  |
| `commodity_physics` | `physics_type` |  |
| `commodity_physics_duration` | `physics_duration` |  |
| `commodity_ptdf_threshold` | `ptdf_threshold` |  |

#### Class `investment_group`

| Old parameter | New parameter | Notes |
|---|---|---|
| `equal_investments` | `equal_investments_active` |  |
| `maximum_capacity_invested_available` | `investment_capacity_total_max_cumulative` |  |
| `maximum_entities_invested_available` | `investment_count_total_max_cumulative` |  |
| `minimum_capacity_invested_available` | `investment_capacity_total_min_cumulative` |  |
| `minimum_entities_invested_available` | `investment_count_total_min_cumulative` |  |

#### Class `model`

| Old parameter | New parameter | Notes |
|---|---|---|
| `db_lp_solver` | `solver_lp` |  |
| `db_lp_solver_options` | `solver_lp_options` |  |
| `db_mip_solver` | `solver_mip` |  |
| `db_mip_solver_options` | `solver_mip_options` |  |
| `max_gap` | `decomposition_max_gap` |  |
| `max_iterations` | `decomposition_max_iterations` |  |
| `max_mga_iterations` | `mga_max_iterations` |  |
| `max_mga_slack` | `mga_max_slack` |  |
| `min_iterations` | `decomposition_min_iterations` |  |
| `report_benders_iterations` | `benders_iterations_reporting_active` |  |
| `use_connection_intact_flow` | `connection_investment_power_flow_impact_active` |  |
| `use_highest_resolution_constraint_ratio_out_in_connection_flow` | `connection_flow_highest_resolution_active` |  |
| `use_tight_compact_formulations` | `tight_compact_formulations_active` |  |

#### Class `node__node`

| Old parameter | New parameter | Notes |
|---|---|---|
| `diff_coeff` | `diffusion_coefficient` |  |

#### Class `node__user_constraint`

| Old parameter | New parameter | Notes |
|---|---|---|
| `demand_coefficient` | `coefficient_for_demand` |  |
| `node_state_coefficient` | `coefficient_for_node_state` |  |
| `storages_invested_available_coefficient` | `coefficient_for_storages_invested_available` |  |
| `storages_invested_coefficient` | `coefficient_for_storages_invested` |  |

#### Class `unit__to_node`

| Old parameter | New parameter | Notes |
|---|---|---|
| `fix_unit_flow` | `flow_limits_fix` |  |
| `fix_unit_flow_op` | `flow_limits_fix_op` |  |
| `initial_unit_flow` | `flow_limits_initial` |  |
| `initial_unit_flow_op` | `flow_limits_initial_op` |  |
| `min_unit_flow` | `flow_limits_min` |  |
| `ramp_down_limit` | `ramp_limits_down` |  |
| `ramp_up_limit` | `ramp_limits_up` |  |
| `shut_down_limit` | `ramp_limits_shutdown` |  |
| `start_up_limit` | `ramp_limits_startup` |  |
| `unit_capacity` | `capacity_per_unit` |  |
| `unit_conv_cap_to_flow` | `capacity_to_flow_conversion_factor` |  |

#### Class `node__to_unit`

| Old parameter | New parameter | Notes |
|---|---|---|
| `fix_unit_flow` | `flow_limits_fix` |  |
| `fix_unit_flow_op` | `flow_limits_fix_op` |  |
| `initial_unit_flow` | `flow_limits_initial` |  |
| `initial_unit_flow_op` | `flow_limits_initial_op` |  |
| `max_total_cumulated_unit_flow_from_node` | `flow_limits_max_cumulative` |  |
| `min_total_cumulated_unit_flow_from_node` | `flow_limits_min_cumulative` |  |
| `min_unit_flow` | `flow_limits_min` |  |
| `ramp_down_limit` | `ramp_limits_down` |  |
| `ramp_up_limit` | `ramp_limits_up` |  |
| `shut_down_limit` | `ramp_limits_shutdown` |  |
| `start_up_limit` | `ramp_limits_startup` |  |
| `unit_capacity` | `capacity_per_unit` |  |
| `unit_conv_cap_to_flow` | `capacity_to_flow_conversion_factor` |  |

#### Class `unit__user_constraint`

| Old parameter | New parameter | Notes |
|---|---|---|
| `units_invested_available_coefficient` | `coefficient_for_units_invested_available` |  |
| `units_invested_coefficient` | `coefficient_for_units_invested` |  |
| `units_on_coefficient` | `coefficient_for_units_on` |  |
| `units_started_up_coefficient` | `coefficient_for_units_started_up` |  |

#### Class `unit_flow__user_constraint`

| Old parameter | New parameter | Notes |
|---|---|---|
| `unit_flow_coefficient` | `coefficient_for_unit_flow` |  |

#### Class `connection__from_node`

| Old parameter | New parameter | Notes |
|---|---|---|
| `fix_binary_gas_connection_flow` | `binary_gas_flow_limits_fix` |  |
| `initial_binary_gas_connection_flow` | `binary_gas_flow_limits_initial` |  |
| `fix_connection_flow` | `flow_limits_fix` |  |
| `fix_connection_intact_flow` | `flow_limits_fix_intact` |  |
| `initial_connection_flow` | `flow_limits_initial` |  |
| `initial_connection_intact_flow` | `flow_limits_initial_intact` |  |
| `connection_capacity` | `capacity_per_connection` |  |
| `connection_conv_cap_to_flow` | `capacity_to_flow_conversion_factor` |  |

#### Class `connection__to_node`

| Old parameter | New parameter | Notes |
|---|---|---|
| `fix_binary_gas_connection_flow` | `binary_gas_flow_limits_fix` |  |
| `initial_binary_gas_connection_flow` | `binary_gas_flow_limits_initial` |  |
| `fix_connection_flow` | `flow_limits_fix` |  |
| `fix_connection_intact_flow` | `flow_limits_fix_intact` |  |
| `initial_connection_flow` | `flow_limits_initial` |  |
| `initial_connection_intact_flow` | `flow_limits_initial_intact` |  |
| `connection_capacity` | `capacity_per_connection` |  |
| `connection_conv_cap_to_flow` | `capacity_to_flow_conversion_factor` |  |

#### Class `connection__from_node__user_constraint`

| Old parameter | New parameter | Notes |
|---|---|---|
| `connection_flow_coefficient` | `coefficient_for_connection_flow` |  |

#### Class `connection__to_node__user_constraint`

| Old parameter | New parameter | Notes |
|---|---|---|
| `connection_flow_coefficient` | `coefficient_for_connection_flow` |  |

#### Class `connection__user_constraint`

| Old parameter | New parameter | Notes |
|---|---|---|
| `connections_invested_available_coefficient` | `coefficient_for_connections_invested_available` |  |
| `connections_invested_coefficient` | `coefficient_for_connections_invested` |  |

#### Class `temporal_block`

| Old parameter | New parameter | Notes |
|---|---|---|
| `representative_period_index` | `representative_block_index` |  |
| `representative_periods_mapping` | `representative_blocks_by_period` |  |

### 1.2 Class rename

| Old class | New class | Behaviour |
|---|---|---|
| `commodity` | `grid` | Renames the class. If `grid` already exists with matching dimensions, the classes are merged and migrated values take precedence; if dimensions differ, the existing target class is replaced. |

### 1.3 Parameter value-list renames

| Old list | New list |
|---|---|
| `commodity_physics_list` | `grid_physics_list` |
| `db_lp_solver_list` | `solver_lp_list` |
| `db_mip_solver_list` | `solver_mip_list` |

### 1.4 Value renames inside lists

**`grid_physics_list`** (after `commodity_physics_list` is renamed):

| Old value | New value |
|---|---|
| `commodity_physics_lodf` | `lodf_physics` |
| `commodity_physics_none` | `none` |
| `commodity_physics_ptdf` | `ptdf_physics` |

**`balance_type_list`:**

| Old value | New value |
|---|---|
| `balance_type_none` | `none` |
| `balance_type_node` | `node_balance` |
| `balance_type_group` | `group_balance` |

**Variable-type list migration:** `unit_online_variable_type_list` becomes `variable_type_list`, with values renamed as follows:

| Old value | New value |
|---|---|
| `unit_online_variable_type_binary` | `binary` |
| `unit_online_variable_type_integer` | `integer` |
| `unit_online_variable_type_linear` | `linear` |
| `unit_online_variable_type_none` | `none` |

That list migration also consolidates investment-variable type handling for `unit`, `connection`, and `node` storage investments; see [Variable-type restructuring](#25-variable-type-restructuring).

## 2. Restructuring

### 2.1 Superclasses and subclasses

The migration ensures `user_constraint` and `investment_group` classes exist (creating empty classes if missing), then ensures the following classes exist:

| Class | Dimensions | Purpose in migration |
|---|---|---|
| `unit__to_node` | `unit, node` | Flow-direction subclass |
| `node__to_unit` | `node, unit` | Flow-direction subclass |
| `unit_flow` | none (0-D superclass) | Shared superclass for unit-flow relations |
| `unit_flow__unit_flow` | `unit_flow, unit_flow` | Relations between two unit flows |
| `unit_flow__investment_group` | `unit_flow, investment_group` | Unit-flow/investment-group relation |
| `unit_flow__user_constraint` | `unit_flow, user_constraint` | Unit-flow/user-constraint relation |

Both `unit__to_node` and `node__to_unit` are made subclasses of `unit_flow`.

### 2.2 Multidimensional class dimension reordering / migration

The script creates destination classes, copies parameter definitions and values, and also copies entity alternatives and group memberships. The dimension mappings below specify the source dimension order used to construct the destination entity names.

| Source class | Destination class | Destination dimensions | Dimension mapping |
|---|---|---|---|
| `unit__from_node` | `node__to_unit` | `node, unit` | `[2, 1]` |
| `unit__to_node_` | `unit__to_node` | `unit, node` | `[1, 2]` |
| `unit__from_node__investment_group` | `unit_flow__investment_group` | `node, unit, investment_group` | `[2, 1, 3]` |
| `unit__from_node__user_constraint` | `unit_flow__user_constraint` | `node, unit, user_constraint` | `[2, 1, 3]` |
| `unit__to_node__investment_group` | `unit_flow__investment_group` | `unit, node, investment_group` | `[1, 2, 3]` |
| `unit__to_node__user_constraint` | `unit_flow__user_constraint` | `unit, node, user_constraint` | `[1, 2, 3]` |

Notes:
- `unit__from_node` is converted to `node__to_unit` by swapping dimensions.
- `unit__to_node_` is converted to `unit__to_node`; the trailing underscore is an intentional staging step so `unit__to_node` can be recreated as a subclass of `unit_flow`.
- `unit__from_node__investment_group` and `unit__from_node__user_constraint` are converted to their `unit_flow__...` classes with the unit/node dimensions reordered.
- The `unit__to_node__investment_group` and `unit__to_node__user_constraint` classes are also migrated to the same destination classes. These source classes do not print errors for missing parameter definitions during this operation (`print_errors=false`).
- Where a destination entity or parameter definition already exists, the migration generally preserves it but lets migrated definitions/values take precedence.

### 2.3 Parameters moved from `unit__node__node` to `unit_flow__unit_flow`

The old `unit__node__node` class models two node dimensions associated with a unit. The migration maps its parameter values into `unit_flow__unit_flow`, whose dimensions are two unit-flow entities. The old parameter definitions are removed after each move, and the old class is removed later.

#### Flow-ratio limits

| Old parameter | New parameter | Dimension mapping |
|---|---|---|
| `fix_ratio_out_in_unit_flow` | `flow_ratio_equality_coefficient` | `[1, 2, 3, 1]` |
| `fix_ratio_in_out_unit_flow` | `flow_ratio_equality_coefficient` | `[2, 1, 1, 3]` |
| `fix_ratio_in_in_unit_flow` | `flow_ratio_equality_coefficient` | `[2, 1, 3, 1]` |
| `fix_ratio_out_out_unit_flow` | `flow_ratio_equality_coefficient` | `[1, 2, 1, 3]` |
| `min_ratio_out_in_unit_flow` | `flow_ratio_greater_than_coefficient` | `[1, 2, 3, 1]` |
| `min_ratio_in_out_unit_flow` | `flow_ratio_greater_than_coefficient` | `[2, 1, 1, 3]` |
| `min_ratio_in_in_unit_flow` | `flow_ratio_greater_than_coefficient` | `[2, 1, 3, 1]` |
| `min_ratio_out_out_unit_flow` | `flow_ratio_greater_than_coefficient` | `[1, 2, 1, 3]` |
| `max_ratio_out_in_unit_flow` | `flow_ratio_less_than_coefficient` | `[1, 2, 3, 1]` |
| `max_ratio_in_out_unit_flow` | `flow_ratio_less_than_coefficient` | `[2, 1, 1, 3]` |
| `max_ratio_in_in_unit_flow` | `flow_ratio_less_than_coefficient` | `[2, 1, 3, 1]` |
| `max_ratio_out_out_unit_flow` | `flow_ratio_less_than_coefficient` | `[1, 2, 1, 3]` |

The four direction suffixes (`out_in`, `in_out`, `in_in`, `out_out`) map to dimension patterns `[1, 2, 3, 1]`, `[2, 1, 1, 3]`, `[2, 1, 3, 1]`, and `[1, 2, 1, 3]`, respectively. For each direction pattern:

- `fix_ratio_*` becomes `flow_ratio_equality_coefficient`.
- `min_ratio_*` becomes `flow_ratio_greater_than_coefficient`.
- `max_ratio_*` becomes `flow_ratio_less_than_coefficient`.

#### Unit-online coefficient limits

| Old parameter | New parameter | Dimension mapping |
|---|---|---|
| `fix_units_on_coefficient_out_in` | `flow_ratio_equality_online_coefficient` | `[1, 2, 3, 1]` |
| `fix_units_on_coefficient_in_out` | `flow_ratio_equality_online_coefficient` | `[2, 1, 1, 3]` |
| `fix_units_on_coefficient_in_in` | `flow_ratio_equality_online_coefficient` | `[2, 1, 3, 1]` |
| `fix_units_on_coefficient_out_out` | `flow_ratio_equality_online_coefficient` | `[1, 2, 1, 3]` |
| `min_units_on_coefficient_out_in` | `flow_ratio_greater_than_online_coefficient` | `[1, 2, 3, 1]` |
| `min_units_on_coefficient_in_out` | `flow_ratio_greater_than_online_coefficient` | `[2, 1, 1, 3]` |
| `min_units_on_coefficient_in_in` | `flow_ratio_greater_than_online_coefficient` | `[2, 1, 3, 1]` |
| `min_units_on_coefficient_out_out` | `flow_ratio_greater_than_online_coefficient` | `[1, 2, 1, 3]` |
| `max_units_on_coefficient_out_in` | `flow_ratio_less_than_online_coefficient` | `[1, 2, 3, 1]` |
| `max_units_on_coefficient_in_out` | `flow_ratio_less_than_online_coefficient` | `[2, 1, 1, 3]` |
| `max_units_on_coefficient_in_in` | `flow_ratio_less_than_online_coefficient` | `[2, 1, 3, 1]` |
| `max_units_on_coefficient_out_out` | `flow_ratio_less_than_online_coefficient` | `[1, 2, 1, 3]` |

The same four direction patterns apply. `fix_units_on_coefficient_*`, `min_units_on_coefficient_*`, and `max_units_on_coefficient_*` become, respectively, `flow_ratio_equality_online_coefficient`, `flow_ratio_greater_than_online_coefficient`, and `flow_ratio_less_than_online_coefficient`.

#### Startup flow

| Old parameter | New parameter | Dimension mapping |
|---|---|---|
| `unit_start_flow` | `flow_ratio_start_flow` | `[2, 1, 1, 3]` (only this input-output mapping is active) |

The script contains three additional `unit_start_flow` mappings in a commented-out block; they are not executed. The comment says enabling the full migration could result in duplicate values.

### 2.4 Flow parameter renames on flow-direction classes

These parameter renames apply to both `unit__to_node` and `node__to_unit`, unless noted.

| Old parameter | New parameter |
|---|---|
| `fix_unit_flow` | `flow_limits_fix` |
| `fix_unit_flow_op` | `flow_limits_fix_op` |
| `initial_unit_flow` | `flow_limits_initial` |
| `initial_unit_flow_op` | `flow_limits_initial_op` |
| `min_unit_flow` | `flow_limits_min` |
| `ramp_down_limit` | `ramp_limits_down` |
| `ramp_up_limit` | `ramp_limits_up` |
| `shut_down_limit` | `ramp_limits_shutdown` |
| `start_up_limit` | `ramp_limits_startup` |
| `unit_capacity` | `capacity_per_unit` |
| `unit_conv_cap_to_flow` | `capacity_to_flow_conversion_factor` |
| `max_total_cumulated_unit_flow_from_node` | `flow_limits_max_cumulative` |
| `min_total_cumulated_unit_flow_from_node` | `flow_limits_min_cumulative` |

### 2.5 Variable-type restructuring

The old `unit_online_variable_type_list` is renamed to `variable_type_list`, with its values normalised to `binary`, `integer`, `linear`, and `none`. The script then creates/uses `investment_variable_type2` as an intermediate parameter linked to `variable_type_list` for:

- `unit.investment_count_max_cumulative` / `unit.investment_variable_type`
- `connection.investment_count_max_cumulative` / `connection.investment_variable_type`
- `node.storage_investment_count_max_cumulative` / `node.storage_investment_variable_type`

If a cumulative investment-count value is `nothing`, the new type is `none`; otherwise the class-specific legacy default is used (`unit`: `linear`; `connection` and `node` storage: `integer`). An explicitly set old investment-variable type overrides that default: values containing `integer` become `integer`, otherwise they become `linear`. The script also merges legacy variable-type lists into the shared list and updates investment parameter definitions. The detailed list names and temporary definitions are implementation details in the script; the final shared list is `variable_type_list`.

### 2.6 Move node physics flags into grid physics

The script migrates boolean node parameters into values of `grid_physics_list`, creating corresponding `grid` and `node__grid` entities as needed:

| Old class/parameter | New destination | Mapping |
|---|---|---|
| `node.has_voltage_angle` | `grid_physics_list` value `voltage_angle_physics` | `true` → `voltage_angle_physics`; `false` → `none` |
| `node.has_pressure` | `grid_physics_list` value `pressure_physics` | `true` → `pressure_physics`; `false` → `none` |

The new list values are inserted at indices 3 and 4, respectively. This is a semantic move, not merely a parameter rename.

### 2.7 Connection-flow parameters and user constraints

Parameters on both `connection__from_node` and `connection__to_node` are renamed in place as follows:

| Old parameter | New parameter |
|---|---|
| `fix_binary_gas_connection_flow` | `binary_gas_flow_limits_fix` |
| `initial_binary_gas_connection_flow` | `binary_gas_flow_limits_initial` |
| `fix_connection_flow` | `flow_limits_fix` |
| `fix_connection_intact_flow` | `flow_limits_fix_intact` |
| `initial_connection_flow` | `flow_limits_initial` |
| `initial_connection_intact_flow` | `flow_limits_initial_intact` |
| `connection_capacity` | `capacity_per_connection` |
| `connection_conv_cap_to_flow` | `capacity_to_flow_conversion_factor` |

On `connection__from_node__user_constraint` and `connection__to_node__user_constraint`, `connection_flow_coefficient` becomes `coefficient_for_connection_flow`.

### 2.8 Additional parameter renames on multidimensional classes

| Class | Old parameter | New parameter |
|---|---|---|
| `node__node` | `diff_coeff` | `diffusion_coefficient` |
| `node__user_constraint` | `demand_coefficient` | `coefficient_for_demand` |
| `node__user_constraint` | `node_state_coefficient` | `coefficient_for_node_state` |
| `node__user_constraint` | `storages_invested_available_coefficient` | `coefficient_for_storages_invested_available` |
| `node__user_constraint` | `storages_invested_coefficient` | `coefficient_for_storages_invested` |
| `unit__user_constraint` | `units_invested_available_coefficient` | `coefficient_for_units_invested_available` |
| `unit__user_constraint` | `units_invested_coefficient` | `coefficient_for_units_invested` |
| `unit__user_constraint` | `units_on_coefficient` | `coefficient_for_units_on` |
| `unit__user_constraint` | `units_started_up_coefficient` | `coefficient_for_units_started_up` |
| `unit_flow__user_constraint` | `unit_flow_coefficient` | `coefficient_for_unit_flow` |
| `connection__user_constraint` | `connections_invested_available_coefficient` | `coefficient_for_connections_invested_available` |
| `connection__user_constraint` | `connections_invested_coefficient` | `coefficient_for_connections_invested` |
| `temporal_block` | `representative_period_index` | `representative_block_index` |
| `temporal_block` | `representative_periods_mapping` | `representative_blocks_by_period` |

### 2.9 Scaling and unit conversion

`node.storage_fom_cost` is scaled before renaming from a cost per model duration unit to an annual cost; it is subsequently renamed to `storage_fixed_annual_cost`. The factor is 365 days expressed in the model's duration unit (hours or minutes). If models use mixed duration units, the script defaults to hourly conversion and logs a warning. Unknown or missing duration units are treated as hours with a warning. The parameter default value is scaled as well as all stored values.

## 3. Removals

### Classes removed

- `unit__commodity`
- `unit__node__node` (after its listed parameters are migrated)

### Parameter removed

- `user_constraint.include_in_non_representative_periods`

## 4. Important migration behaviour and caveats

- **Summation exception:** `unit.units_unavailable` is merged into `unit.out_of_service_count_fix` using `sum`; values are summed into the target rather than simply overwriting it.
- **Existing target definitions:** for ordinary parameter renames, if the new name already exists, the old definition's attributes/defaults/value list take precedence and old values overwrite same-alternative target values; other target values are retained.
- **Dimension migration copies more than values:** parameter definitions, entity records, parameter values, entity alternatives, and entity group memberships are copied/re-mapped. Migrated values overwrite existing values at matching destination keys.
- **Potential database inconsistencies:** the script explicitly warns that some older databases may have `unit__node__node` entities without matching `unit__to_node` or `unit__from_node` entities. It recommends fixing those entities manually based on the migration error messages and rerunning.
- **Template list validation:** at the end, values are checked against the latest template lists. Values not in a target list may be dropped during list changes, with warnings. Defaults not valid in the new list can also be dropped.
- **Best-effort operations:** some class/entity/list operations catch errors and log warnings rather than aborting the entire migration. Review migration logs, especially around class conversion and value-list changes.

## 5. Summary by migration type

| Type | Main changes |
|---|---|
| Simple renaming | Parameter names across `unit`, `node`, `connection`, `commodity`, `investment_group`, `model`, multidimensional classes, and `temporal_block`; `commodity` → `grid`; value-list and list-value renames |
| Restructuring | Create `unit_flow` superclass and subclasses; reorder flow class dimensions; consolidate flow/investment-group and flow/user-constraint classes; migrate `unit__node__node` ratio and online-coefficient parameters to `unit_flow__unit_flow`; consolidate variable-type handling; move node voltage-angle/pressure flags into grid physics |
| Value transformation | Convert `storage_fom_cost` to annual cost; sum `units_unavailable` into `out_of_service_count_fix`; translate node physics booleans into grid physics list values |
| Removal | Remove `unit__commodity`, migrated `unit__node__node`, and `user_constraint.include_in_non_representative_periods` |

---

*Generated from the supplied `major_upgrade_1.jl` source. This is a documentation of the migration logic declared in that file; it does not claim that every operation succeeds for every database.*
