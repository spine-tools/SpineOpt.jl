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

@testset "find_version" begin
	url = "sqlite://"
    # With no data
    SpineInterface.close_connection(url)
    SpineInterface.open_connection(url)
	@test SpineOpt.find_version(url) == 1
    SpineInterface.close_connection(url)
    # With settings class only
    SpineInterface.open_connection(url)
	data = Dict(:object_classes => ["settings"])
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 1
    SpineInterface.close_connection(url)
    # With settings class and integer version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", 8)])
    SpineInterface.open_connection(url)
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 8
    SpineInterface.close_connection(url)
    # With settings class and string version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", "77")])
    SpineInterface.open_connection(url)
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 77
    SpineInterface.close_connection(url)
    # With settings class and float version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", 44.0)])
    SpineInterface.open_connection(url)
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 44
    SpineInterface.close_connection(url)
    # With settings class and invalid version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", "invalid")])
    SpineInterface.open_connection(url)
    SpineInterface.import_data(url; data...)
	@test_throws ArgumentError SpineOpt.find_version(url)
    SpineInterface.close_connection(url)
end

@testset "run_migrations" begin
	file_path, io = mktemp()
	url = "sqlite:///$file_path"
	SpineOpt.run_migrations(url, 1, 0)
	Y = Module()
	using_spinedb(url, Y)
	template = SpineOpt.template()
	object_class_names = [Symbol(x[1]) for x in template["object_classes"]]
	relationship_class_names = [Symbol(x[1]) for x in template["relationship_classes"]]
	parameter_names = [Symbol(x[2]) for k in ("object_parameters", "relationship_parameters") for x in template[k]]
	@test Set([x.name for x in object_classes(Y)]) == Set(object_class_names)
	@test Set([x.name for x in relationship_classes(Y)]) == Set(relationship_class_names)
	@test Set([x.name for x in parameters(Y)]) == Set(parameter_names)
	dummy = Object(:dummy, :settings)
	add_objects!(Y.settings, [dummy])
	@test Y.version(settings=dummy) == SpineOpt.current_version()
end

function _test_rename_unit_constraint_to_user_constraint()
	@testset "rename_unit_constraint_to_user_constraint" begin
	end
end

function _test_move_connection_flow_cost()
	@testset "move_connection_flow_cost" begin
		data = Dict(
			:object_classes => ["connection", "node"],
			:relationship_classes => [
				("connection__from_node", ("connection", "node")), ("connection__to_node", ("connection", "node"))
			],
			:object_parameters => [("connection", "connection_flow_cost")],
			:objects => [
				("connection", "conn_ab"),
				("connection", "conn_bc"),
				("node", "node_a"),
				("node", "node_b"),
				("node", "node_c"),
			],
			:relationships => [
				("connection__from_node", ("conn_ab", "node_a")),
				("connection__from_node", ("conn_bc", "node_b")),
				("connection__to_node", ("conn_ab", "node_b")),
				("connection__to_node", ("conn_bc", "node_c")),
			],
			:object_parameter_values => [
				("connection", "conn_ab", "connection_flow_cost", 99),
				("connection", "conn_bc", "connection_flow_cost", -1)
			]
		)
		@testset "successful" begin
			url = "sqlite://"
			_load_test_data_without_template(url, data)
			@test SpineOpt.move_connection_flow_cost(url, 0) === true
			run_request(url, "call_method", ("commit_session", "move_connection_flow_cost"))
			Y = Module()
			using_spinedb(url, Y)
			@test Y.connection_flow_cost(connection=Y.connection(:conn_ab), node=Y.node(:node_a)) == 99
			@test Y.connection_flow_cost(connection=Y.connection(:conn_bc), node=Y.node(:node_b)) == -1
		end
		@testset "unsuccessful" begin
			url = "sqlite://"
			push!(data[:objects], ("connection", "invalid"))
			push!(data[:object_parameter_values], ("connection", "invalid", "connection_flow_cost", 800))
			_load_test_data_without_template(url, data)
			@test_throws Exception SpineOpt.move_connection_flow_cost(url, 0)
		end
	end
end

