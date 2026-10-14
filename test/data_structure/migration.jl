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

const url_in = "sqlite://"

@testset "find_version" begin
    # With no data
    with_connection_open(url_in) do
        @test SpineOpt.find_version(url_in) == 1
    end
    # With settings class only
    with_connection_open(url_in) do
    	data = Dict(:object_classes => ["settings"])
        SpineInterface.import_data(url_in; data...)
    	@test SpineOpt.find_version(url_in) == 1
    end
    # With settings class and integer version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", 8)])
	with_connection_open(url_in) do
        SpineInterface.import_data(url_in; data...)
    	@test SpineOpt.find_version(url_in) == 8
	end
	# With settings class and string version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", "77")])
	with_connection_open(url_in) do
        SpineInterface.import_data(url_in; data...)
    	@test SpineOpt.find_version(url_in) == 77
	end
	# With settings class and float version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", 44.0)])
    with_connection_open(url_in) do
        SpineInterface.import_data(url_in; data...)
    	@test SpineOpt.find_version(url_in) == 44
    end
    # With settings class and invalid version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", "invalid")])
	with_connection_open(url_in) do
        SpineInterface.import_data(url_in; data...)
    	@test_throws ArgumentError SpineOpt.find_version(url_in)
	end
end

@testset "run_migrations" begin
	file_path, io = mktemp()
	url = "sqlite:///$file_path"
	SpineOpt.run_migrations(url, 1, 0)
	Y = Bind()
	using_spinedb(url, Y)
	template = SpineOpt.template()
	object_class_names = Set(
		Symbol(x[1]) for x in template["entity_classes"] if isempty(x[2])
	)
	relationship_class_names = Set(
		Symbol(x[1]) for x in template["entity_classes"] if !isempty(x[2])
	)
	superclass_names = Set(
		Symbol(x[1]) for x in template["superclass_subclasses"]
	)
	parameter_names = Set(
		Symbol(x[2]) for x in template["parameter_definitions"]
	)
	@test Set(x.name for x in object_classes(Y)) == setdiff!(object_class_names, superclass_names)
	@test Set(x.name for x in relationship_classes(Y)) == relationship_class_names
	@test Set(x.name for x in superclasses(Y)) == superclass_names
	@test Set(x.name for x in parameters(Y)) == Set(parameter_names)
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
			with_connection_open(url_in) do
    			_load_test_data_without_template(url_in, data)
    			@test SpineOpt.move_connection_flow_cost(url_in, 0) === true
    			run_request(url_in, "call_method", ("commit_session", "move_connection_flow_cost"))
    			Y = Bind()
    			using_spinedb(url_in, Y)
    			@test Y.connection_flow_cost(connection=Y.connection(:conn_ab), node=Y.node(:node_a)) == 99
    			@test Y.connection_flow_cost(connection=Y.connection(:conn_bc), node=Y.node(:node_b)) == -1
            end
		end
		@testset "unsuccessful" begin
			push!(data[:objects], ("connection", "invalid"))
			push!(data[:object_parameter_values], ("connection", "invalid", "connection_flow_cost", 800))
			with_connection_open(url_in) do
    			_load_test_data_without_template(url_in, data)
    			@test_throws Exception SpineOpt.move_connection_flow_cost(url_in, 0)
            end
		end
	end
end

function _test_rename_model_types()
	@testset "rename_model_types" begin
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
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		@test SpineOpt.rename_model_types(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "rename_model_types"))
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test Y.model_type(model=Y.model(:op)) == :spineopt_standard
    		@test Y.model_type(model=Y.model(:benders)) == :spineopt_benders_master
    	end
    end
end

function _test_translate_ramp_parameters()
	@testset "translate_ramp_parameters" begin
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
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		@test SpineOpt.translate_ramp_parameters(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "translate_ramp_parameters"))
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test isempty(intersect([x.name for x in parameters(Y)], to_rm_pnames))
    		@test Y.ramp_limits_startup(unit=Y.unit(:unit_a), node=Y.node(:node_b)) == 0.5
    		@test Y.ramp_limits_shutdown(unit=Y.unit(:unit_a), node=Y.node(:node_b)) == 0.8
    	end
    end
end

function _test_remove_model_tb_ss()
	@testset "remove_model_tb_ss" begin
		to_rm_ec_names = ("model__temporal_block", "model__stochastic_structure")
		data = Dict(
			:object_classes => ["model", "temporal_block", "stochastic_structure"],
			:relationship_classes => [
				["model__temporal_block", ["model", "temporal_block"]],
				["model__stochastic_structure", ["model", "stochastic_structure"]],
			],
		)
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		@test SpineOpt.remove_model_tb_ss(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "remove_model_tb_ss"))
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test isempty(intersect([x.name for x in relationship_classes(Y)], to_rm_ec_names))
    		@test all(cn in [x.name for x in object_classes(Y)] for cn in (:model, :temporal_block, :stochastic_structure))
    	end
    end
end

function _test_update_investment_variable_type()
	@testset "update_investment_variable_type" begin
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
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test Y.connection_investment_variable_type(connection=Y.connection(:conn)) == :variable_type_continuous
    		@test Y.storage_investment_variable_type(node=Y.node(:n)) == :variable_type_continuous
    		@test SpineOpt.update_investment_variable_type(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "update_investment_variable_type"))
    		using_spinedb(url_in, Y)
    		@test Y.connection_investment_variable_type(
    			connection=Y.connection(:conn)
    		) == :connection_investment_variable_type_continuous
    		@test Y.storage_investment_variable_type(node=Y.node(:n)) == :storage_investment_variable_type_continuous
    	end
    end
