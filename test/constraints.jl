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
	    t = first(time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=unit(:test_unit)))))
	    key = (unit(:test_unit), stochastic_scenario(:parent), t)
	    var_units_on = m.ext[:variables][:units_on]
	    var_units_available = m.ext[:variables][:units_available]
	    var_u_on = var_units_on[key...]
	    var_u_av = var_units_available[key...]
	    expected_con = @build_constraint(var_u_on <= var_u_av)
	    con_u_on = m.ext[:constraints][:units_on][key]
	    observed_con = constraint_object(con_u_on)
	    @test _is_constraint_equal(observed_con, expected_con)
	end
	@testset "constraint_units_available" begin
		# TODO: investments
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		number_of_units = 4
		db_api.import_data_to_url(url_in; object_parameter_values=[["unit", "test_unit", "number_of_units", number_of_units]])
	    m = run_spineopt(url_in; log_level=0)
	    t = first(time_slice(temporal_block=node__temporal_block(node=units_on_resolution(unit=unit(:test_unit)))))
	    key = (unit(:test_unit), stochastic_scenario(:parent), t)
	    var = m.ext[:variables][:units_available][key...]
	    expected_con = @build_constraint(var == number_of_units)
	    con = m.ext[:constraints][:units_available][key]
	    observed_con = constraint_object(con)
	    @test _is_constraint_equal(observed_con, expected_con)
	end
	@testset "constraint_unit_state_transition" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
	    m = run_spineopt(url_in; log_level=0)
	    t1 = last(time_slice(temporal_block=temporal_block(:hourly)))
	    t0 = first(t_before_t(t_after=t1))
	    con_key = (unit(:test_unit), [stochastic_scenario(:parent), stochastic_scenario(:child)], t0, t1)
	    var_t0_key = (unit(:test_unit), stochastic_scenario(:parent), t0)
	    var_t1_key = (unit(:test_unit), stochastic_scenario(:child), t1)
	    var_units_on = m.ext[:variables][:units_on]
	    var_units_started_up = m.ext[:variables][:units_started_up]
	    var_units_shut_down = m.ext[:variables][:units_shut_down]
	    var_u_on_t0 = var_units_on[var_t0_key...]
	    var_u_on_t1 = var_units_on[var_t1_key...]
	    var_u_su_t1 = var_units_started_up[var_t1_key...]
	    var_u_sd_t1 = var_units_shut_down[var_t1_key...]
	    expected_con = @build_constraint(var_u_on_t1 - var_u_on_t0 == var_u_su_t1 - var_u_sd_t1)
	    observed_con = constraint_object(m.ext[:constraints][:unit_state_transition][con_key])
	    @test _is_constraint_equal(observed_con, expected_con)
	end
end
