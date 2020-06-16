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

@testset "Check data structure" begin
	url_in = "sqlite:///$(@__DIR__)/test.sqlite"
	_load_template(url_in)
	# TODO: Once we get our error messages right, we should use:
	# @test_throws ErrorException("...exception message...") m = run_spineopt(url_in; log_level=0)
	# to make sure that the test passes for the good reasons.
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0)
	db_api.import_data_to_url(url_in; objects=[["model", "instance"]])
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0)
	db_api.import_data_to_url(
		url_in; 
		objects=[["temporal_block", "test_temporal_block"], ["unit", "test_unit"], ["node", "test_node"]]
	)
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0)
	db_api.import_data_to_url(
		url_in; 
		relationships=[["units_on_resolution", ["test_unit", "test_node"]]]
	)
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0)
end

@testset "Generate unit_flow variables" begin
	url_in = "sqlite:///$(@__DIR__)/test.sqlite"
	_load_template(url_in)
	test_data = Dict(
		:objects => [
			["model", "instance"], 
			["temporal_block", "test_temporal_block"],
			["stochastic_structure", "test_stochastic_structure"],
			["unit", "test_unit"],
			["node", "test_node"],
			["stochastic_scenario", "test_stochastic_scenario"]
		],
		:relationships => [
			["units_on_resolution", ["test_unit", "test_node"]],
			["unit__to_node", ["test_unit", "test_node"]],
			["node__temporal_block", ["test_node", "test_temporal_block"]],
			["node__stochastic_structure", ["test_node", "test_stochastic_structure"]],
			["stochastic_structure__stochastic_scenario", ["test_stochastic_structure", "test_stochastic_scenario"]],
		]
	)
	db_api.import_data_to_url(url_in; test_data...)
    m = run_spineopt(url_in; log_level=0)
    @test length(unit_flow_indices()) == 1
    u, n, d, s, t = first(unit_flow_indices())
    @test u.name == :test_unit
    @test n.name == :test_node
    @test d.name == :to_node
    @test s.name == :test_stochastic_scenario
    @test start(t) == DateTime(2000)
    @test end_(t) == DateTime(2000, 1, 1, 1, 0, 0)
end

include("constraints.jl")