function _test_rename_model_types()
	@testset "rename_model_types" begin
		url = "sqlite://"
		data = Dict(
			:object_classes => ["model"],
			:objects => [("model", "op"), ("model", "benders")],
			:object_parameters => [("model", "model_type", "spineopt_other", "model_type_list")],
			:object_parameter_values => [
				("model", "op", "model_type", "spineopt_operations"),
				("model", "benders", "model_type", "spineopt_master")
			],
			:parameter_value_lists => [
				("model_type_list", "spineopt_master"),
				("model_type_list", "spineopt_operations"),
				("model_type_list", "spineopt_other")
			]
		)
		_load_test_data_without_template(url, data)
		@test SpineOpt.rename_model_types(url, 0) === true
		run_request(url, "call_method", ("commit_session", "rename_model_types"))
		Y = Module()
		using_spinedb(url, Y)
		@test Y.model_type(model=Y.model(:op)) == :spineopt_standard
		@test Y.model_type(model=Y.model(:benders)) == :spineopt_benders_master
	end
end

function _test_translate_ramp_parameters()
	@testset "translate_ramp_parameters" begin
		url = "sqlite://"
		to_rm_pnames = (
			"min_startup_ramp",
			"min_shutdown_ramp",
			"min_res_startup_ramp",
			"min_res_shutdown_ramp",
			"max_res_startup_ramp",
			"max_res_shutdown_ramp",
		)
		data = Dict(
			:object_classes => ["unit", "node"],
			:relationship_classes => [["unit__to_node", ["unit", "node"]]],
			:relationship_parameters => [
				[["unit__to_node", x] for x in to_rm_pnames];
				[["unit__to_node", "max_startup_ramp"], ["unit__to_node", "max_shutdown_ramp"]]
			],
			:objects => [["unit", "unit_a"], ["node", "node_b"]],
			:relationships => [["unit__to_node", ["unit_a", "node_b"]]],
			:relationship_parameter_values => [
				["unit__to_node", ["unit_a", "node_b"], "max_startup_ramp", 0.5],
				["unit__to_node", ["unit_a", "node_b"], "max_shutdown_ramp", 0.8],
			],
		)
		_load_test_data_without_template(url, data)
		@test SpineOpt.translate_ramp_parameters(url, 0) === true
		run_request(url, "call_method", ("commit_session", "translate_ramp_parameters"))
		Y = Module()
		using_spinedb(url, Y)
		@test isempty(intersect([x.name for x in parameters(Y)], to_rm_pnames))
		@test Y.start_up_limit(unit=Y.unit(:unit_a), node=Y.node(:node_b)) == 0.5
		@test Y.shut_down_limit(unit=Y.unit(:unit_a), node=Y.node(:node_b)) == 0.8
	end
end

function _test_remove_model_tb_ss()
	@testset "remove_model_tb_ss" begin
		url = "sqlite://"
		to_rm_ec_names = ("model__temporal_block", "model__stochastic_structure")
		data = Dict(
			:object_classes => ["model", "temporal_block", "stochastic_structure"],
			:relationship_classes => [
				["model__temporal_block", ["model", "temporal_block"]],
				["model__stochastic_structure", ["model", "stochastic_structure"]],
			],
		)
		_load_test_data_without_template(url, data)
		@test SpineOpt.remove_model_tb_ss(url, 0) === true
		run_request(url, "call_method", ("commit_session", "remove_model_tb_ss"))
		Y = Module()
		using_spinedb(url, Y)
		@test isempty(intersect([x.name for x in relationship_classes(Y)], to_rm_ec_names))
		@test all(cn in [x.name for x in object_classes(Y)] for cn in (:model, :temporal_block, :stochastic_structure))
	end
end

function _test_update_investment_variable_type()
	@testset "update_investment_variable_type" begin
		url = "sqlite://"
		data = Dict(
			:object_classes => ["connection", "node"],
			:object_parameters => [
				("connection", "connection_investment_variable_type", "variable_type_integer", "variable_type_list"),
				("node", "storage_investment_variable_type", "variable_type_integer", "variable_type_list"),
			],
			:parameter_value_lists => [
				("variable_type_list", "variable_type_integer"),
				("variable_type_list", "variable_type_continuous"),
				("connection_investment_variable_type_list", "connection_investment_variable_type_continuous"),
				("connection_investment_variable_type_list", "connection_investment_variable_type_integer"),
			],
			:objects => [("connection", "conn"), ("node", "n")],
			:object_parameter_values => [
				("connection", "conn", "connection_investment_variable_type", "variable_type_continuous"),
				("node", "n", "storage_investment_variable_type", "variable_type_continuous")
			],
		)
		_load_test_data_without_template(url, data)
		Y = Module()
		using_spinedb(url, Y)
		@test Y.connection_investment_variable_type(connection=Y.connection(:conn)) == :variable_type_continuous
		@test Y.storage_investment_variable_type(node=Y.node(:n)) == :variable_type_continuous
		@test SpineOpt.update_investment_variable_type(url, 0) === true
		run_request(url, "call_method", ("commit_session", "update_investment_variable_type"))
		using_spinedb(url, Y)
		@test Y.connection_investment_variable_type(
			connection=Y.connection(:conn)
		) == :connection_investment_variable_type_continuous
		@test Y.storage_investment_variable_type(node=Y.node(:n)) == :storage_investment_variable_type_continuous
	end