end

function _test_add_model_algorithm()
	@testset "add_model_algorithm" begin
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
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test Y.model_type(model=Y.model(:test_model)) == :spineopt_mga
    		@test SpineOpt.add_model_algorithm(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "add_model_algorithm"))
    		using_spinedb(url_in, Y)
    		@test Y.model_type(model=Y.model(:test_model)) == :spineopt_standard
    		@test Y.model_algorithm(model=Y.model(:test_model)) == :mga_algorithm
    	end
    end
end

function _test_rename_lifetime_to_tech_lifetime()
	@testset "rename_lifetime_to_tech_lifetime" begin
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
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test SpineOpt.rename_lifetime_to_tech_lifetime(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "rename_lifetime_to_tech_lifetime"))
    		using_spinedb(url_in, Y)
    		@test Y.connection_investment_tech_lifetime(connection=Y.connection(:conn)) == Year(1)
    		@test Y.storage_investment_tech_lifetime(node=Y.node(:n)) == Year(1)
    		@test Y.unit_investment_tech_lifetime(unit=Y.unit(:u)) == Year(1)
    	end
    end
end
function _test_translate_heatrate_parameters()
	@testset "translate_heatrate_parameters" begin
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
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test SpineOpt.translate_heatrate_parameters(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "translate_heatrate_parameters"))
    		using_spinedb(url_in, Y)
    		@test Y.fix_ratio_in_out_unit_flow(unit=Y.unit(:u), node1=Y.node(:n1), node2=Y.node(:n2)) == 10
    		@test Y.fix_units_on_coefficient_in_out(unit=Y.unit(:u), node1=Y.node(:n1), node2=Y.node(:n2)) == 200
    	end
    end
end

function _test_translate_use_economic_representation__use_milestone_years_setup()
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
end

function _test_translate_use_economic_representation__use_milestone_years()
	_options = (nothing, false, true)
	cases = collect(Iterators.product(_options, _options))

	for (use_economic_representation, use_milestone_years) in cases
		@testset "translate_use_economic_representation__use_milestone_years:
		use_economic_representation = $use_economic_representation,
		use_milestone_years = $use_milestone_years" begin
		    with_connection_open(url_in) do
    		    _test_translate_use_economic_representation__use_milestone_years_setup()
    			object_parameter_values = [
    				["model", "instance", "use_economic_representation", use_economic_representation],
    				["model", "instance", "use_milestone_years", use_milestone_years]
    			]
    			SpineInterface.import_data(
    				url_in;
    				object_parameter_values=object_parameter_values,
    			)

    			Y = Bind()
    			using_spinedb(url_in, Y)
    			@test SpineOpt.translate_use_economic_representation__use_milestone_years(url_in, 0) === true
    			run_request(
    				url_in, "call_method", ("commit_session", "translate_use_economic_representation__use_milestone_years")
    			)

    			_check = run_request(
    				url_in,
    				"query",
    				("list_value_sq", "parameter_value_list_sq"),
    			)
    			@show collect(_check)

    			old_parameter_names = [:use_economic_representation, :use_milestone_years]
    			new_parameter_name = :multiyear_economic_discounting

    			using_spinedb(url_in, Y)

    			all_parameter_names = [x.name for x in parameters(Y)]
    			@test isempty(intersect(all_parameter_names, old_parameter_names))
    			@test new_parameter_name in all_parameter_names

    			if isnothing(use_economic_representation) || !use_economic_representation
                    println(Y.multiyear_economic_discounting(model=Y.model(:instance), _strict=false))
    				@test isnothing(Y.multiyear_economic_discounting(model=Y.model(:instance), _strict=false))
    			else
    				if isnothing(use_milestone_years) || !use_milestone_years
    					@test Y.multiyear_economic_discounting(model=Y.model(:instance)) == :consecutive_years
    				elseif use_milestone_years == true
    					@test Y.multiyear_economic_discounting(model=Y.model(:instance)) == :milestone_years
    				end
    			end
    		end
    	end
    end
	# Test the case where the new parameter and is value list is already present, e.g. by loading the latest template
	with_connection_open(url_in) do
    	_test_translate_use_economic_representation__use_milestone_years_setup()
    	_load_test_data(url_in, Dict())	# incl. loading the latest template
    	Y = Bind()
    	using_spinedb(url_in, Y)
    	@test SpineOpt.translate_use_economic_representation__use_milestone_years(url_in, 0) === true
    end
end

function _test_dummy_migrations_functions()
	@testset "dummy_migrations_functions" begin
		@test SpineOpt.add_units_out_of_service_and_min_capacity_margin(url_in,0)
		@test SpineOpt.add_stage_output(url_in,0)
		@test SpineOpt.add_node_state_longterm_output(url_in,0)
		@test SpineOpt.add_node_availability_factor(url_in,0)
		@test SpineOpt.add_node_state_min_factor(url_in,0)
		@test SpineOpt.add_connection_min_factor(url_in,0)
	end
end

