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

@testset "postprocess_results" begin
    @testset "save_connection_avg_throughflow" begin
        url_in = "sqlite://"
        test_data = Dict(
            :objects => [
                ["model", "instance"],
                ["temporal_block", "hourly"],
                ["stochastic_structure", "stochastic"],
                ["connection", "connection_ab"],
                ["node", "node_a"],
                ["node", "node_b"],
                ["stochastic_scenario", "parent"],
                ["stochastic_scenario", "child"],
                ["commodity", "electricity"],
                ["report", "report_x"],
                ["output", "connection_avg_intact_throughflow"],
            ],
            :relationships => [
                ["connection__from_node", ["connection_ab", "node_a"]],
                ["connection__to_node", ["connection_ab", "node_b"]],
                ["model__temporal_block", ["instance", "hourly"]],
                ["model__stochastic_structure", ["instance", "stochastic"]],
                ["node__temporal_block", ["node_a", "hourly"]],
                ["node__temporal_block", ["node_b", "hourly"]],
                ["node__stochastic_structure", ["node_a", "stochastic"]],
                ["node__stochastic_structure", ["node_b", "stochastic"]],
                ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
                ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
                ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
                ["node__commodity", ["node_a", "electricity"]],
                ["node__commodity", ["node_b", "electricity"]],
                ["report__output", ["report_x", "connection_avg_intact_throughflow"]],
            ],
            :object_parameter_values => [
                ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
                ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
                ["model", "instance", "duration_unit", "hour"],
                ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
                ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"],
                ["connection", "connection_ab", "connection_monitored", true],
                ["connection", "connection_ab", "connection_reactance", 0.1],
                ["connection", "connection_ab", "connection_resistance", 0.9],
                ["commodity", "electricity", "commodity_physics", "commodity_physics_ptdf"],
                ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
                ["node", "node_a", "demand", -100],
                ["node", "node_b", "demand", 100],
                ["output","connection_avg_intact_throughflow", "output_resolution", Dict("type" => "duration", "data" => "2h")],
                ["model", "instance", "db_mip_solver", "Cbc.jl"],
                ["model", "instance", "db_lp_solver", "Clp.jl"],
            ],
            :relationship_parameter_values => [[
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ]],
        )
        _load_test_data(url_in, test_data)
        m = run_spineopt(url_in, "sqlite://"; log_level=0)
        connection_avg_throughflow = m.ext[:spineopt].values[:connection_avg_intact_throughflow]
        @test length(connection_avg_throughflow) == 2
        t1, t2 = time_slice(m; temporal_block=temporal_block(:hourly))
        key = (connection=connection(:connection_ab), node=node(:node_b))
        key1 = (key..., stochastic_scenario=stochastic_scenario(:parent), t=t1)
        key2 = (key..., stochastic_scenario=stochastic_scenario(:child), t=t2)
        @test connection_avg_throughflow[key1] == connection_avg_throughflow[key2] == 100
    end
    @testset "save_contingency_is_binding" begin
        url_in = "sqlite://"
        test_data = Dict(
            :objects => [
                ["model", "instance"],
                ["model", "master"],
                ["temporal_block", "hourly"],
                ["temporal_block", "investments_hourly"],
                ["temporal_block", "two_hourly"],
                ["stochastic_structure", "deterministic"],
                ["stochastic_structure", "investments_deterministic"],
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
                ["model__temporal_block", ["instance", "hourly"]],
                ["model__temporal_block", ["instance", "two_hourly"]],
                ["model__temporal_block", ["master", "investments_hourly"]],
                ["model__stochastic_structure", ["instance", "deterministic"]],
                ["model__stochastic_structure", ["instance", "stochastic"]],
                ["model__stochastic_structure", ["master", "investments_deterministic"]],
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
                ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
                ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
            ],
            :object_parameter_values => [
                ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
                ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
                ["model", "instance", "duration_unit", "hour"],
                ["model", "instance", "model_type", "spineopt_standard"],
                ["model", "master", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
                ["model", "master", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
                ["model", "master", "duration_unit", "hour"],
                ["model", "master", "model_type", "spineopt_other"],
                ["model", "master", "max_gap", "0.05"],
                ["model", "master", "max_iterations", "2"],
                ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
                ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
                ["model", "instance", "db_mip_solver", "Cbc.jl"],
                ["model", "instance", "db_lp_solver", "Clp.jl"],
            ],
            :relationship_parameter_values => [
                [
                    "stochastic_structure__stochastic_scenario",
                    ["stochastic", "parent"],
                    "stochastic_scenario_end",
                    Dict("type" => "duration", "data" => "1h")
                ]
            ],
        )
        _load_test_data(url_in, test_data)
        conn_r = 0.9
        conn_x = 0.1
        conn_emergency_cap_ab = 80
        conn_emergency_cap_bc = 100
        conn_emergency_cap_ca = 150
        objects = [
            ["commodity", "electricity"],
            ["report", "report_x"],
            ["output", "contingency_is_binding"],
        ]
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
            ["report__output", ["report_x", "contingency_is_binding"]],
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
            ["node", "node_c", "demand", 100],
            ["node", "node_b", "demand", -100],
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
        m = run_spineopt(url_in; log_level=0, optimize=true)
        var_connection_flow = m.ext[:spineopt].variables[:connection_flow]
        @test !haskey(m.ext[:spineopt].constraints, :connection_flow_lodf)
        contingency_is_binding = m.ext[:spineopt].values[:contingency_is_binding]
        @test length(contingency_is_binding) == 3
        conn_cont = connection(:connection_ca)
        s_parent = stochastic_scenario(:parent)
        s_child = stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        # connection_ab
        conn_mon = connection(:connection_ab)
        @test observed_val = contingency_is_binding[conn_cont, conn_mon, [s_parent, s_child], t2h] == 0
        # connection_bc -- t1h1
        conn_mon = connection(:connection_bc)
        @test observed_val = contingency_is_binding[conn_cont, conn_mon, [s_parent], t1h1] == 1
        # connection_bc -- t1h2
        @test observed_val = contingency_is_binding[conn_cont, conn_mon, [s_child], t1h2] == 1
    end

end
