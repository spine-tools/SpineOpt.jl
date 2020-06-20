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

@testset "connection-based constraints" begin
	url_in = "sqlite:///$(@__DIR__)/test.sqlite"
	test_data = Dict(
		:objects => [
			["model", "instance"], 
			["temporal_block", "hourly"],
			["temporal_block", "two_hourly"],
			["stochastic_structure", "deterministic"],
			["stochastic_structure", "stochastic"],
			["connection", "connection_ab"],
			["connection", "connection_bc"],
			["connection", "connection_ca"],
			["node", "node_a"],
			["node", "node_b"],
			["node", "node_c"],
			["stochastic_scenario", "parent"],
			["stochastic_scenario", "child"],
		],
		:relationships => [
			["connection__from_node", ["connection_ab", "node_a"]],
			["connection__to_node", ["connection_ab", "node_b"]],
			["connection__from_node", ["connection_bc", "node_b"]],
			["connection__to_node", ["connection_bc", "node_c"]],
			["connection__from_node", ["connection_ca", "node_c"]],
			["connection__to_node", ["connection_ca", "node_a"]],
			["node__temporal_block", ["node_a", "hourly"]],
			["node__temporal_block", ["node_b", "two_hourly"]],
			["node__temporal_block", ["node_c", "hourly"]],
			["node__stochastic_structure", ["node_a", "stochastic"]],
			["node__stochastic_structure", ["node_b", "deterministic"]],
			["node__stochastic_structure", ["node_c", "stochastic"]],
			["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
			["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
			["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
			["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
		],
		:object_parameter_values => [
			["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
			["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
			["model", "instance", "duration_unit", "hour"],
			["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
			["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
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
	@testset "constraint_connection_flow_capacity" begin
		connection_capacity = 200
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		relationship_parameter_values = [
			["connection__from_node", ["connection_ab", "node_a"], "connection_capacity", connection_capacity]
		]
		db_api.import_data_to_url(url_in; relationship_parameter_values=relationship_parameter_values)
		m = run_spineopt(url_in; log_level=0)
		var_connection_flow = m.ext[:variables][:connection_flow]
		constraint = m.ext[:constraints][:connection_flow_capacity]
		@test length(constraint) == 2
		scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
		time_slices = time_slice(temporal_block=temporal_block(:hourly))
		@testset for (s, t) in zip(scenarios, time_slices)
			key = (connection(:connection_ab), node(:node_a), direction(:from_node), s, t)
			var_conn_flow = var_connection_flow[key...]
			expected_con = @build_constraint(var_conn_flow <= connection_capacity)
			observed_con = constraint_object(constraint[key])
			@test _is_constraint_equal(observed_con, expected_con)
		end
	end
	@testset "constraint_connection_flow_ptdf" begin
		conn_r = 0.9
		conn_x = 0.1
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		objects = [["commodity", "electricity"]]
		relationships = [
			["connection__from_node", ["connection_ab", "node_b"]],
			["connection__to_node", ["connection_ab", "node_a"]],
			["connection__from_node", ["connection_bc", "node_c"]],
			["connection__to_node", ["connection_bc", "node_b"]],
			["connection__from_node", ["connection_ca", "node_a"]],
			["connection__to_node", ["connection_ca", "node_c"]],
			["node__commodity", ["node_a", "electricity"]],
			["node__commodity", ["node_b", "electricity"]],
			["node__commodity", ["node_c", "electricity"]],
			["connection__node__node", ["connection_ab", "node_b", "node_a"]],
			["connection__node__node", ["connection_ab", "node_a", "node_b"]],
			["connection__node__node", ["connection_bc", "node_c", "node_b"]],
			["connection__node__node", ["connection_bc", "node_b", "node_c"]],
			["connection__node__node", ["connection_ca", "node_a", "node_c"]],
			["connection__node__node", ["connection_ca", "node_c", "node_a"]],
		]
		object_parameter_values = [
			["connection", "connection_ab", "connection_monitored", "value_true"],
	        ["connection", "connection_ab", "connection_reactance", conn_x],
	        ["connection", "connection_ab", "connection_resistance", conn_r],
			["connection", "connection_bc", "connection_monitored", "value_true"],
	        ["connection", "connection_bc", "connection_reactance", conn_x],
	        ["connection", "connection_bc", "connection_resistance", conn_r],
			["connection", "connection_ca", "connection_monitored", "value_true"],
	        ["connection", "connection_ca", "connection_reactance", conn_x],
	        ["connection", "connection_ca", "connection_resistance", conn_r],
			["commodity", "electricity", "commodity_physics", "commodity_physics_ptdf"],
        	["node", "node_a", "node_opf_type", "node_opf_type_reference"],
		]
		relationship_parameter_values = [
			["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
			["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
			["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
			["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
			["connection__node__node", ["connection_ca", "node_a", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
			["connection__node__node", ["connection_ca", "node_c", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
		]
		db_api.import_data_to_url(
			url_in; 
			objects=objects,
			relationships=relationships,
			object_parameter_values=object_parameter_values,
			relationship_parameter_values=relationship_parameter_values
		)
		m = run_spineopt(url_in; log_level=0)
		var_connection_flow = m.ext[:variables][:connection_flow]
		var_node_injection = m.ext[:variables][:node_injection]
		constraint = m.ext[:constraints][:flow_ptdf]
		@test length(constraint) == 5
		@testset for (conn_name, n_to_name, n_inj_name, scen_names, t_block) in (
				(:connection_ab, :node_b, :node_b, (:parent,), :two_hourly),
				(:connection_bc, :node_c, :node_c, (:parent, :child), :hourly),
				(:connection_ca, :node_a, :node_c, (:parent, :child), :hourly)
			)
			conn = connection(conn_name)
			n_to = node(n_to_name)
			n_inj = node(n_inj_name)
			scenarios = (stochastic_scenario(s) for s in scen_names)
			time_slices = time_slice(temporal_block=temporal_block(t_block))
			@testset for (s, t) in zip(scenarios, time_slices)
				var_conn_flow_to = var_connection_flow[conn, n_to, direction(:to_node), s, t]
				var_conn_flow_from = var_connection_flow[conn, n_to, direction(:from_node), s, t]
				var_n_inj = var_node_injection[n_inj, s, t]
				ptdf_val = SpineOpt.ptdf(connection=conn, node=n_inj)
				expected_con = @build_constraint(var_conn_flow_to - var_conn_flow_from == ptdf_val * var_n_inj)
				observed_con = constraint_object(constraint[conn, n_to, [s], t])
				@test _is_constraint_equal(observed_con, expected_con)
			end
		end
	end
end