function _test_major_upgrade_1(; template_on_top=false)
	log_level = 0
	# Non-comprehensive migration test. Samples every sub-function, though.
	# With `template_on_top`, the latest template is imported before migrating (as if the new parameters, classes and
	# lists were already added by hand), which should give the same result.
	@testset "major_upgrade_1$(template_on_top ? " with latest template on top" : "")" begin
		original_data = Dict(
			:object_classes => [
				"commodity",
				"connection",
				"investment_group",
				"node",
				"unit",
				"user_constraint"
			],
			:relationship_classes => [
				("unit__commodity", ("unit", "commodity")),
				("unit__from_node", ("unit", "node")),
				("unit__from_node__investment_group", ("unit", "node", "investment_group")),
				("unit__from_node__user_constraint", ("unit", "node", "user_constraint")),
				("unit__to_node", ("unit", "node")),
				("unit__to_node__investment_group", ("unit", "node", "investment_group")),
				("unit__to_node__user_constraint", ("unit", "node", "user_constraint")),
				("unit__node__node", ("unit", "node", "node")),
			],
			:objects => [
				("commodity", "com"),
				("unit", "u"),
				("node", "n"),
				("user_constraint", "uc"),
				("investment_group", "ig"),
			],
			:relationships => [
				("unit__from_node", ("u", "n")),
				("unit__from_node__user_constraint", ("u", "n", "uc")),
				("unit__from_node__investment_group", ("u", "n", "ig")),
				("unit__to_node", ("u", "n")),
				("unit__to_node__user_constraint", ("u", "n", "uc")),
				("unit__node__node", ("u", "n", "n")),
			],
			:alternatives => ["alt_ts"],
			:object_parameters => [
				("commodity", "commodity_lodf_tolerance"),
				("unit", "fix_units_out_of_service"),
				("unit", "units_unavailable"),
				("node", "storage_fom_cost", 0.5),
				("user_constraint", "include_in_non_representative_periods")
			],
			:object_parameter_values => [
				("commodity", "com", "commodity_lodf_tolerance", 1),
				("unit", "u", "fix_units_out_of_service", 1),
				("unit", "u", "units_unavailable", 2),
				("node", "n", "storage_fom_cost", 2.5),
				(
					"node", "n", "storage_fom_cost",
					unparse_db_value(TimeSeries([DateTime(2000), DateTime(2001)], [1.0, 2.0])), "alt_ts"
				),
				("user_constraint", "uc", "include_in_non_representative_periods", true),
			],
			:relationship_parameters => [
				("unit__from_node", "fix_unit_flow"),
				("unit__from_node__user_constraint", "unit_flow_coefficient"),
				("unit__to_node", "fix_unit_flow"),
				("unit__node__node", "fix_ratio_in_out_unit_flow"),
			],
			:relationship_parameter_values => [
				("unit__from_node", ("u", "n"), "fix_unit_flow", 2),
				("unit__to_node", ("u", "n"), "fix_unit_flow", 3),
				("unit__from_node__user_constraint", ("u", "n", "uc"), "unit_flow_coefficient", 4),
				("unit__node__node", ("u", "n", "n"), "fix_ratio_in_out_unit_flow", 5),
				("unit__node__node", ("u", "n", "n"), "fix_ratio_out_in_unit_flow", 6), # Conflicting definition, let's see what happens.
			],
			:parameter_value_lists => [
				("balance_type_list", "balance_type_none"),
				("balance_type_list", "balance_type_node"),
				("balance_type_list", "balance_type_group"),
				("commodity_physics_list", "commodity_physics_lodf"),
				("commodity_physics_list", "commodity_physics_none"),
				("commodity_physics_list", "commodity_physics_ptdf"),
				("db_lp_solver_list", "HiGHS.jl"),
				("db_mip_solver_list", "Gurobi.jl"),
				("unit_online_variable_type_list", "unit_online_variable_type_binary"),
				("unit_online_variable_type_list", "unit_online_variable_type_integer"),
				("unit_online_variable_type_list", "unit_online_variable_type_linear"),
				("unit_online_variable_type_list", "unit_online_variable_type_none"),
				("connection_investment_variable_type_list", "connection_investment_variable_type_continuous"),
				("connection_investment_variable_type_list", "connection_investment_variable_type_integer"),
				("storage_investment_variable_type_list", "storage_investment_variable_type_continuous"),
				("storage_investment_variable_type_list", "storage_investment_variable_type_integer"),
				("unit_investment_variable_type_list", "unit_investment_variable_type_continuous"),
				("unit_investment_variable_type_list", "unit_investment_variable_type_integer"),
			]
		)
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, original_data)
    		if template_on_top
    			template = deepcopy(SpineOpt.template())
    			filter!(x -> x[1:2] != ["settings", "version"], template["parameter_definitions"])
    			SpineInterface.import_data(url_in, template, "Import latest template")
    		end
    		SpineOpt.major_upgrade_1(url_in, log_level) # This runs the migration.
    		migrated_data = export_data(url_in) # Export migrated data (required for examining parameter value lists)
    		Y = Bind() # Empty Bind for loading DB into.
    		using_spinedb(url_in, Y) # Load DB into the module.
    		obj_class_names = getproperty.(object_classes(Y), :name)
    		rel_class_names = getproperty.(relationship_classes(Y), :name)
    		param_names = getproperty.(parameters(Y), :name)
    		# Check that class and parameter renaming works as intended.
    		@test !in(:commodity, obj_class_names)
    		@test getproperty.(Y.grid(), :name) == [:com] # New class has the entity from the old one.
    		@test Y.lodf_tolerance(grid=Y.grid(:com)) == 1 # New class has the parameters from the old one (renamed).
    		@test !in(:commodity_lodf_tolerance, param_names) # Old parameter deleted.
    		@test Y.out_of_service_count_fix(unit=Y.unit(:u)) == 3 # Combined parameters sum.
    		@test !in(:fix_units_out_of_service, param_names) # Old parameter deleted.
    		@test !in(:units_unavailable, param_names) # Old parameter deleted.
    		@test !in(:storage_fom_cost, param_names) # Old parameter deleted.
    		storage_cost_by_alt = Dict( # Per-hour cost scaled to per-year, in every alternative.
    			x[5] => parse_db_value(x[4])
    			for x in migrated_data["parameter_values"] if x[3] == "storage_fixed_annual_cost"
    		)
    		@test storage_cost_by_alt["Base"] == 2.5 * 8760
    		@test storage_cost_by_alt["alt_ts"].values == [1.0, 2.0] .* 8760 # Indexed values scaled element-wise.
    		storage_cost_default = only( # Default value scaled too.
    			parse_db_value(x[3])
    			for x in migrated_data["parameter_definitions"] if x[1] == "node" && x[2] == "storage_fixed_annual_cost"
    		)
    		@test storage_cost_default == 0.5 * 8760
    		# Check that all necessary superclasses are created correctly.
    		@test only(Y.unit__to_node()) == (unit=Y.unit(:u), node=Y.node(:n)) # Correct entities
    		@test only(Y.node__to_unit()) == (node=Y.node(:n), unit=Y.unit(:u)) # Correct entities
    		@test !in(:unit__from_node, rel_class_names) # Old class deleted.
    		@test Y.unit_flow() == [ # Correct entities.
    			(node=Y.node(:n), unit=Y.unit(:u)),
    			(unit=Y.unit(:u), node=Y.node(:n))
    		]
    		@test Y.flow_limits_fix(node=Y.node(:n), unit=Y.unit(:u)) == 2 # Check parameter value.
    		@test Y.flow_limits_fix(unit=Y.unit(:u), node=Y.node(:n)) == 3 # Check parameter value.
    		@test !in(:fix_unit_flow, param_names) # Old parameter deleted.
    		@test Y.unit_flow__investment_group() == [ # Correct entities
    			(node=Y.node(:n), unit=Y.unit(:u), investment_group=Y.investment_group(:ig))
    		]
    		@test !in(:unit__from_node__investment_group, rel_class_names) # Old class deleted.
    		@test !in(:unit__to_node__investment_group, rel_class_names) # Old class deleted.
    		@test Y.unit_flow__user_constraint() == [ # Correct entities.
    			(node=Y.node(:n), unit=Y.unit(:u), user_constraint=Y.user_constraint(:uc)),
    			(unit=Y.unit(:u), node=Y.node(:n), user_constraint=Y.user_constraint(:uc)),
    		]
    		@test !in(:unit__from_node__user_constraint, rel_class_names) # Old class deleted.
    		@test !in(:unit__to_node__user_constraint, rel_class_names) # Old class deleted.
    		@test Y.coefficient_for_unit_flow( # Check parameter value.
    			node=Y.node(:n), unit=Y.unit(:u), user_constraint=Y.user_constraint(:uc)
    		) == 4
    		@test !in(:unit_flow_coefficient, param_names) # Old parameter deleted.
    		# Check multidimensional class parameters.
    		@test Y.flow_ratio_equality_coefficient( # Check parameter value.
    			node1=Y.node(:n), unit1=Y.unit(:u), unit2=Y.unit(:u), node2=Y.node(:n)
    		) == 5 # Only the first definition seems to end up in the db?
    		@test !in(:fix_ratio_in_out_unit_flow, param_names) # Old parameter deleted.
    		@test !in(:fix_ratio_out_in_unit_flow, param_names) # Old parameter deleted.
    		# Check classes to be removed.
    		@test !in(:unit__commodity, rel_class_names)
    		@test !in(:unit__node__node, rel_class_names) # Old class deleted.
    		# Check that parameters are removed.
    		@test !in(:include_in_non_representative_periods, param_names)
    		# Check parameter value lists, which we first need to parse.
    		parameter_value_lists = Dict()
    		for (list_name, list_value) in migrated_data["parameter_value_lists"]
    			list = get!(parameter_value_lists, list_name, [])
    			push!(list, parse_db_value(list_value))
    		end
    		@test Set(parameter_value_lists["grid_physics_list"]) == Set( # Correct list elements.
    			["none", "lodf_physics", "ptdf_physics", "voltage_angle_physics", "pressure_physics"]
    		)
    		@test !in("commodity_physics_list", keys(parameter_value_lists)) # Old list removed.
    		@test !in(:has_voltage_angle, param_names) # Converted parameter removed.
    		@test !in(:pressure_physics, param_names) # Converted parameter removed.
    		@test "HiGHS.jl" in parameter_value_lists["solver_lp_list"] # Correct list elements.
    		@test !in("db_lp_solver_list", keys(parameter_value_lists)) # Old list removed.
    		@test "Gurobi.jl" in parameter_value_lists["solver_mip_list"] # Correct list elements.
    		@test !in("db_mip_solver_list", keys(parameter_value_lists)) # Old list removed.
    		@test Set(parameter_value_lists["balance_type_list"]) == Set(
    			["none", "node_balance", "group_balance"] # Correct list elements.
    		)
    		@test Set(parameter_value_lists["variable_type_list"]) == Set(
    			["binary", "integer", "linear", "none"] # Correct list elements.
    		)
    		@test !in("connection_investment_variable_type_list", keys(parameter_value_lists)) # Old list removed.
    		@test !in("storage_investment_variable_type_list", keys(parameter_value_lists)) # Old list removed.
    		@test !in("unit_investment_variable_type_list", keys(parameter_value_lists)) # Old list removed.
    	end
    end
