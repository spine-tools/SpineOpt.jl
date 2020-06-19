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

@testset "node-based constraints" begin
	url_in = "sqlite:///$(@__DIR__)/test.sqlite"
	test_data = Dict(
		:objects => [
			["model", "instance"], 
			["temporal_block", "hourly"],
			["temporal_block", "two_hourly"],
			["stochastic_structure", "deterministic"],
			["stochastic_structure", "stochastic"],
			["unit", "unit_ab"],
			["connection", "connection_bc"],
			["connection", "connection_ca"],
			["node", "test_node_a"],
			["node", "test_node_b"],
			["node", "test_node_c"],
			["node", "test_group_node_bc"],
			["stochastic_scenario", "parent"],
			["stochastic_scenario", "child"],
		],
		:relationships => [
			["units_on_resolution", ["unit_ab", "test_node_a"]],
			["unit__from_node", ["unit_ab", "test_node_a"]],
			["unit__to_node", ["unit_ab", "test_node_b"]],
			["connection__from_node", ["connection_bc", "test_node_b"]],
			["connection__to_node", ["connection_bc", "test_node_c"]],
			["connection__from_node", ["connection_ca", "test_node_c"]],
			["connection__to_node", ["connection_ca", "test_node_a"]],
			["node__temporal_block", ["test_node_a", "two_hourly"]],
			["node__temporal_block", ["test_node_b", "hourly"]],
			["node__temporal_block", ["test_node_c", "hourly"]],
			["node__temporal_block", ["test_group_node_bc", "hourly"]],
			["node__stochastic_structure", ["test_node_a", "deterministic"]],
			["node__stochastic_structure", ["test_node_b", "stochastic"]],
			["node__stochastic_structure", ["test_node_c", "stochastic"]],
			["node__stochastic_structure", ["test_group_node_bc", "stochastic"]],
			["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
			["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
			["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
			["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
			["node_group__node", ["test_group_node_bc", "test_node_b"]],
			["node_group__node", ["test_group_node_bc", "test_node_c"]],
		],
		:object_parameter_values => [
			["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
			["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
			["model", "instance", "duration_unit", "hour"],
			["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
			["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
        	["node", "test_group_node_bc", "balance_type", "balance_type_group"],
		],
		:relationship_parameter_values => [
			[
				"stochastic_structure__stochastic_scenario", 
				["stochastic", "parent"], 
				"stochastic_scenario_end", 
				Dict("type" => "duration", "data" => "1h")
			]
		]
	)
	@testset "constraint_nodal_balance" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		object_parameter_values = [
        	["node", "test_node_a", "node_slack_penalty", 0.5],
        ]
        db_api.import_data_to_url(url_in; object_parameter_values=object_parameter_values)
		m = run_spineopt(url_in; log_level=0)
		var_node_injection = m.ext[:variables][:node_injection]
		var_connection_flow = m.ext[:variables][:connection_flow]
		var_node_slack_pos = m.ext[:variables][:node_slack_pos]
		var_node_slack_neg = m.ext[:variables][:node_slack_neg]
		constraint = m.ext[:constraints][:nodal_balance]
		@test length(constraint) == 3
		conn = connection(:connection_ca)
		# test_node_a
		n = node(:test_node_a)
		key_tail = (stochastic_scenario(:parent), time_slice(temporal_block=temporal_block(:two_hourly))[1])
		node_key = (n, key_tail...)
		conn_key = (conn, n, direction(:to_node), key_tail...)
		var_n_inj = var_node_injection[node_key...]
		var_n_sl_pos = var_node_slack_pos[node_key...]
		var_n_sl_neg = var_node_slack_neg[node_key...]
		var_conn_flow = var_connection_flow[conn_key...]
		expected_con = @build_constraint(var_n_inj + var_conn_flow + var_n_sl_pos - var_n_sl_neg == 0)
		con = constraint[node_key]
		observed_con = constraint_object(con)
		@test _is_constraint_equal(observed_con, expected_con)
		# test_group_node_bc
		n = node(:test_group_node_bc)
		scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
		time_slices = time_slice(temporal_block=temporal_block(:hourly))
		@testset for (s, t) in zip(scenarios, time_slices)
			var_n_inj = var_node_injection[node(:test_group_node_bc), s, t]
			var_conn_flow = var_connection_flow[conn, node(:test_node_c), direction(:from_node), s, t]
			expected_con = @build_constraint(var_n_inj - var_conn_flow == 0)
			con = constraint[node(:test_group_node_bc), s, t]
			observed_con = constraint_object(con)
			@test _is_constraint_equal(observed_con, expected_con)
		end
	end
	@testset "constraint_node_injection" begin
		demand_a = 100
		demand_b = 20
		demand_c = -80
		demand_group = 200
		fractional_demand_b = 0.6
		fractional_demand_c = 0.4
		frac_state_loss_b = 0.15
		frac_state_loss_c = 0.25
		state_coeff_b = 0.9
		state_coeff_c = 0.8
		diff_coeff_bc = 0.2
		diff_coeff_cb = 0.3
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		relationships = [
			["node__node", ["test_node_b", "test_node_c"]], ["node__node", ["test_node_c", "test_node_b"]]
		]
		object_parameter_values = [
			["node", "test_node_a", "demand", demand_a],
			["node", "test_node_b", "demand", demand_b],
			["node", "test_node_c", "demand", demand_c],
			["node", "test_group_node_bc", "demand", demand_group],
			["node", "test_node_b", "has_state", "value_true"],
			["node", "test_node_c", "has_state", "value_true"],
	        ["node", "test_node_b", "frac_state_loss", frac_state_loss_b],
	        ["node", "test_node_c", "frac_state_loss", frac_state_loss_c],
	        ["node", "test_node_b", "state_coeff", state_coeff_b],
	        ["node", "test_node_c", "state_coeff", state_coeff_c],
	    ]
		relationship_parameter_values = [
	        ["node__node", ["test_node_b", "test_node_c"], "diff_coeff", diff_coeff_bc],
	        ["node__node", ["test_node_c", "test_node_b"], "diff_coeff", diff_coeff_cb],
			["node_group__node", ["test_group_node_bc", "test_node_b"], "fractional_demand", fractional_demand_b],
			["node_group__node", ["test_group_node_bc", "test_node_c"], "fractional_demand", fractional_demand_c],
		]
		db_api.import_data_to_url(
			url_in; 
			relationships=relationships, 
			object_parameter_values=object_parameter_values, 
			relationship_parameter_values=relationship_parameter_values
		)
		m = run_spineopt(url_in; log_level=0)
		var_node_injection = m.ext[:variables][:node_injection]
		var_unit_flow = m.ext[:variables][:unit_flow]
		var_node_state = m.ext[:variables][:node_state]
		constraint = m.ext[:constraints][:node_injection]
		@test length(constraint) == 11
		u = unit(:unit_ab)
		# test_node_a
		n = node(:test_node_a)
		s = stochastic_scenario(:parent)
		time_slices = time_slice(temporal_block=temporal_block(:two_hourly))
		@testset for t1 in time_slices
			var_n_inj = var_node_injection[n, s, t1]
			var_u_flow = var_unit_flow[u, node(:test_node_a), direction(:from_node), s, t1]
			expected_con = @build_constraint(var_n_inj + var_u_flow + demand_a == 0)
			@testset for t0 in t_before_t(t_after=t1)
				con = constraint[n, [s], t0, t1]
				observed_con = constraint_object(con)
				@test _is_constraint_equal(observed_con, expected_con)
			end
		end
		# test_group_node_bc
		n = node(:test_group_node_bc)
		scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
		time_slices = time_slice(temporal_block=temporal_block(:hourly))
		@testset for (s, t1) in zip(scenarios, time_slices)
			var_n_inj = var_node_injection[n, s, t1]
			var_u_flow = var_unit_flow[u, node(:test_node_b), direction(:to_node), s, t1]
			expected_con = @build_constraint(var_n_inj - var_u_flow + demand_group == 0)
			@testset for t0 in t_before_t(t_after=t1)
				con = constraint[n, [s], t0, t1]
				observed_con = constraint_object(con)
				@test _is_constraint_equal(observed_con, expected_con)
			end
		end
		# test_node_b
		n = node(:test_node_b)
		s0 = stochastic_scenario(:parent)
		scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
		time_slices = time_slice(temporal_block=temporal_block(:hourly))
		@testset for (s1, t1) in zip(scenarios, time_slices)
			path = unique([s0, s1])
			var_n_st_b1 = var_node_state[n, s1, t1]
			var_n_st_c1 = var_node_state[node(:test_node_c), s1, t1]
			var_n_inj = var_node_injection[n, s1, t1]
			var_u_flow = var_unit_flow[u, node(:test_node_b), direction(:to_node), s1, t1]
			@testset for t0 in t_before_t(t_after=t1)
				var_n_st_b0 = get(var_node_state, (n, s0, t0), 0)
				expected_con = @build_constraint(
					var_n_inj 
					+ (state_coeff_b + frac_state_loss_b + diff_coeff_bc) * var_n_st_b1
					- state_coeff_b * var_n_st_b0
					- diff_coeff_cb * var_n_st_c1 
					- var_u_flow 
					+ demand_b 
					+ demand_group * fractional_demand_b
					== 0
				)
				con = constraint[n, path, t0, t1]
				observed_con = constraint_object(con)
				@test _is_constraint_equal(observed_con, expected_con)
			end
		end
		# test_node_c
		n = node(:test_node_c)
		s0 = stochastic_scenario(:parent)
		scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
		time_slices = time_slice(temporal_block=temporal_block(:hourly))
		@testset for (s1, t1) in zip(scenarios, time_slices)
			path = unique([s0, s1])
			var_n_st_c1 = var_node_state[n, s1, t1]
			var_n_st_b1 = var_node_state[node(:test_node_b), s1, t1]
			var_n_inj = var_node_injection[n, s1, t1]
			@testset for t0 in t_before_t(t_after=t1)
				var_n_st_c0 = get(var_node_state, (n, s0, t0), 0)
				expected_con = @build_constraint(
					var_n_inj 
					+ (state_coeff_c + frac_state_loss_c + diff_coeff_cb) * var_n_st_c1
					- state_coeff_c * var_n_st_c0
					- diff_coeff_bc * var_n_st_b1 
					+ demand_c 
					+ demand_group * fractional_demand_c
					== 0
				)
				con = constraint[n, path, t0, t1]
				observed_con = constraint_object(con)
				@test _is_constraint_equal(observed_con, expected_con)
			end
		end
	end
	@testset "constraint_node_state_capacity" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		node_capacity = Dict(
			"test_node_b" => 120,
			"test_node_c" => 400,
		)
		object_parameter_values = [
			["node", "test_node_b", "node_state_cap", node_capacity["test_node_b"]],
			["node", "test_node_c", "node_state_cap", node_capacity["test_node_c"]],
			["node", "test_node_b", "has_state", "value_true"],
			["node", "test_node_c", "has_state", "value_true"],
		]
		db_api.import_data_to_url(url_in; object_parameter_values=object_parameter_values)
		m = run_spineopt(url_in; log_level=0)
		var_node_state = m.ext[:variables][:node_state]
		constraint = m.ext[:constraints][:node_state_capacity]
		@test length(constraint) == 4
		scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
		time_slices = time_slice(temporal_block=temporal_block(:hourly))
		@testset for (s, t) in zip(scenarios, time_slices)
			@testset for (name, cap) in node_capacity
				n = node(Symbol(name))
				key = (n, s, t)
				var_n_st = var_node_state[key...]
				expected_con = @build_constraint(var_n_st <= cap)
				con = constraint[key]
				observed_con = constraint_object(con)
				@test _is_constraint_equal(observed_con, expected_con)
			end
		end
	end
end