end

function _test_add_model_algorithm()
	@testset "add_model_algorithm" begin
		url = "sqlite://"
		data = Dict(
			:object_classes => ["model"],
			:object_parameters => [
				("model", "model_type", "spineopt_standard", "model_type_list"),
			],
			:parameter_value_lists => [
				("model_type_list", "spineopt_standard"),
				("model_type_list", "spineopt_benders"),
				("model_type_list", "spineopt_mga"),
			],
			:objects => [("model", "test_model")],
			:object_parameter_values => [
				("model", "test_model", "model_type", "spineopt_mga"),
			],
		)
		_load_test_data_without_template(url, data)
		Y = Module()
		using_spinedb(url, Y)
		@test Y.model_type(model=Y.model(:test_model)) == :spineopt_mga
		@test SpineOpt.add_model_algorithm(url, 0) === true
		run_request(url, "call_method", ("commit_session", "add_model_algorithm"))
		using_spinedb(url, Y)
		@test Y.model_type(model=Y.model(:test_model)) == :spineopt_standard
		@test Y.model_algorithm(model=Y.model(:test_model)) == :mga_algorithm
	end
end

function _test_rename_lifetime_to_tech_lifetime()
	@testset "rename_lifetime_to_tech_lifetime" begin
		url = "sqlite://"
		data = Dict(
			:object_classes => ["connection", "node", "unit"],
			:objects => [("connection", "conn"), ("node", "n"), ("unit", "u")],
			:object_parameters => [
				("connection", "connection_investment_lifetime"),
				("node", "storage_investment_lifetime"),
				("unit", "unit_investment_lifetime")
			],
			:object_parameter_values => [
				("connection", "conn", "connection_investment_lifetime", Dict("type" => "duration", "data" => "1Y")),
				("node", "n", "storage_investment_lifetime", Dict("type" => "duration", "data" => "1Y")),
				("unit", "u", "unit_investment_lifetime", Dict("type" => "duration", "data" => "1Y"))
			]
		)
		_load_test_data_without_template(url, data)
		Y = Module()
		using_spinedb(url, Y)
		@test SpineOpt.rename_lifetime_to_tech_lifetime(url, 0) === true
		run_request(url, "call_method", ("commit_session", "rename_lifetime_to_tech_lifetime"))
		using_spinedb(url, Y)
		@test Y.connection_investment_tech_lifetime(connection=Y.connection(:conn)) == Year(1)
		@test Y.storage_investment_tech_lifetime(node=Y.node(:n)) == Year(1)
		@test Y.unit_investment_tech_lifetime(unit=Y.unit(:u)) == Year(1)		
	end
end

function _test_translate_heatrate_parameters()
	@testset "translate_heatrate_parameters" begin
		url = "sqlite://"
		data = Dict(
			:object_classes => ["node", "unit"],
			:relationship_classes => [
				["unit__node__node", ["unit", "node", "node"]],
			],
			:objects => [("node", "n1"), ("node", "n2"), ("unit", "u")],
			:relationships => [("unit__node__node", ["u", "n1", "n2"])],
			:relationship_parameters => [
				("unit__node__node", "unit_incremental_heat_rate"),
				("unit__node__node", "unit_idle_heat_rate")
			],
			:relationship_parameter_values => [
				("unit__node__node", ["u", "n1", "n2"], "unit_incremental_heat_rate", 10),
				("unit__node__node", ["u", "n1", "n2"], "unit_idle_heat_rate", 200)
			]
		)
		_load_test_data_without_template(url, data)
		Y = Module()
		using_spinedb(url, Y)
		@test SpineOpt.translate_heatrate_parameters(url, 0) === true
		run_request(url, "call_method", ("commit_session", "translate_heatrate_parameters"))
		using_spinedb(url, Y)
		@test Y.fix_ratio_in_out_unit_flow(unit=Y.unit(:u), node1=Y.node(:n1), node2=Y.node(:n2)) == 10
		@test Y.fix_units_on_coefficient_in_out(unit=Y.unit(:u), node1=Y.node(:n1), node2=Y.node(:n2)) == 200	
	end
