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

function _test_save_connection_avg_throughflow_setup()
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
            ["report", "report_x"],
            ["output", "connection_avg_throughflow"],
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
            ["report__output", ["report_x", "connection_avg_throughflow"]],
            ["report__output", ["report_x", "connection_avg_intact_throughflow"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["node", "node_a", "demand", -100],
            ["node", "node_b", "demand", 100],
            ["output", "connection_avg_throughflow", "output_resolution", Dict("type" => "duration", "data" => "2h")],
            ["output", "connection_avg_intact_throughflow", "output_resolution", Dict("type" => "duration", "data" => "2h")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ],
        :relationship_parameter_values => [[
            "stochastic_structure__stochastic_scenario",
            ["stochastic", "parent"],
            "stochastic_scenario_end",
            Dict("type" => "duration", "data" => "1h"),
        ]],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function test_save_connection_avg_throughflow()
    @testset "save_connection_avg_throughflow_unidirectional" begin
        # The case where the connection has a single connection__from_node and connection__to_node from node a to b.
        url_in = _test_save_connection_avg_throughflow_setup()
        m = run_spineopt(url_in; log_level=0)
        connection_avg_throughflow = m.ext[:spineopt].values[:connection_avg_throughflow]
        @test length(connection_avg_throughflow) == 2
        t1, t2 = time_slice(m; temporal_block=temporal_block(:hourly))
        key = (connection=connection(:connection_ab), node=node(:node_b))
        key1 = (key..., stochastic_scenario=stochastic_scenario(:parent), t=t1)
        key2 = (key..., stochastic_scenario=stochastic_scenario(:child), t=t2)
        @test connection_avg_throughflow[key1] == connection_avg_throughflow[key2] == 100
    end
    @testset "save_connection_avg_throughflow_unidirectional_imbalanced_terminal_a" begin
        # The case where the connection has connection__from_node for both node a and b 
        # and a single connection__to_node for node b.
        url_in = _test_save_connection_avg_throughflow_setup()
        relationships = [
            ["connection__from_node", ["connection_ab", "node_b"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships)
        m = run_spineopt(url_in; log_level=0)
        connection_avg_throughflow = m.ext[:spineopt].values[:connection_avg_throughflow]
        @test length(connection_avg_throughflow) == 2
        t1, t2 = time_slice(m; temporal_block=temporal_block(:hourly))
        key = (connection=connection(:connection_ab), node=node(:node_b))
        key1 = (key..., stochastic_scenario=stochastic_scenario(:parent), t=t1)
        key2 = (key..., stochastic_scenario=stochastic_scenario(:child), t=t2)
        @test connection_avg_throughflow[key1] == connection_avg_throughflow[key2] == 100
    end
    @testset "save_connection_avg_throughflow_unidirectional_imbalanced_terminal_b" begin
        # The case where the connection has connection__to_node for both node a and b 
        # and a single connection__from_node for node a.
        url_in = _test_save_connection_avg_throughflow_setup()
        relationships = [
            ["connection__to_node", ["connection_ab", "node_a"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships)
        m = run_spineopt(url_in; log_level=0)
        connection_avg_throughflow = m.ext[:spineopt].values[:connection_avg_throughflow]
        @test length(connection_avg_throughflow) == 2
        t1, t2 = time_slice(m; temporal_block=temporal_block(:hourly))
        key = (connection=connection(:connection_ab), node=node(:node_b))
        key1 = (key..., stochastic_scenario=stochastic_scenario(:parent), t=t1)
        key2 = (key..., stochastic_scenario=stochastic_scenario(:child), t=t2)
        @test connection_avg_throughflow[key1] == connection_avg_throughflow[key2] == 100
    end
    @testset "save_connection_avg_throughflow_bidirectional" begin
        # The case where the connection between node a and b is bidirectional, including the ptdf calculation.
        url_in = _test_save_connection_avg_throughflow_setup()
        objects = [
            ["commodity", "electricity"],
        ]
        relationships = [
            ["node__commodity", ["node_a", "electricity"]],
            ["node__commodity", ["node_b", "electricity"]],
        ]
        object_parameter_values = [
            ["connection", "connection_ab", "connection_monitored", true],
            ["connection", "connection_ab", "connection_reactance", 0.1],
            ["connection", "connection_ab", "connection_resistance", 0.9],
            ["commodity", "electricity", "commodity_physics", "commodity_physics_ptdf"],
            ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
            ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0)
        connection_avg_throughflow = m.ext[:spineopt].values[:connection_avg_throughflow]
        @test length(connection_avg_throughflow) == 2
        t1, t2 = time_slice(m; temporal_block=temporal_block(:hourly))
        key = (connection=connection(:connection_ab), node=node(:node_b))
        key1 = (key..., stochastic_scenario=stochastic_scenario(:parent), t=t1)
        key2 = (key..., stochastic_scenario=stochastic_scenario(:child), t=t2)
        @test connection_avg_throughflow[key1] == connection_avg_throughflow[key2] == 100
    end
end

function _test_save_contingency_is_binding_setup()
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
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
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
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
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T00:00:00")],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "6h")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "6h")
            ]
        ],
    )
    _load_test_data(url_in, test_data)
    url_in, url_out, file_path_out
end

function test_save_contingency_is_binding()
    @testset "save_contingency_is_binding" begin
        url_in, url_out, file_path_out = _test_save_contingency_is_binding_setup()
        conn_r = 0.9
        conn_x = 0.1
        conn_emergency_cap_ab = 80
        conn_emergency_cap_bc = 100
        conn_emergency_cap_ca = 150
        d_timestamps = collect(DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2))
        d_values = [100, 50, 200, 75, 100]
        demand_ = TimeSeries(d_timestamps, d_values, false, false)
        objects = [
            ["commodity", "electricity"],
            ["report", "report_x"],
            #FIXME: Another report with the same output will fail the test by an error
            # Uncomment the following line and that in "relationships" to see the error
            # ["report", "report_y"],
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
            # ["report__output", ["report_y", "contingency_is_binding"]],
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
            ["node", "node_c", "demand", unparse_db_value(demand_)],
            ["node", "node_b", "demand", unparse_db_value(-demand_)],
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
        rm(file_path_out; force=true)
        m = run_spineopt(url_in, url_out; log_level=0, optimize=true)
        O = Module()
        using_spinedb(url_out, O)
        var_connection_flow = m.ext[:spineopt].variables[:connection_flow]
        @test !haskey(m.ext[:spineopt].constraints, :connection_flow_lodf)
        conn_cont = connection(:connection_ca)
        val = O.contingency_is_binding(connection1=conn_cont, connection2=connection(:connection_ab))
        demand_pv = parameter_value(demand_)
        @testset for (t, obs) in val
            exp = demand_pv(t=t) >= 200 ? 1.0 : 0.0
            @test obs == exp
        end
        val = O.contingency_is_binding(connection1=conn_cont, connection2=connection(:connection_bc))
        @testset for (t, obs) in val
            exp = demand_pv(t=t) >= 100 ? 1.0 : 0.0
            @test obs == exp
        end
    end
end

@testset "postprocess_results" begin
    test_save_connection_avg_throughflow()
    test_save_contingency_is_binding()
end