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

# Include this file in main testset of runtests.jl with Juniper.jl and 
# SCS.jl installed.

function _test_socp_formulation_setup()
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
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
            ["unit", "unit_ab"],
            ["connection", "connection_bc"],
            ["connection", "connection_ca"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["node", "node_group_bc"],
            ["report", "report1"]
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__temporal_block", ["instance", "investments_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["model__stochastic_structure", ["instance", "investments_deterministic"]],
            ["model__report", ["instance", "report1"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["units_on__temporal_block", ["unit_ab", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["connection__from_node", ["connection_ca", "node_c"]],
            ["connection__to_node", ["connection_ca", "node_a"]],
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
            ["report__output", ["report1", "node_voltage_squared"]]
        ],
        :object_groups => [["node", "node_group_bc", "node_b"], ["node", "node_group_bc", "node_c"]],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["model", "instance", "max_gap", "0.05"],
            ["model", "instance", "ac_opf_model_formulation", "ac_opf_conic"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["temporal_block", "investments_hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["node", "node_group_bc", "balance_type", "balance_type_none"],
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
    test_node_voltage_singleconn_socp()
    Testing the voltage of the demand node when there is a real power demand behind a single connection.
"""
function test_node_voltage_singleconn_socp()
    @testset "constraint_node_voltage" begin
        nl_solver_options = Map(["solver", "options"], ["SCS.jl", Map(["verbose"],[0])] )
        solver_options = unparse_db_value(Map(["Juniper.jl"], [Map(["nl_solver"], [nl_solver_options])]))

        url_in = _test_socp_formulation_setup()
        object_parameter_values = [
            ["model", "instance", "db_mip_solver", "Juniper.jl"],
            ["model", "instance", "db_mip_solver_options", solver_options],
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.1],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.2],
            ["node", "node_c", "demand_reactive", 0.0],
            ["connection","connection_bc","connection_resistance",0.2],
            ["connection","connection_bc","connection_reactance",0.2],
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
        connflow = m.ext[:spineopt].variables[:connection_flow]
              
        @test value( vsq[node(:node_c), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.9165 atol=0.001
        
        # testing reactive power demand
        object_parameter_values = [
            ["node", "node_c", "demand", 0.0],
            ["node", "node_c", "demand_reactive", 0.2],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
        )
        m = run_spineopt(url_in; log_level=1, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        var_unit_flow_reactive = m.ext[:spineopt].variables[:unit_flow_reactive]

        @test value( var_unit_flow_reactive[unit(:unit_ab), node(:node_b), 
        direction(:to_node), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.3087 atol=0.0001
    end
end

"""
Testing the reverse real AC flow over a connection..
"""
function test_reverse_ac_flow_socp()
    @testset "reverse_acflow" begin
        nl_solver_options = Map(["solver", "options"], ["SCS.jl", Map(["verbose"],[0])] )
        solver_options = unparse_db_value(Map(["Juniper.jl"], [Map(["nl_solver"], [nl_solver_options])]))

        url_in = _test_socp_formulation_setup()

        # add one more node and connection
        objects = [
            ["connection", "connection_bd"],
            ["node", "node_d"],
        ]
        object_parameter_values = [
            ["model", "instance", "db_mip_solver", "Juniper.jl"],
            ["model", "instance", "db_mip_solver_options", solver_options],
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.1],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_d", "has_voltage", true],
            ["node", "node_d", "min_voltage", 0.7],
            ["node", "node_d", "demand", 0.2],
            ["node", "node_d", "demand_reactive", 0.0],
            ["connection","connection_bd","connection_resistance",0.2],
            ["connection","connection_bd","connection_reactance",0.2],
            ["connection","connection_bd","connection_current_max",1.0]
        ]
        relationships = [["connection__from_node", ["connection_bd", "node_b"]],
            ["connection__to_node", ["connection_bd", "node_d"]],
            ["connection__node__node", [ "connection_bd", "node_b", "node_d"]],
            ["node__temporal_block", ["node_d", "hourly"]],
            ["node__stochastic_structure", ["node_d", "stochastic"]]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
                ["connection_bd", "node_b", "node_d"], "connection_has_ac_flow", true]
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
        vsin  = m.ext[:spineopt].variables[:node_voltageproduct_sine]
        vcos  = m.ext[:spineopt].variables[:node_voltageproduct_cosine]
        connflow = m.ext[:spineopt].variables[:connection_flow]

        @test value( vsq[node(:node_d), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.9165 atol=0.001
    end
end

"""
    test_constraint_ac_opf_capacitance_socp()
    Testing the voltage rise on an unloaded capacitive line.
"""
function test_constraint_ac_opf_capacitance_socp()
    @testset "constraint_ac_opf_capacitance" begin
   
        nl_solver_options = Map(["solver", "options"], ["SCS.jl", Map(["verbose", "eps_abs"],[0, 1e-6])] )
        solver_options = unparse_db_value(Map(["Juniper.jl"], [Map(["nl_solver"], [nl_solver_options])]))

        url_in = _test_socp_formulation_setup()
        object_parameter_values = [
            ["model", "instance", "db_mip_solver", "Juniper.jl"],
            ["model", "instance", "db_mip_solver_options", solver_options],
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.0],
            ["node", "node_b", "min_voltage", 1.0],
            ["node", "node_b", "max_voltage", 1.1],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "max_voltage", 1.1],
            ["node", "node_c", "demand", 0.0],
            ["node", "node_c", "demand_reactive", 0.0],
            ["node", "node_c", "shunt_susceptance", 0.1],
            ["connection","connection_bc","connection_resistance",0.0],
            ["connection","connection_bc","connection_reactance",0.1],
            ["connection","connection_bc","connection_current_max",1.0]
        ]
        relationships = [
            ["unit__from_node", ["unit_ab", "node_b"]],
            ["connection__node__node", [ "connection_bc", "node_b", "node_c"]]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["unit__from_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true]
        ]
            
        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=true)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        
        # aliases for the model OPF variables
        vsq = m.ext[:spineopt].variables[:node_voltage_squared]
        vsin  = m.ext[:spineopt].variables[:node_voltageproduct_sine]
        vcos  = m.ext[:spineopt].variables[:node_voltageproduct_cosine]
    
        @test value( vsq[node(:node_c), stochastic_scenario(:parent), time_slices[1]] ) ≈ 1.0101 atol=0.001
    end
end

"""
Testing the node voltage in AC flow over two connections
"""
function test_node_voltage2()

    @testset "acflow1" begin
        nl_solver_options = Map(["solver", "options"], ["SCS.jl", Map(["verbose", "eps_abs"],[0, 1e-6])] )
        
        #solver_options = unparse_db_value(Map(["Juniper.jl"], [Map(["nl_solver"], ["solver:SCS.jl"])]))
        solver_options = unparse_db_value(Map(["Juniper.jl"], [Map(["nl_solver"], [nl_solver_options])]))

        url_in = _test_socp_formulation_setup()

        # add one more node and connection
        objects = [
            ["connection", "connection_cd"],
            ["node", "node_d"],
        ]

        object_parameter_values = [
            ["model", "instance", "db_mip_solver", "Juniper.jl"],
            ["model", "instance", "db_mip_solver_options", solver_options],
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.0],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.0],
            ["node", "node_c", "demand_reactive", 0.2],
            ["node", "node_d", "has_voltage", true],
            ["node", "node_d", "min_voltage", 0.7],
            ["node", "node_d", "demand", 0.0],
            ["node", "node_d", "demand_reactive", 0.2],
            ["connection","connection_bc","connection_resistance",0.2],
            ["connection","connection_bc","connection_reactance",0.2],
            ["connection","connection_bc","connection_current_max",1.0],
            ["connection","connection_cd","connection_resistance",0.2],
            ["connection","connection_cd","connection_reactance",0.2],
            ["connection","connection_cd","connection_current_max",1.0]
        ]
        relationships = [
            ["connection__from_node", ["connection_cd", "node_c"]],
            ["connection__to_node", ["connection_cd", "node_d"]],
            ["connection__node__node", [ "connection_bc", "node_b", "node_c"]],
            ["connection__node__node", [ "connection_cd", "node_c", "node_d"]],
            ["node__temporal_block", ["node_d", "hourly"]],
            ["node__stochastic_structure", ["node_d", "stochastic"]],
        
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true],
            ["connection__node__node",
            ["connection_cd", "node_c", "node_d"], "connection_has_ac_flow", true]
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

        println("voltage")
        println(value( vsq[node(:node_b), stochastic_scenario(:parent), time_slices[1]] ) )
        println(value( vsq[node(:node_c), stochastic_scenario(:parent), time_slices[1]] ) )
        println(value( vsq[node(:node_d), stochastic_scenario(:parent), time_slices[1]] ) )

        @test value( vsq[node(:node_d), stochastic_scenario(:parent), 
                        time_slices[1]] ) ≈ 0.7302 atol=0.0001
    end
end

"""
    test_node_voltage_singleconn_lindistflow()
    Using the the lindistflow formulation to test the voltage of the demand node when 
    there is a power demand behind a single connection.
"""
function test_node_voltage_singleconn_lindistflow()
    @testset "constraint_node_voltage_lindistflow" begin
        nl_solver_options = Map(["solver", "options"], ["SCS.jl", Map(["verbose"],[0])] )
        solver_options = unparse_db_value(Map(["Juniper.jl"], [Map(["nl_solver"], [nl_solver_options])]))

        url_in = _test_socp_formulation_setup()
        object_parameter_values = [
            ["model", "instance", "ac_opf_model_formulation", "ac_opf_lindistflow"],
            ["model", "instance", "db_mip_solver", "Juniper.jl"],
            ["model", "instance", "db_mip_solver_options", solver_options],
            ["node", "node_b", "has_voltage", true],
            ["node", "node_b", "demand_reactive", 0.1],
            ["node", "node_b", "min_voltage", 1.0],
            ["node", "node_c", "has_voltage", true],
            ["node", "node_c", "power_base", 1000],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 200],
            ["node", "node_c", "demand_reactive", 0.0],
            ["connection","connection_bc","connection_resistance",0.2],
            ["connection","connection_bc","connection_reactance",0.2],
            ["connection","connection_bc","connection_current_max",1.0]
        ]
        relationships = [["connection__node__node", [ "connection_bc", "node_b", "node_c"]]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 10.0],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost_reactive", 2.0],
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true],

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
        connflow = m.ext[:spineopt].variables[:connection_flow]
        @test value( vsq[node(:node_c), stochastic_scenario(:parent), time_slices[1]] ) ≈ 0.92 atol=0.0001
    end
end


@testset "socp formulation" begin
    test_node_voltage_singleconn_socp()
    test_reverse_ac_flow_socp()
    test_constraint_ac_opf_capacitance_socp()
    test_node_voltage_singleconn_lindistflow()
end