end

function _test_rename_storage_fixed_annual_cost()
	@testset "rename_storage_fixed_annual_cost" begin
		data = Dict(
			:object_classes => ["node"],
			:objects => [("node", "n")],
			:object_parameters => [("node", "storage_fixed_annual_cost")],
			:object_parameter_values => [("node", "n", "storage_fixed_annual_cost", 100)],
		)
		with_connection_open(url_in) do
    		_load_test_data_without_template(url_in, data)
    		@test SpineOpt.rename_storage_fixed_annual_cost(url_in, 0) === true
    		run_request(url_in, "call_method", ("commit_session", "rename_storage_fixed_annual_cost"))
    		Y = Bind()
    		using_spinedb(url_in, Y)
    		@test Y.fixed_annual_cost(node=Y.node(:n)) == 100
    		@test !in(:storage_fixed_annual_cost, getproperty.(parameters(Y), :name))
    	end
    end
end

# Parameter values of the given entity by alternative name
function _parameter_value_by_alternative(db_url, class_name, par_name, entity_byname)
	pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
		"entity_class_name" => class_name, "parameter_definition_name" => par_name)
	)
	# NOTE: Resolves values from parameter value lists, which may have been renamed in the session
	vals = SpineOpt.create_dict_from_parameter_value_items(db_url, pvals)
	Dict(get(vals, entity_byname, []))
