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

import DelimitedFiles: readdlm

@testset "misc" begin
    url_in = "sqlite://"
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
        :relationship_parameter_values => [[
            "stochastic_structure__stochastic_scenario",
            ["stochastic", "parent"],
            "stochastic_scenario_end",
            Dict("type" => "duration", "data" => "1h"),
        ]],
    )
    @testset "write_ptdf_lodf" begin
        conn_r = 0.9
        conn_x = 0.1
        conn_emergency_cap_ab = 80
        conn_emergency_cap_bc = 100
        conn_emergency_cap_ca = 150
        _load_test_data(url_in, test_data)
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
            ["connection", "connection_ab", "connection_monitored", true],
            ["connection", "connection_ab", "connection_reactance", conn_x],
            ["connection", "connection_ab", "connection_resistance", conn_r],
            ["connection", "connection_bc", "connection_monitored", true],
            ["connection", "connection_bc", "connection_reactance", conn_x],
            ["connection", "connection_bc", "connection_resistance", conn_r],
            ["connection", "connection_ca", "connection_monitored", true],
            ["connection", "connection_ca", "connection_reactance", conn_x],
            ["connection", "connection_ca", "connection_resistance", conn_r],
            ["commodity", "electricity", "commodity_physics", "commodity_physics_lodf"],
            ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
            ["connection", "connection_ca", "connection_contingency", true],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ]
        relationship_parameter_values = [
            ["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ca", "node_a", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ca", "node_c", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            [
                "connection__from_node",
                ["connection_ab", "node_a"],
                "connection_emergency_capacity",
                conn_emergency_cap_ab,
            ],
            [
                "connection__from_node",
                ["connection_bc", "node_b"],
                "connection_emergency_capacity",
                conn_emergency_cap_bc,
            ],
            [
                "connection__from_node",
                ["connection_ca", "node_c"],
                "connection_emergency_capacity",
                conn_emergency_cap_ca,
            ],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        using_spinedb(url_in, SpineOpt)
        SpineOpt.generate_direction()
        SpineOpt.generate_ptdf_lodf()
        SpineOpt.write_ptdfs()
        ptdfs = readdlm("ptdfs.csv", ',', Any, '\n')
        @test ptdfs[1, 1:(end - 1)] == ["connection", "node_a", "node_b", "node_c"]
        @test ptdfs[:, 1] == ["connection", "connection_ab", "connection_bc", "connection_ca"]
        @test isapprox(
            convert(Array{Float64,2}, ptdfs[2:end, 2:(end - 1)]),
            [
                0.0 -0.666666 -0.333333
                0.0 0.333333 -0.333333
                0.0 -0.333333 -0.666667
            ];
            atol=1e-5,
        )
        SpineOpt.write_lodfs()
        lodfs = readdlm("lodfs.csv", ',', Any, '\n')
        @test convert(Array{String,1}, lodfs[1, 1:(end - 1)]) ==
              ["contingency line", "from_node", "to node", "connection_ab", "connection_bc", "connection_ca"]
        @test convert(Array{String,1}, lodfs[:, 1]) == ["contingency line", "connection_ca"]
        @test isapprox(convert(Array{Float64,1}, lodfs[2, 4:(end - 2)]), [1, 1])
    end
end
