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

using SpineOpt
using SpineInterface
using Test
using Dates
using JuMP


function _load_template(url_in)
	db_api.create_new_spine_database(url_in)
	template = Dict(Symbol(key) => value for (key, value) in SpineOpt.template)
	db_api.import_data_to_url(url_in; template...)
end

_is_constraint_equal(con1, con2) = con1.func == con2.func && con1.set == con2.set


@testset "Generate unit-related constraints" begin
	url_in = "sqlite:///$(@__DIR__)/test.sqlite"
	test_data = Dict(
		:objects => [
			["model", "instance"], 
			["temporal_block", "hourly"],
			["temporal_block", "two_hourly"],
			["stochastic_structure", "deterministic"],
			["stochastic_structure", "stochastic"],
			["unit", "test_unit"],
			["node", "from_node"],
			["node", "to_node"],
			["stochastic_scenario", "parent"],
			["stochastic_scenario", "child"],
		],
		:relationships => [
			["units_on_resolution", ["test_unit", "from_node"]],
			["unit__from_node", ["test_unit", "from_node"]],
			["unit__to_node", ["test_unit", "to_node"]],
			["node__temporal_block", ["from_node", "hourly"]],
			["node__temporal_block", ["to_node", "two_hourly"]],
			["node__stochastic_structure", ["from_node", "stochastic"]],
			["node__stochastic_structure", ["to_node", "deterministic"]],
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
	@testset "constraint_units_on" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
	    m = run_spineopt(url_in; log_level=0)
		var_units_on = m.ext[:variables][:units_on]
		var_units_available = m.ext[:variables][:units_available]
	    constraint = m.ext[:constraints][:units_on]
	    @test length(constraint) == 2
	    scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
	    time_slices = time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=unit(:test_unit))))
	    @testset for (s, t) in zip(scenarios, time_slices)
		    key = (unit(:test_unit), s, t)
		    var_u_on = var_units_on[key...]
		    var_u_av = var_units_available[key...]
		    expected_con = @build_constraint(var_u_on <= var_u_av)
		    con_u_on = constraint[key]
		    observed_con = constraint_object(con_u_on)
		    @test _is_constraint_equal(observed_con, expected_con)
		end
	end
	@testset "constraint_units_available" begin
		# TODO: investments
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		number_of_units = 4
		db_api.import_data_to_url(
			url_in; object_parameter_values=[["unit", "test_unit", "number_of_units", number_of_units]]
		)
	    m = run_spineopt(url_in; log_level=0)
		var_units_available = m.ext[:variables][:units_available]
	    constraint = m.ext[:constraints][:units_available]
	    @test length(constraint) == 2
	    scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
	    time_slices = time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=unit(:test_unit))))
	    @testset for (s, t) in zip(scenarios, time_slices)
		    key = (unit(:test_unit), s, t)
		    var = var_units_available[key...]
		    expected_con = @build_constraint(var == number_of_units)
		    con = constraint[key]
		    observed_con = constraint_object(con)
		    @test _is_constraint_equal(observed_con, expected_con)
	    end
	end
	@testset "constraint_unit_state_transition" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
	    m = run_spineopt(url_in; log_level=0)
		var_units_on = m.ext[:variables][:units_on]
		var_units_started_up = m.ext[:variables][:units_started_up]
		var_units_shut_down = m.ext[:variables][:units_shut_down]
	    constraint = m.ext[:constraints][:unit_state_transition]
	    @test length(constraint) == 2
	    scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
	    time_slices = time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=unit(:test_unit))))
	    @testset for (s1, t1) in zip(scenarios, time_slices)
		    t0 = first(t_before_t(t_after=t1))
		    s0 = first(parent_stochastic_scenario__child_stochastic_scenario(stochastic_scenario2=s1, _default=[s1]))
		    path = unique([s0, s1])
		    con_key = (unit(:test_unit), path, t0, t1)
		    var_key0 = (unit(:test_unit), s0, t0)
		    var_key1 = (unit(:test_unit), s1, t1)
		    var_u_on0 = get(var_units_on, var_key0, 0)
		    var_u_on1 = var_units_on[var_key1...]
		    var_u_su1 = var_units_started_up[var_key1...]
		    var_u_sd1 = var_units_shut_down[var_key1...]
		    expected_con = @build_constraint(var_u_on1 - var_u_on0 == var_u_su1 - var_u_sd1)
		    observed_con = constraint_object(constraint[con_key])
		    @test _is_constraint_equal(observed_con, expected_con)
		end
	end
	@testset "constraint_unit_flow_capacity" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		unit_capacity = 100
		relationship_parameter_values = [["unit__from_node", ["test_unit", "from_node"], "unit_capacity", unit_capacity]]
		db_api.import_data_to_url(url_in; relationship_parameter_values=relationship_parameter_values)
	    m = run_spineopt(url_in; log_level=0)
	    constraint = m.ext[:constraints][:unit_flow_capacity]	    
		var_unit_flow = m.ext[:variables][:unit_flow]
		var_units_on = m.ext[:variables][:units_on]   
	    scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
	    time_slices = time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=unit(:test_unit))))
	    @testset for (s, t) in zip(scenarios, time_slices)
			con_key = (unit(:test_unit), node(:from_node), direction(:from_node), [s], t)
			var_u_flow_key = (unit(:test_unit), node(:from_node), direction(:from_node), s, t)
			var_u_on_key = (unit(:test_unit), s, t)
			var_u_flow = var_unit_flow[var_u_flow_key...]
			var_u_on = var_units_on[var_u_on_key...]
		    expected_con = @build_constraint(var_u_flow <= unit_capacity * var_u_on)
		    observed_con = constraint_object(constraint[con_key])
		    @test _is_constraint_equal(observed_con, expected_con)
	    end
	end
end
