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

@testset "stochastic structure" begin
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["node", "only_node"],
            ["unit", "only_unit"],
            ["temporal_block", "only_block"],
            ["stochastic_structure", "structure_a"],
            ["stochastic_structure", "structure_b"],
            ["stochastic_scenario", "scenario_a"],
            ["stochastic_scenario", "scenario_a1"],
            ["stochastic_scenario", "scenario_a2"],
            ["stochastic_scenario", "scenario_b"],
            ["stochastic_scenario", "scenario_b1"],
            ["stochastic_scenario", "scenario_b2"],
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "only_block"]],
            ["model__stochastic_structure", ["instance", "structure_a"]],
            ["model__stochastic_structure", ["instance", "structure_b"]],
            ["node__temporal_block", ["only_node", "only_block"]],
            ["node__stochastic_structure", ["only_node", "structure_a"]],
            ["units_on__temporal_block", ["only_unit", "only_block"]],
            ["units_on__stochastic_structure", ["only_unit", "structure_b"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["scenario_a", "scenario_a1"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["scenario_a", "scenario_a2"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["scenario_b", "scenario_b1"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["scenario_b", "scenario_b2"]],
            ["stochastic_structure__stochastic_scenario", ["structure_a", "scenario_a"]],
            ["stochastic_structure__stochastic_scenario", ["structure_a", "scenario_a1"]],
            ["stochastic_structure__stochastic_scenario", ["structure_a", "scenario_a2"]],
            ["stochastic_structure__stochastic_scenario", ["structure_a", "scenario_b"]],
            ["stochastic_structure__stochastic_scenario", ["structure_a", "scenario_b1"]],
            ["stochastic_structure__stochastic_scenario", ["structure_a", "scenario_b2"]],
            ["stochastic_structure__stochastic_scenario", ["structure_b", "scenario_b"]],
            ["stochastic_structure__stochastic_scenario", ["structure_b", "scenario_b1"]],
            ["stochastic_structure__stochastic_scenario", ["structure_b", "scenario_b2"]],
            ["stochastic_structure__stochastic_scenario", ["structure_b", "scenario_a"]],
            ["stochastic_structure__stochastic_scenario", ["structure_b", "scenario_a1"]],
            ["stochastic_structure__stochastic_scenario", ["structure_b", "scenario_a2"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-04T00:00:00")],
            ["temporal_block", "only_block", "resolution", Dict("type" => "duration", "data" => "1D")],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_a"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1D"),
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_a"],
                "weight_relative_to_parents",
                1.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_a1"],
                "weight_relative_to_parents",
                1.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_a2"],
                "weight_relative_to_parents",
                2.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_b"],
                "weight_relative_to_parents",
                0.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_b1"],
                "weight_relative_to_parents",
                0.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_a", "scenario_b2"],
                "weight_relative_to_parents",
                0.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_b"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "2D"),
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_b"],
                "weight_relative_to_parents",
                2.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_b1"],
                "weight_relative_to_parents",
                0.1,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_b2"],
                "weight_relative_to_parents",
                0.2,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_a"],
                "weight_relative_to_parents",
                0.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_a1"],
                "weight_relative_to_parents",
                0.0,
            ],
            [
                "stochastic_structure__stochastic_scenario",
                ["structure_b", "scenario_a2"],
                "weight_relative_to_parents",
                0.0,
            ],
        ],
    )
    db_map = _load_test_data(url_in, test_data)
    using_spinedb(db_map, SpineOpt)
    db_map.commit_session("Add test data")
    m = run_spineopt(db_map, log_level=0, optimize=false)

    @testset "node_stochastic_time_indices" begin
        @test length(node_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_a))) == 1
        @test length(node_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_a1))) == 2
        @test length(node_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_a2))) == 2
        @test length(node_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_b))) == 3
        @test isempty(node_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_b1)))
        @test isempty(node_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_b2)))
        @test length(node_stochastic_time_indices(m)) == 8
    end
    @testset "unit_stochastic_time_indices" begin
        @test length(unit_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_a))) == 3
        @test isempty(unit_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_a1)))
        @test isempty(unit_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_a2)))
        @test length(unit_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_b))) == 2
        @test length(unit_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_b1))) == 1
        @test length(unit_stochastic_time_indices(m; stochastic_scenario=stochastic_scenario(:scenario_b2))) == 1
        @test length(unit_stochastic_time_indices(m)) == 7
    end
    @testset "node_stochastic_scenario_weight" begin
        @test realize(SpineOpt.node_stochastic_scenario_weight(
            m;
            node=node(:only_node),
            stochastic_scenario=stochastic_scenario(:scenario_a),
        )) == 1.0
        @test realize(SpineOpt.node_stochastic_scenario_weight(
            m;
            node=node(:only_node),
            stochastic_scenario=stochastic_scenario(:scenario_a1),
        )) == 1.0
        @test realize(SpineOpt.node_stochastic_scenario_weight(
            m;
            node=node(:only_node),
            stochastic_scenario=stochastic_scenario(:scenario_a2),
        )) == 2.0
        @test realize(SpineOpt.node_stochastic_scenario_weight(
            m;
            node=node(:only_node),
            stochastic_scenario=stochastic_scenario(:scenario_b),
        )) == 0.0
    end
    @testset "unit_stochastic_scenario_weight" begin
        @test realize(SpineOpt.unit_stochastic_scenario_weight(
            m;
            unit=unit(:only_unit),
            stochastic_scenario=stochastic_scenario(:scenario_b),
        )) == 2.0
        @test realize(SpineOpt.unit_stochastic_scenario_weight(
            m;
            unit=unit(:only_unit),
            stochastic_scenario=stochastic_scenario(:scenario_b1),
        )) == 0.2
        @test realize(SpineOpt.unit_stochastic_scenario_weight(
            m;
            unit=unit(:only_unit),
            stochastic_scenario=stochastic_scenario(:scenario_b2),
        )) == 0.4
        @test realize(SpineOpt.unit_stochastic_scenario_weight(
            m;
            unit=unit(:only_unit),
            stochastic_scenario=stochastic_scenario(:scenario_a),
        )) == 0.0
    end
end
