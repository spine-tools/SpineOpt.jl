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

function _test_acflow_setup()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "two_hourly"],
            ["temporal_block", "investments_hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "stochastic"],
            ["stochastic_structure", "investments_deterministic"],
            ["grid", "grid1"],
            ["unit", "unit_ab"],
            ["connection", "connection_bc"],
            ["connection", "connection_ca"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["node", "node_group_bc"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__temporal_block", ["instance", "investments_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["model__stochastic_structure", ["instance", "investments_deterministic"]],
            ["node__to_unit", ["node_a", "unit_ab"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["units_on__temporal_block", ["unit_ab", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["connection__from_node", ["connection_ca", "node_c"]],
            ["connection__to_node", ["connection_ca", "node_a"]],
            ["node__grid", ["node_b", "grid1"]],
            ["node__grid", ["node_c", "grid1"]],
            ["node__temporal_block", ["node_a", "two_hourly"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__temporal_block", ["node_c", "hourly"]],
            ["node__temporal_block", ["node_group_bc", "hourly"]],
            ["node__stochastic_structure", ["node_a", "deterministic"]],
            ["node__stochastic_structure", ["node_b", "stochastic"]],
            ["node__stochastic_structure", ["node_c", "stochastic"]],
            ["node__stochastic_structure", ["node_group_bc", "stochastic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
        ],
        :object_groups => [["node", "node_group_bc", "node_b"], ["node", "node_group_bc", "node_c"]],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["model", "instance", "decomposition_max_gap", "0.05"],
            ["model", "instance", "decomposition_max_iterations", "2"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["temporal_block", "investments_hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["grid", "grid1", "physics_type", "acflow_physics"],
            ["node", "node_group_bc", "balance_type", "none"],
            ["model", "instance", "solver_mip", "HiGHS.jl"],
            ["model", "instance", "solver_lp", "HiGHS.jl"],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ]
        ]
    )
    _load_test_data(url_in, test_data)
    url_in
end

"""
    test_ac_opf_singleconn()
    Testing the voltage of the demand node when there is a real power demand behind a single connection.
"""
function test_ac_opf_singleconn()
    @testset "ac_opf_singleconn" begin
   
        url_in = _test_acflow_setup()
        object_parameter_values = [      
            ["node", "node_b", "demand_reactive", 0.1],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.2],
            ["node", "node_c", "demand_reactive", 0.0],
            ["connection","connection_bc","resistance",0.2],
            ["connection","connection_bc","reactance",0.2],
            ["connection","connection_bc","connection_current_max",1.0]
        ]
        relationships = [["connection__node__node", [ "connection_bc", "node_b", "node_c"]]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true]
        ]    

        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        vsq = m.ext[:spineopt].variables[:node_voltage_squared]
        vsin  = m.ext[:spineopt].variables[:node_voltageproduct_sine]
        vcos  = m.ext[:spineopt].variables[:node_voltageproduct_cosine]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]

        # if isdefined(Main, :Infiltrator)
        #     Main.infiltrate(@__MODULE__, Base.@locals, @__FILE__, @__LINE__)
        # end

        @test value( vsq[node(:node_c), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.9165 atol=0.02

        @test value(flowP[connection(:connection_bc), node(:node_b), 
            direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            0.2087 atol=0.001
            
        @test value(flowQ[connection(:connection_bc), node(:node_b), 
            direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            0.0087 atol=0.001
    end
end


"""
    test_ac_opf_singleconn_q()
    Testing the voltage of the demand node when there is a reactive power demand behind a single connection.
"""
function test_ac_opf_singleconn_q()
    @testset "ac_opf_singleconn_q" begin
   
        url_in = _test_acflow_setup()
        object_parameter_values = [      
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.1],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.0],
            ["node", "node_c", "demand_reactive", 0.2],
            ["connection","connection_bc","resistance",0.2],
            ["connection","connection_bc","reactance",0.2],
            ["connection","connection_bc","connection_current_max",1.0]
        ]
        relationships = [["connection__node__node", [ "connection_bc", "node_b", "node_c"]]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true]
        ]    

        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        vsq = m.ext[:spineopt].variables[:node_voltage_squared]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]

        @test value( vsq[node(:node_c), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.9165 atol=0.02
        @test value(flowP[connection(:connection_bc), node(:node_b), 
            direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            0.0087 atol=0.001
            
        @test value(flowQ[connection(:connection_bc), node(:node_b), 
            direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            0.2087 atol=0.001
    end
end


"""
    test_ac_opf_singleconn_q()
    Testing the voltage of the demand node when a single connection works in reverse direction.
"""
function test_ac_opf_singleconn_rev()
    @testset "ac_opf_singleconn_rev" begin
   
        url_in = _test_acflow_setup()
        # add one more node and connection
        objects = [
            ["connection", "c1"],
            ["node", "node_d"],
            ["node", "node_e"],
            ["unit", "unit_x"]
        ]
        object_parameter_values = [
            ["node", "node_e", "has_voltage", true],
            ["node", "node_e", "demand", 0.2],
            ["node", "node_e", "min_voltage", 0.7],
            ["node", "node_d", "has_voltage", true],
            ["node", "node_d", "min_voltage", 0.7],
            ["node", "node_d", "demand", 0.0],
            ["node", "node_d", "demand_reactive", 0.0],
            ["connection","c1","resistance",0.2],
            ["connection","c1","reactance",0.2],
            ["connection","c1","connection_current_max",1.0]
        ]
        relationships = [
            ["node__grid", ["node_d", "grid1"]],
            ["node__grid", ["node_e", "grid1"]],
            ["unit__to_node", ["unit_x", "node_d"]],
            ["units_on__temporal_block", ["unit_x", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_x", "deterministic"]],
            ["connection__from_node", ["c1", "node_e"]],
            ["connection__to_node", ["c1", "node_d"]],
            ["connection__node__node", [ "c1", "node_e", "node_d"]],
            ["node__temporal_block", ["node_d", "hourly"]],
            ["node__stochastic_structure", ["node_d", "stochastic"]],
            ["node__temporal_block", ["node_e", "hourly"]],
            ["node__stochastic_structure", ["node_e", "stochastic"]]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_x", "node_d"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_x", "node_d"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
                ["c1", "node_e", "node_d"], "connection_has_ac_flow", true]
        ]

        SpineInterface.import_data(
            url_in;
            objects = objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        vsq = m.ext[:spineopt].variables[:node_voltage_squared]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]

       
        @test value( vsq[node(:node_e), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.9165 atol=0.01
        @test value(flowP[connection(:c1), node(:node_e), 
             direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            -0.2 atol=0.001

        @test value(flowP[connection(:c1), node(:node_d), 
            direction(:to_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            -0.2087 atol=0.001
    end
end

"""
    test_ac_opf_singleconn_lim_I()
    Testing the voltage of the demand node when there is a real power demand behind a single connection.
"""
function test_ac_opf_singleconn_lim_I()
    @testset "ac_opf_singleconn_lim_I" begin
   
        url_in = _test_acflow_setup()
        objects = [
            ["unit", "unit_x"]
        ]
        object_parameter_values = [      
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.0],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.3],
            ["node", "node_c", "demand_reactive", 0.0],
            ["connection","connection_bc","resistance",0.2],
            ["connection","connection_bc","reactance",0.2],
            ["connection","connection_bc","connection_current_max", 0.2089]
        ]
        relationships = [
            ["connection__node__node", [ "connection_bc", "node_b", "node_c"]],
            ["unit__to_node", ["unit_x", "node_c"]],
            ["units_on__temporal_block", ["unit_x", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_x", "deterministic"]]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["unit__to_node", ["unit_x", "node_c"], "vom_cost", 100.0],
            ["unit__to_node", ["unit_x", "node_c"], "vom_cost_reactive", 20.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true]
        ]    

        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        vsq = m.ext[:spineopt].variables[:node_voltage_squared]
        uflow = m.ext[:spineopt].variables[:unit_flow]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]

        @test value(flowP[connection(:connection_bc), node(:node_b), 
            direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            0.2087 atol=0.003
            
        @test value(flowQ[connection(:connection_bc), node(:node_b), 
            direction(:from_node), stochastic_scenario(:parent), time_slices[1]]) ≈
            0.0087 atol=0.001

        #println(SpineOpt._has_ac_flow_connection_node(m; connection=connection(:connection_bc), node=node(:node_c) ))
    end
end

"""
    test_ac_opf_singleconn_inve()

    Tests the optimal investment in an AC connection when the alternative is a more
    expensive generation unit connected directly to the demand node.
"""
function test_ac_opf_singleconn_inve()
    @testset "ac_opf_singleconn_inve" begin
   
        url_in = _test_acflow_setup()
        objects = [
            ["unit", "unit_x"]
        ]
        object_parameter_values = [      
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.0],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.3],
            ["node", "node_c", "demand_reactive", 0.0],
            ["connection","connection_bc","resistance",0.2],
            ["connection","connection_bc","reactance",0.2],
            ["connection","connection_bc","connection_current_max", 0.2089],
            ["connection","connection_bc","investment_count_max_cumulative", 1.0],
            ["connection","connection_bc","connection_investment_cost", 35.0],
            ["connection","connection_bc", "investment_variable_type", "integer"]
        ]
        relationships = [
            ["connection__node__node", [ "connection_bc", "node_b", "node_c"]],
            ["unit__to_node", ["unit_x", "node_c"]],
            ["units_on__temporal_block", ["unit_x", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_x", "deterministic"]],
            ["connection__investment_temporal_block", ["connection_bc", "investments_hourly"]],
            ["connection__investment_stochastic_structure", ["connection_bc", "investments_deterministic"]],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["unit__to_node", ["unit_x", "node_c"], "vom_cost", 100.0],
            ["unit__to_node", ["unit_x", "node_c"], "vom_cost_reactive", 20.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true],
            ["connection__to_node", ["connection_bc", "node_c"], "capacity_per_connection", 10.0]
        ]    

        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        vsq = m.ext[:spineopt].variables[:node_voltage_squared]
        uflow = m.ext[:spineopt].variables[:unit_flow]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]
        cinv = m.ext[:spineopt].variables[:connections_invested]

        @test value(cinv[connection(:connection_bc), stochastic_scenario(:parent), time_slices[1]]) == 1.0
    end
end

"""
    test_ac_opf_singleconn_inve_rev()

    Tests the optimal investment in an AC connection when the connection is in reverse direction.
"""
function test_ac_opf_singleconn_inve_rev()
    @testset "ac_opf_singleconn_inve_rev" begin
        url_in = _test_acflow_setup()
    
        # add one more node and connection
        objects = [
            ["connection", "c1"],
            ["node", "node_d"],
            ["node", "node_e"],
            ["unit", "unit_x"]
        ]
        object_parameter_values = [
            ["node", "node_e", "has_voltage", true],
            ["node", "node_e", "demand", 0.2],
            ["node", "node_e", "min_voltage", 0.7],
            ["node", "node_d", "has_voltage", true],
            ["node", "node_d", "min_voltage", 0.7],
            ["node", "node_d", "demand", 0.0],
            ["node", "node_d", "demand_reactive", 0.0],
            ["connection","c1","resistance", 0.2],
            ["connection","c1","reactance", 0.2],
            ["connection","c1","connection_current_max", 1.0],
            ["connection","c1","investment_count_max_cumulative", 1.0],
            ["connection","c1","connection_investment_cost", 5.0],
            ["connection","c1", "investment_variable_type", "integer"]
        ]
        relationships = [
            ["node__grid", ["node_d", "grid1"]],
            ["node__grid", ["node_e", "grid1"]],
            ["unit__to_node", ["unit_x", "node_d"]],
            ["units_on__temporal_block", ["unit_x", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_x", "deterministic"]],
            ["connection__from_node", ["c1", "node_e"]],
            ["connection__to_node", ["c1", "node_d"]],
            ["connection__node__node", [ "c1", "node_e", "node_d"]],
            ["node__temporal_block", ["node_d", "hourly"]],
            ["node__stochastic_structure", ["node_d", "stochastic"]],
            ["node__temporal_block", ["node_e", "hourly"]],
            ["node__stochastic_structure", ["node_e", "stochastic"]],
            ["connection__investment_temporal_block", ["c1", "investments_hourly"]],
            ["connection__investment_stochastic_structure", ["c1", "investments_deterministic"]]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_x", "node_d"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_x", "node_d"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
                ["c1", "node_e", "node_d"], "connection_has_ac_flow", true],
            ["connection__to_node", ["c1", "node_d"], "capacity_per_connection", 10.0]
        ]    
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        uflow = m.ext[:spineopt].variables[:unit_flow]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]
        cinv = m.ext[:spineopt].variables[:connections_invested]

        @test value(cinv[connection(:c1), stochastic_scenario(:parent), time_slices[1]]) == 1.0
    end
end

"""
    test_ac_opf_singleconn_lossless()

    Tests the investment in an AC connection when there is only reactive flow.
"""
function test_ac_opf_singleconn_lossless()
    @testset "ac_opf_singleconn_lossless" begin
        url_in = _test_acflow_setup()
        # add one more node and connection
        objects = [
            ["connection", "c1"],
            ["node", "node_d"],
            ["node", "node_e"],
            ["unit", "unit_x"]
        ]
        object_parameter_values = [
            ["node", "node_e", "has_voltage", true],
            ["node", "node_e", "demand_reactive", 0.2],
            ["node", "node_e", "min_voltage", 0.7],
            ["node", "node_d", "has_voltage", true],
            ["node", "node_d", "min_voltage", 0.7],
            ["node", "node_d", "demand", 0.0],
            ["node", "node_d", "demand_reactive", 0.0],
            ["connection","c1","resistance", 0.0],
            ["connection","c1","reactance", 0.2],
            ["connection","c1","connection_current_max", 1.0],
            ["connection","c1","investment_count_max_cumulative", 1.0],
            ["connection","c1","connection_investment_cost", 5.0],
            ["connection","c1", "investment_variable_type", "integer"]
        ]
        relationships = [
            ["node__grid", ["node_d", "grid1"]],
            ["node__grid", ["node_e", "grid1"]],
            ["unit__to_node", ["unit_x", "node_d"]],
            ["units_on__temporal_block", ["unit_x", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_x", "deterministic"]],
            ["connection__from_node", ["c1", "node_e"]],
            ["connection__to_node", ["c1", "node_d"]],
            ["connection__node__node", [ "c1", "node_e", "node_d"]],
            ["node__temporal_block", ["node_d", "hourly"]],
            ["node__stochastic_structure", ["node_d", "stochastic"]],
            ["node__temporal_block", ["node_e", "hourly"]],
            ["node__stochastic_structure", ["node_e", "stochastic"]],
            ["connection__investment_temporal_block", ["c1", "investments_hourly"]],
            ["connection__investment_stochastic_structure", ["c1", "investments_deterministic"]],
      
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_x", "node_d"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_x", "node_d"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
                ["c1", "node_e", "node_d"], "connection_has_ac_flow", true],
            ["connection__to_node", ["c1", "node_d"], "capacity_per_connection", 10.0]
        ]    
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )

        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        uflow = m.ext[:spineopt].variables[:unit_flow]
        flowP = m.ext[:spineopt].variables[:connection_flow]
        flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]
        cinv = m.ext[:spineopt].variables[:connections_invested]
      
        @test value(cinv[connection(:c1), stochastic_scenario(:parent), time_slices[1]]) == 1.0
        @test value(uflow[unit(:unit_x), node(:node_d), 
            direction(:to_node), stochastic_scenario(:parent), time_slices[1]]) ≈ 0.0 atol=0.001
    end
end

@testset "validation of linear AC flow calculation" begin

    # test_ac_opf_singleconn()
    # test_ac_opf_singleconn_q()
    # test_ac_opf_singleconn_rev()
    # test_ac_opf_singleconn_lim_I()
    #test_ac_opf_singleconn_inve()
    test_ac_opf_singleconn_inve_rev()
    
    #test_ac_opf_singleconn_lossless()
end