end

function _test_translate_use_economic_representation__use_milestone_years_setup()
	url_in = "sqlite://"
	data = Dict(
		:object_classes => ["model",],
		:objects => [
			("model", "instance"),
		],
		:parameter_value_lists => [("boolean_value_list", true), ("boolean_value_list", false)],
		:object_parameters => [
			("model", "use_economic_representation", false, "boolean_value_list"),
			("model", "use_milestone_years", false, "boolean_value_list"),
		],
	)
	_load_test_data_without_template(url_in, data)
	url_in
end

function _test_translate_use_economic_representation__use_milestone_years()
	_options = (nothing, false, true)
	cases = collect(Iterators.product(_options, _options))
	
	for (use_economic_representation, use_milestone_years) in cases
		@testset "translate_use_economic_representation__use_milestone_years:
		use_economic_representation = $use_economic_representation,
		use_milestone_years = $use_milestone_years" begin
			url = _test_translate_use_economic_representation__use_milestone_years_setup()		
			object_parameter_values = [
				["model", "instance", "use_economic_representation", use_economic_representation],
				["model", "instance", "use_milestone_years", use_milestone_years]
			]
			SpineInterface.import_data(
				url; 
				object_parameter_values=object_parameter_values,
			)

			Y = Module()
			using_spinedb(url, Y)
			@test SpineOpt.translate_use_economic_representation__use_milestone_years(url, 0) === true
			run_request(
				url, "call_method", ("commit_session", "translate_use_economic_representation__use_milestone_years")
			)

			_check = run_request(
				url,
				"query",
				("list_value_sq", "parameter_value_list_sq"),
			)
			@show collect(_check)

			old_parameter_names = [:use_economic_representation, :use_milestone_years]
			new_parameter_name = :multiyear_economic_discounting

			using_spinedb(url, Y)
			
			all_parameter_names = [x.name for x in parameters(Y)]
			@test isempty(intersect(all_parameter_names, old_parameter_names))
			@test new_parameter_name in all_parameter_names
			
			if isnothing(use_economic_representation) || !use_economic_representation
				@test isnothing(Y.multiyear_economic_discounting(model=Y.model(:instance)))
			else
				if isnothing(use_milestone_years) || !use_milestone_years
					@test Y.multiyear_economic_discounting(model=Y.model(:instance)) == :consecutive_years
				elseif use_milestone_years == true
					@test Y.multiyear_economic_discounting(model=Y.model(:instance)) == :milestone_years
				end
			end
		end
	end

	# Test the case where the new parameter and is value list is already present, e.g. by loading the latest template
	url_w_template = _test_translate_use_economic_representation__use_milestone_years_setup()
	_load_test_data(url_w_template, Dict())	# incl. loading the latest template
	Y = Module()
	using_spinedb(url_w_template, Y)
	@test SpineOpt.translate_use_economic_representation__use_milestone_years(url_w_template, 0) === true
end

function _test_dummy_migrations_functions()
	url_in = "sqlite://"
	@testset "dummy_migrations_functions" begin
		@test SpineOpt.add_units_out_of_service_and_min_capacity_margin(url_in,0)
		@test SpineOpt.add_stage_output(url_in,0)
		@test SpineOpt.add_node_availability_factor(url_in,0)
		@test SpineOpt.add_node_state_min_factor(url_in,0)
		@test SpineOpt.add_connection_min_factor(url_in,0)
	end
end

@testset "migration scripts" begin
	# _test_rename_unit_constraint_to_user_constraint()
	# _test_move_connection_flow_cost()
	# _test_rename_model_types()
	# _test_translate_ramp_parameters()
	# _test_remove_model_tb_ss()
	# _test_update_investment_variable_type()
	# _test_add_model_algorithm()
	# _test_rename_lifetime_to_tech_lifetime()
	# _test_translate_heatrate_parameters()
	_test_translate_use_economic_representation__use_milestone_years()
	_test_dummy_migrations_functions()
end