end

# Standard output printed by `f`
function _captured_output(f)
	path, io = mktemp()
	redirect_stdout(f, io)
	close(io)
	read(path, String)
end

function _test_rename_parameter_to_existing_parameter()
	@testset "rename_parameter to an existing parameter" begin
		data = Dict(
			:object_classes => ["node"],
			:objects => [("node", "n1"), ("node", "n2")],
			:alternatives => ["alt"],
			:object_parameters => [
				("node", "storage_fom_cost", 0.5, nothing, "Old description"),
				("node", "storage_fixed_annual_cost"), # Hand-made new parameter.
			],
			:object_parameter_values => [
				("node", "n1", "storage_fom_cost", 1.0),
				("node", "n1", "storage_fom_cost", 2.0, "alt"),
				("node", "n1", "storage_fixed_annual_cost", 100.0), # Conflicts with a migrated value.
				("node", "n2", "storage_fixed_annual_cost", 200.0), # No conflict.
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.scale_parameter_values(url_in, [(("node", "storage_fom_cost"), 8760)], 0)
			SpineOpt.rename_parameter(url_in, "node", "storage_fom_cost", "storage_fixed_annual_cost", "", 0)
			pdef_old = run_request(url_in, "call_method", ("get_item", "parameter_definition"), Dict(
				"entity_class_name" => "node", "name" => "storage_fom_cost")
			)
			@test isempty(pdef_old) # Old parameter deleted.
			pdef = run_request(url_in, "call_method", ("get_item", "parameter_definition"), Dict(
				"entity_class_name" => "node", "name" => "storage_fixed_annual_cost")
			)
			@test parse_db_value(pdef["default_value"], pdef["default_type"]) == 0.5 * 8760 # Migrated default wins.
			@test pdef["description"] == "Old description"
			n1_vals = _parameter_value_by_alternative(url_in, "node", "storage_fixed_annual_cost", ["n1"])
			@test n1_vals == Dict("Base" => 1.0 * 8760, "alt" => 2.0 * 8760) # Migrated values win.
			n2_vals = _parameter_value_by_alternative(url_in, "node", "storage_fixed_annual_cost", ["n2"])
			@test n2_vals == Dict("Base" => 200.0) # Hand-made value kept, and not scaled.
		end
	end
end

function _test_update_ordering_to_existing_parameter_definition()
	@testset "update_ordering_of_multidimensional_classes to an existing parameter definition" begin
		data = Dict(
			:object_classes => ["node", "unit"],
			:relationship_classes => [("unit__from_node", ["unit", "node"]), ("node__to_unit", ["node", "unit"])],
			:relationship_parameters => [
				("unit__from_node", "unit_capacity", 1.0, nothing, "Old description"),
				("node__to_unit", "unit_capacity", 2.0, nothing, "Hand-made description"),
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.update_ordering_of_multidimensional_classes(
				url_in, [("unit__from_node", "node__to_unit", ["node", "unit"], [2, 1], true)], 0
			)
			pdef = run_request(url_in, "call_method", ("get_item", "parameter_definition"), Dict(
				"entity_class_name" => "node__to_unit", "name" => "unit_capacity")
			)
			@test parse_db_value(pdef["default_value"], pdef["default_type"]) == 1.0 # Migrated definition wins.
			@test pdef["description"] == "Old description"
		end
	end
end

function _test_rename_storage_fixed_annual_cost_to_existing_parameter()
	@testset "rename_storage_fixed_annual_cost to an existing fixed_annual_cost" begin
		data = Dict(
			:object_classes => ["node"],
			:objects => [("node", "n1"), ("node", "n2")],
			:object_parameters => [("node", "storage_fixed_annual_cost"), ("node", "fixed_annual_cost")],
			:object_parameter_values => [
				("node", "n1", "storage_fixed_annual_cost", 100),
				("node", "n1", "fixed_annual_cost", 1), # Conflicts with the migrated value.
				("node", "n2", "fixed_annual_cost", 2), # No conflict.
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			@test SpineOpt.rename_storage_fixed_annual_cost(url_in, 0) === true
			run_request(url_in, "call_method", ("commit_session", "rename_storage_fixed_annual_cost"))
			Y = Bind()
			using_spinedb(url_in, Y)
			@test !in(:storage_fixed_annual_cost, getproperty.(parameters(Y), :name))
			@test Y.fixed_annual_cost(node=Y.node(:n1)) == 100
			@test Y.fixed_annual_cost(node=Y.node(:n2)) == 2
		end
	end
end

function _test_update_ordering_to_existing_entities()
	@testset "update_ordering_of_multidimensional_classes to existing entities" begin
		data = Dict(
			:object_classes => ["node", "unit"],
			:objects => [("node", "n1"), ("node", "n2"), ("unit", "u")],
			:relationship_classes => [("unit__from_node", ["unit", "node"]), ("node__to_unit", ["node", "unit"])],
			:relationships => [
				("unit__from_node", ["u", "n1"]),
				("unit__from_node", ["u", "n2"]),
				("node__to_unit", ["n1", "u"]), # Hand-made, also migrated.
				("node__to_unit", ["n2", "u"]), # Hand-made, also migrated.
			],
			:relationship_parameters => [("unit__from_node", "vom_cost"), ("node__to_unit", "vom_cost")],
			:relationship_parameter_values => [
				("unit__from_node", ["u", "n1"], "vom_cost", 1.0),
				("unit__from_node", ["u", "n2"], "vom_cost", 2.0),
				("node__to_unit", ["n1", "u"], "vom_cost", 10.0), # Conflicts with a migrated value.
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.update_ordering_of_multidimensional_classes(
				url_in, [("unit__from_node", "node__to_unit", ["node", "unit"], [2, 1], true)], 0
			)
			@test SpineOpt.entity_bynames(url_in, "node__to_unit") == Set([["n1", "u"], ["n2", "u"]])
			@test isempty(run_request(url_in, "call_method", ("get_entity_class_item",), Dict("name" => "unit__from_node")))
			# All values migrated, also after the first already existing entity; migrated values win.
			@test _parameter_value_by_alternative(url_in, "node__to_unit", "vom_cost", ["n1", "u"]) == Dict("Base" => 1.0)
			@test _parameter_value_by_alternative(url_in, "node__to_unit", "vom_cost", ["n2", "u"]) == Dict("Base" => 2.0)
		end
	end
end

function _test_move_parameter_to_existing_grid()
	@testset "move_parameter with and without existing grid entities" begin
		data = Dict(
			:object_classes => ["node", "grid"],
			:relationship_classes => [("node__grid", ["node", "grid"])],
			:objects => [("node", "n1"), ("node", "n2"), ("grid", "n2")], # Grid `n2` is hand-made.
			:relationships => [("node__grid", ["n2", "n2"])],
			:object_parameters => [("node", "has_voltage_angle"), ("grid", "physics_type")],
			:object_parameter_values => [
				("node", "n1", "has_voltage_angle", true),
				("node", "n2", "has_voltage_angle", false),
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.move_parameter(url_in, 0, "has_voltage_angle", "voltage_angle_physics", 3)
			@test SpineOpt.entity_bynames(url_in, "grid") == Set([["n1"], ["n2"]])
			@test SpineOpt.entity_bynames(url_in, "node__grid") == Set([["n1", "n1"], ["n2", "n2"]])
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["n1"]) == Dict(
				"Base" => "voltage_angle_physics"
			)
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["n2"]) == Dict("Base" => "none")
			pdef = run_request(url_in, "call_method", ("get_item", "parameter_definition"), Dict(
				"entity_class_name" => "node", "name" => "has_voltage_angle")
			)
			@test isempty(pdef)
		end
	end
end

function _test_create_superclasses_and_subclasses_with_existing_classes()
	@testset "create_superclasses_and_subclasses with existing classes" begin
		data = Dict(
			:object_classes => ["node", "unit", "unit_flow"], # `unit_flow` hand-made.
			:relationship_classes => [
				("node__to_unit", ["node", "unit"]), # Hand-made, with the right dimensions.
				("unit_flow__unit_flow", ["unit", "unit"]), # Hand-made, with wrong dimensions.
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.create_superclasses_and_subclasses(url_in, 0)
			classes = Dict(
				x["name"] => collect(x["dimension_name_list"])
				for x in run_request(url_in, "call_method", ("get_entity_class_items",), Dict())
			)
			@test classes["unit__to_node"] == ["unit", "node"]
			@test classes["node__to_unit"] == ["node", "unit"]
			@test classes["unit_flow"] == []
			@test classes["unit_flow__unit_flow"] == ["unit_flow", "unit_flow"] # Replaced.
			@test classes["unit_flow__investment_group"] == ["unit_flow", "investment_group"]
			@test classes["unit_flow__user_constraint"] == ["unit_flow", "user_constraint"]
			superclass_subclass = Set(
				(x["superclass_name"], x["subclass_name"])
				for x in run_request(url_in, "call_method", ("get_superclass_subclass_items",), Dict())
			)
			@test superclass_subclass == Set([("unit_flow", "node__to_unit"), ("unit_flow", "unit__to_node")])
		end
	end
end

function _test_rename_classes_to_existing_class()
	@testset "rename_classes to an existing class" begin
		data = Dict(
			:object_classes => ["commodity", "grid"], # `grid` hand-made.
			:objects => [("commodity", "c1"), ("commodity", "c2"), ("grid", "c1"), ("grid", "g")],
			:object_parameters => [("commodity", "commodity_lodf_tolerance"), ("grid", "commodity_lodf_tolerance")],
			:object_parameter_values => [
				("commodity", "c1", "commodity_lodf_tolerance", 0.1),
				("commodity", "c2", "commodity_lodf_tolerance", 0.2),
				("grid", "c1", "commodity_lodf_tolerance", 1.0), # Conflicts with a migrated value.
				("grid", "g", "commodity_lodf_tolerance", 2.0), # No conflict.
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.rename_classes(url_in, [("commodity", "grid")], 0)
			@test isempty(run_request(url_in, "call_method", ("get_entity_class_item",), Dict("name" => "commodity")))
			@test SpineOpt.entity_bynames(url_in, "grid") == Set([["c1"], ["c2"], ["g"]])
			@test _parameter_value_by_alternative(url_in, "grid", "commodity_lodf_tolerance", ["c1"]) == Dict("Base" => 0.1)
			@test _parameter_value_by_alternative(url_in, "grid", "commodity_lodf_tolerance", ["c2"]) == Dict("Base" => 0.2)
			@test _parameter_value_by_alternative(url_in, "grid", "commodity_lodf_tolerance", ["g"]) == Dict("Base" => 2.0)
		end
	end
end

# Values of the given parameter value list, in order
_list_values(db_url, list_name) = [
	parse_db_value(x["value"], x["type"])
	for x in sort(
		run_request(db_url, "call_method", ("find_list_values",), Dict("parameter_value_list_name" => list_name));
		by=x -> x["index"],
	)
]

function _test_rename_pval_list_to_existing_list()
	@testset "rename_parameter_value_lists to an existing list" begin
		data = Dict(
			:object_classes => ["grid"],
			:objects => [("grid", "g1"), ("grid", "g2")],
			:parameter_value_lists => [
				("commodity_physics_list", "commodity_physics_lodf"),
				("commodity_physics_list", "commodity_physics_none"),
				("grid_physics_list", "lodf_physics"), # Hand-made, already with new values.
				("grid_physics_list", "none"),
			],
			:object_parameters => [
				("grid", "physics_type", nothing, "commodity_physics_list"),
				("grid", "hand_made_physics", nothing, "grid_physics_list"),
			],
			:object_parameter_values => [
				("grid", "g1", "physics_type", "commodity_physics_lodf"),
				("grid", "g2", "physics_type", "commodity_physics_none"),
				("grid", "g1", "hand_made_physics", "lodf_physics"),
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.rename_parameter_value_lists(url_in, [("commodity_physics_list", "grid_physics_list")], 0)
			SpineOpt.rename_list_values(url_in, [("grid_physics_list", Dict(
				"commodity_physics_lodf" => "lodf_physics",
				"commodity_physics_none" => "none",
				"commodity_physics_ptdf" => "ptdf_physics",
			))], 0)
			lists = [x["name"] for x in run_request(url_in, "call_method", ("get_parameter_value_list_items",), Dict())]
			@test lists == ["grid_physics_list"]
			@test _list_values(url_in, "grid_physics_list") == ["lodf_physics", "none"] # Duplicates merged.
			for par in ("physics_type", "hand_made_physics")
				pdef = run_request(url_in, "call_method", ("get_item", "parameter_definition"), Dict(
					"entity_class_name" => "grid", "name" => par)
				)
				@test pdef["parameter_value_list_name"] == "grid_physics_list"
			end
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["g1"]) == Dict("Base" => "lodf_physics")
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["g2"]) == Dict("Base" => "none")
			@test _parameter_value_by_alternative(url_in, "grid", "hand_made_physics", ["g1"]) == Dict(
				"Base" => "lodf_physics"
			)
		end
	end
end

function _test_merge_variable_type_lists_with_existing_list()
	@testset "merge_variable_type_lists with an existing variable_type_list in use" begin
		data = Dict(
			:object_classes => ["unit"],
			:objects => [("unit", "u")],
			:parameter_value_lists => [
				("unit_online_variable_type_list", "unit_online_variable_type_binary"),
				("unit_online_variable_type_list", "unit_online_variable_type_integer"),
				("unit_online_variable_type_list", "unit_online_variable_type_linear"),
				("unit_online_variable_type_list", "unit_online_variable_type_none"),
				("variable_type_list", "linear"), # Hand-made.
				("variable_type_list", "integer"),
			],
			:object_parameters => [
				("unit", "online_variable_type", "unit_online_variable_type_linear", "unit_online_variable_type_list"),
				("unit", "hand_made_variable_type", nothing, "variable_type_list"),
			],
			:object_parameter_values => [
				("unit", "u", "online_variable_type", "unit_online_variable_type_binary"),
				("unit", "u", "hand_made_variable_type", "integer"),
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			SpineOpt.merge_variable_type_lists(url_in, 0) # Used to throw an error.
			lists = [x["name"] for x in run_request(url_in, "call_method", ("get_parameter_value_list_items",), Dict())]
			@test lists == ["variable_type_list"]
			@test Set(_list_values(url_in, "variable_type_list")) == Set(["binary", "integer", "linear", "none"])
			@test _parameter_value_by_alternative(url_in, "unit", "online_variable_type", ["u"]) == Dict("Base" => "binary")
			@test _parameter_value_by_alternative(url_in, "unit", "hand_made_variable_type", ["u"]) == Dict(
				"Base" => "integer"
			)
		end
	end
end

function _test_hand_made_list_values_in_migration()
	@testset "hand-made parameter values from a parameter value list during migration" begin
		data = Dict(
			:object_classes => ["commodity", "grid"], # `grid` hand-made.
			:objects => [("commodity", "elec"), ("grid", "h2"), ("grid", "gas")],
			:parameter_value_lists => [
				("commodity_physics_list", "commodity_physics_lodf"),
				("commodity_physics_list", "commodity_physics_none"),
				("commodity_physics_list", "commodity_physics_ptdf"),
				("grid_physics_list", "lodf_physics"), # Hand-made, with an invalid value.
				("grid_physics_list", "bogus_physics"),
			],
			:object_parameters => [
				("commodity", "commodity_physics", nothing, "commodity_physics_list"),
				("grid", "physics_type", nothing, "grid_physics_list"), # Hand-made.
			],
			:object_parameter_values => [
				("commodity", "elec", "commodity_physics", "commodity_physics_ptdf"),
				("grid", "h2", "physics_type", "lodf_physics"), # Valid only after renaming the list values.
				("grid", "gas", "physics_type", "bogus_physics"), # Never valid.
			],
		)
		with_connection_open(url_in) do
			_load_test_data_without_template(url_in, data)
			output = _captured_output() do
				SpineOpt.rename_parameter(url_in, "commodity", "commodity_physics", "physics_type", "", 0)
				SpineOpt.rename_classes(url_in, [("commodity", "grid")], 0)
				SpineOpt.rename_parameter_value_lists(url_in, [("commodity_physics_list", "grid_physics_list")], 0)
				SpineOpt.rename_list_values(url_in, [("grid_physics_list", Dict(
					"commodity_physics_lodf" => "lodf_physics",
					"commodity_physics_none" => "none",
					"commodity_physics_ptdf" => "ptdf_physics",
				))], 0)
				SpineOpt.warn_about_values_not_in_template_lists(url_in, 0)
			end
			# All values are kept.
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["elec"]) == Dict("Base" => "ptdf_physics")
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["h2"]) == Dict("Base" => "lodf_physics")
			@test _parameter_value_by_alternative(url_in, "grid", "physics_type", ["gas"]) == Dict("Base" => "bogus_physics")
			@test Set(_list_values(url_in, "grid_physics_list")) == Set(
				["lodf_physics", "none", "ptdf_physics", "bogus_physics"]
			)
			# Only the invalid value is reported, with its parameter, class, entity and alternative.
			@test occursin(
				"The value `bogus_physics` of `physics_type` for the `grid` entity (\"gas\",) in alternative `Base` " *
				"is not valid in the parameter value list `grid_physics_list`",
				output,
			)
			@test !occursin("The value `lodf_physics`", output)
			@test !occursin("The value `ptdf_physics`", output)
		end
	end
end

@testset "migration scripts" begin
	_test_rename_unit_constraint_to_user_constraint()
	_test_move_connection_flow_cost()
	_test_rename_model_types()
	_test_translate_ramp_parameters()
	_test_remove_model_tb_ss()
	_test_update_investment_variable_type()
	_test_add_model_algorithm()
	_test_rename_lifetime_to_tech_lifetime()
	_test_translate_heatrate_parameters()
	_test_translate_use_economic_representation__use_milestone_years()
	_test_dummy_migrations_functions()
	_test_major_upgrade_1()
	_test_major_upgrade_1(; template_on_top=true)
	_test_rename_storage_fixed_annual_cost()
	# Migrations into already existing (e.g. hand-made) items
	_test_rename_parameter_to_existing_parameter()
	_test_update_ordering_to_existing_parameter_definition()
	_test_rename_storage_fixed_annual_cost_to_existing_parameter()
	_test_update_ordering_to_existing_entities()
	_test_move_parameter_to_existing_grid()
	_test_create_superclasses_and_subclasses_with_existing_classes()
	_test_rename_classes_to_existing_class()
	_test_rename_pval_list_to_existing_list()
	_test_merge_variable_type_lists_with_existing_list()
	_test_hand_made_list_values_in_migration()
end
