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

@testset "add connection relationships" begin
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [["connection", "connection_ab"], ["node", "node_a"], ["node", "node_b"]],
        :relationships => [
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
        ],
        :object_parameter_values =>
            [["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"]],
    )
    db_map = _load_test_data(url_in, test_data)
    db_map.commit_session("Add test data")
    using_spinedb(db_map, SpineOpt)
    SpineOpt.add_connection_relationships()
    conn_ab = connection(:connection_ab)
    n_a = node(:node_a)
    n_b = node(:node_b)
    @test length(connection__from_node()) == 2
    @test isempty(symdiff(connection__from_node(), connection__to_node()))
    @test (connection=conn_ab, node=n_a) in connection__from_node()
    @test (connection=conn_ab, node=n_b) in connection__from_node()
    @test length(connection__node__node()) == 2
    @test (connection=conn_ab, node1=n_a, node2=n_b) in connection__node__node()
    @test (connection=conn_ab, node1=n_b, node2=n_a) in connection__node__node()
    @test connection_conv_cap_to_flow(connection=conn_ab, node=n_a) == 1
    @test connection_conv_cap_to_flow(connection=conn_ab, node=n_b) == 1
    @test fix_ratio_out_in_connection_flow(connection=conn_ab, node1=n_a, node2=n_b) == 1
    @test fix_ratio_out_in_connection_flow(connection=conn_ab, node1=n_b, node2=n_a) == 1
end
@testset "expand groups" begin
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["stochastic_structure", "ss"],
            ["node", "node_group_ab"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["unit", "unit_group_ab"],
            ["unit", "unit_a"],
            ["unit", "unit_b"],
        ],
        :object_groups => [
            ["node", "node_group_ab", "node_a"],
            ["node", "node_group_ab", "node_b"],
            ["unit", "unit_group_ab", "unit_a"],
            ["unit", "unit_group_ab", "unit_b"],
        ],
        :relationships => [
            ["node__stochastic_structure", ["node_group_ab", "ss"]],
            ["units_on__stochastic_structure", ["unit_group_ab", "ss"]],
        ],
    )
    db_map = _load_test_data(url_in, test_data)
    db_map.commit_session("Add test data")
    using_spinedb(db_map, SpineOpt)
    n_a = node(:node_a)
    n_b = node(:node_b)
    ng_ab = node(:node_group_ab)
    u_a = unit(:unit_a)
    u_b = unit(:unit_b)
    ug_ab = unit(:unit_group_ab)
    ss = stochastic_structure(:ss)
    @test node__stochastic_structure() == [(node=ng_ab, stochastic_structure=ss)]
    @test units_on__stochastic_structure() == [(unit=ug_ab, stochastic_structure=ss)]
    SpineOpt.expand_node__stochastic_structure()
    SpineOpt.expand_units_on__stochastic_structure()
    @test length(node__stochastic_structure()) == 3
    @test length(units_on__stochastic_structure()) == 3
    @test all((node=n, stochastic_structure=ss) in node__stochastic_structure() for n in (ng_ab, n_a, n_b))
    @test all((unit=u, stochastic_structure=ss) in units_on__stochastic_structure() for u in (ug_ab, u_a, u_b))
end
@testset "constraint_process_lossless_bidirectional_capacities" begin
    conn_r = 0.9
    conn_x = 0.1
    conn_cap_ab = 80
    conn_cap_bc = 100
    conn_cap_ca = 150    
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["commodity", "electricity"],
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
            ["stochastic_scenario", "child"]
        ],
        :relationships => [
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["connection__from_node", ["connection_ca", "node_c"]],
            ["connection__to_node", ["connection_ca", "node_a"]],
            ["node__commodity", ["node_a", "electricity"]],
            ["node__commodity", ["node_b", "electricity"]],
            ["node__commodity", ["node_c", "electricity"]],
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__temporal_block", ["master", "investments_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["model__stochastic_structure", ["master", "investments_deterministic"]],        
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
            ["model", "instance", "model_type", "spineopt_operations"],
            ["model", "master", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "master", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "master", "duration_unit", "hour"],
            ["model", "master", "model_type", "spineopt_other"],
            ["model", "master", "max_gap", "0.05"],
            ["model", "master", "max_iterations", "2"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"],
            ["connection", "connection_bc", "connection_type", "connection_type_lossless_bidirectional"],
            ["connection", "connection_ca", "connection_type", "connection_type_lossless_bidirectional"],        
            ["connection", "connection_ab", "connection_monitored", true],
            ["connection", "connection_ab", "connection_reactance", conn_x],
            ["connection", "connection_ab", "connection_resistance", conn_r],
            ["connection", "connection_bc", "connection_monitored", true],
            ["connection", "connection_bc", "connection_reactance", conn_x],
            ["connection", "connection_bc", "connection_resistance", conn_r],
            ["connection", "connection_ca", "connection_monitored", true],
            ["connection", "connection_ca", "connection_reactance", conn_x],
            ["connection", "connection_ca", "connection_resistance", conn_r],
            ["commodity", "electricity", "commodity_physics", "commodity_physics_ptdf"],
            ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
            ["connection", "connection_ca", "connection_contingency", true],
        ],
        :relationship_parameter_values => [            
            ["connection__from_node", ["connection_ab", "node_a"], "connection_capacity", conn_cap_ab,],
            ["connection__from_node", ["connection_ab", "node_b"], "connection_capacity", conn_cap_ab,],
            ["connection__from_node", ["connection_bc", "node_b"], "connection_capacity", conn_cap_bc,],
            ["connection__from_node", ["connection_ca", "node_c"], "connection_capacity", conn_cap_ca,],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"], "stochastic_scenario_end", Dict("type" => "duration", "data" => "1h")]
        ]
    )
    
    db_map = _load_test_data(url_in, test_data)    
    db_map.commit_session("Add test data")
    m = run_spineopt(db_map; log_level=0, optimize=false)
    
    capacities_dict=Dict(
        connection(:connection_ab) => conn_cap_ab,
        connection(:connection_bc) => conn_cap_bc,
        connection(:connection_ca) => conn_cap_ca
    )

    for (conn, n_from, n_to) in(               
            (connection(:connection_ab), node(:node_a), node(:node_b)),
            (connection(:connection_bc), node(:node_b), node(:node_c)),
            (connection(:connection_ca), node(:node_c), node(:node_a))            
        )
        @test connection_capacity(connection=conn, node=n_from, direction=direction(:from_node)) == capacities_dict[conn]
        @test connection_capacity(connection=conn, node=n_to, direction=direction(:from_node)) == capacities_dict[conn]
        @test connection_capacity(connection=conn, node=n_from, direction=direction(:to_node)) == capacities_dict[conn]
        @test connection_capacity(connection=conn, node=n_to, direction=direction(:to_node)) == capacities_dict[conn]
    end
end