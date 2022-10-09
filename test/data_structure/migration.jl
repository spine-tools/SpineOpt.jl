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
@testset "migration scripts" begin
	@testset "rename_unit_constraint_to_user_constraint" begin
	end
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
