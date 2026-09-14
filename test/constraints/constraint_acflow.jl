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

function test_constraint_connection_ac_flows()
    @testset "test constraint connection ac flows" begin
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
        m = run_spineopt(url_in; log_level=0, optimize=false)
        c1 = m.ext[:spineopt].constraints[:connection_flow_real]
        var_v_sq = m.ext[:spineopt].variables[:node_voltage_squared]
        var_v_cos = m.ext[:spineopt].variables[:node_voltageproduct_cosine]
        var_v_sin = m.ext[:spineopt].variables[:node_voltageproduct_sine]
        var_flowP = m.ext[:spineopt].variables[:connection_flow]
       
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        s_path = [stochastic_scenario(:parent), stochastic_scenario(:child)]

        g = 2.5; b = -2.5

        for (s, t) in zip(s_path, time_slices)
            println("$s ja $t")
            #source  bus
            flowind = (connection(:connection_bc), node(:node_b), direction(:from_node), s, t)
            nodeind = (node(:node_b), s, t)
            twonodeind = (node(:node_b), node(:node_c), s, t)
            expected_con = @build_constraint(var_flowP[flowind...] 
                + g * var_v_cos[twonodeind...] -b * var_v_sin[twonodeind...] 
                - g * var_v_sq[nodeind...] == 0)
            con_key = (connection(:connection_bc), node(:node_b), direction(:from_node), s, t)
            observed_con = constraint_object(c1[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
            # destination bus
            flowind = (connection(:connection_bc), node(:node_c), direction(:to_node), s, t)
            nodeind = (node(:node_c), s, t)
            expected_con = @build_constraint(var_flowP[flowind...] 
                - g * var_v_cos[twonodeind...] + g * var_v_sq[nodeind...]  
                - b * var_v_sin[twonodeind...] == 0)
            con_key = (connection(:connection_bc), node(:node_c), direction(:to_node), s, t)
            observed_con = constraint_object(c1[con_key...])
            println(c1[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end

        
    end
end

function test_constraint_nodal_reactive_balance()
    @testset "test constraint nodal reactive balance" begin
        url_in = _test_acflow_setup()
        object_parameter_values = [      
            ["node", "node_b", "demand_reactive", 0.1],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "min_voltage", 0.7],
        ]
        relationships = [["connection__node__node", [ "connection_bc", "node_b", "node_c"]]]
        relationship_parameter_values = [
            ["connection__node__node",
            ["connection_bc", "node_b", "node_c"], "connection_has_ac_flow", true]
        ]    
        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        c1 = m.ext[:spineopt].constraints[:nodal_reactive_balance]
        var_flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]
        var_u_q = m.ext[:spineopt].variables[:unit_flow_reactive]
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        s_path = [stochastic_scenario(:parent), stochastic_scenario(:child)]

        for (s, t) in zip(s_path, time_slices)
            println("$s ja $t")
            con_key = (node(:node_b), s, t)
            flowind = (connection(:connection_bc), node(:node_b), direction(:from_node), s, t)
            genind = (unit(:unit_ab), node(:node_b), direction(:to_node), s, t)
            nodeind = (node(:node_b), s, t)
            expected_con = @build_constraint(-var_flowQ[flowind...] + var_u_q[genind...]  
            == 0.1)
            observed_con = constraint_object(c1[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_connection_reactive_capacity()
    url_in = _test_acflow_setup()
     @testset "test constraint line reactive power capacity" begin
        objects = [
            ["unit", "unit_x"]
        ]
        object_parameter_values = [      
            ["node", "node_b", "demand_reactive", 0.0],
            ["node", "node_b", "min_voltage", 0.7],
            ["node", "node_c", "min_voltage", 0.7],
            ["node", "node_c", "demand", 0.3],
            ["node", "node_c", "demand_reactive", 0.0],
            ["connection","connection_bc","resistance",0.2],
            ["connection","connection_bc","reactance",0.2],
            ["connection","connection_bc","investment_count_max_cumulative", 1.0],
            ["connection","connection_bc","connection_investment_cost", 35.0],
            ["connection","connection_bc", "investment_variable_type", "integer"]
        ]
        relationships = [
            ["connection__node__node", [ "connection_bc", "node_b", "node_c"]],
            ["unit__to_node", ["unit_x", "node_c"]],
            ["units_on__temporal_block", ["unit_x", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_x", "deterministic"]],
            ["connection__investment_temporal_block", ["connection_bc", "inve_daily"]],
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
        m = run_spineopt(url_in; log_level=1, optimize=false)
        time_slices_inve = time_slice(m; temporal_block=temporal_block(:inve_daily))
        
        # aliases for the model OPF variables
        var_conn_inve_ava = m.ext[:spineopt].variables[:connections_invested_available]
        var_flowQ = m.ext[:spineopt].variables[:connection_flow_reactive]
        c1 = m.ext[:spineopt].constraints[:connection_reactive_flow_capacity]

        scenarios = [stochastic_scenario(:parent), stochastic_scenario(:child)]
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        daily_t = time_slice(m; temporal_block=temporal_block(:inve_daily))
        @testset for (k, t) in enumerate(time_slices)
            s = scenarios[k]
            con_key = (connection(:connection_bc), node(:node_c), direction(:to_node), scenarios[1:k], t)
            inve_ind = (connection(:connection_bc), stochastic_scenario(:parent), daily_t[1])
            flowind = (connection(:connection_bc), node(:node_c), direction(:to_node), s, t)
            expected_con = @build_constraint(var_flowQ[flowind...] <= 10 * var_conn_inve_ava[inve_ind...])
            observed_con = constraint_object(c1[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
     end
end

@testset "acflow constraints" begin
    #test_constraint_connection_ac_flows()
    #test_constraint_nodal_reactive_balance()
    test_constraint_connection_reactive_capacity()
end
