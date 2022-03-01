
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

# TODO: fix_units_on, fix_unit_flow

@testset "user constraints" begin
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],            
            ["temporal_block", "hourly"],            
            ["temporal_block", "two_hourly"],
            ["temporal_block", "investments_two_hourly"],
            ["temporal_block", "investments_four_hourly"],
            ["stochastic_structure", "deterministic"],            
            ["stochastic_structure", "stochastic"],
            ["stochastic_structure", "investments_deterministic"],
            ["unit", "unit_ab"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["connection", "connection_bc"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "hourly"]],            
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__temporal_block", ["instance", "investments_two_hourly"]],
            ["model__temporal_block", ["instance", "investments_four_hourly"]],            
            ["model__stochastic_structure", ["instance", "deterministic"]],            
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["model__stochastic_structure", ["instance", "investments_deterministic"]],
            ["units_on__temporal_block", ["unit_ab", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "stochastic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["node__temporal_block", ["node_a", "hourly"]],
            ["node__temporal_block", ["node_b", "two_hourly"]],
            ["node__temporal_block", ["node_c", "hourly"]],
            ["node__investment_temporal_block", ["node_c", "investments_two_hourly"]],
            ["unit__investment_temporal_block", ["unit_ab", "investments_four_hourly"]],
            ["connection__investment_temporal_block", ["connection_bc", "investments_four_hourly"]],
            ["node__investment_stochastic_structure", ["node_c", "investments_deterministic"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "investments_deterministic"]],
            ["connection__investment_stochastic_structure", ["connection_bc", "investments_deterministic"]],
            ["node__stochastic_structure", ["node_a", "stochastic"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["node__stochastic_structure", ["node_c", "deterministic"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T04:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],                 
            ["node", "node_c", "has_state", true],
            ["node", "node_c", "node_state_cap", 100],
            ["node", "node_c", "candidate_storages", 2],
            ["unit", "unit_ab", "candidate_units", 3],
            ["connection", "connection_bc", "candidate_connections", 1],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],            
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["temporal_block", "investments_two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],            
            ["temporal_block", "investments_four_hourly", "resolution", Dict("type" => "duration", "data" => "4h")],            
        ],
        :relationship_parameter_values => [[
            "stochastic_structure__stochastic_scenario",
            ["stochastic", "parent"],
            "stochastic_scenario_end",
            Dict("type" => "duration", "data" => "1h"),
        ]],
    )
    @testset "constraint_user_constraint_investments" begin
        @testset for sense in ("==", ">=", "<=")
            _load_test_data(url_in, test_data)
            rhs = 1
            unit_flow_coefficient_a = 2
            unit_flow_coefficient_b = 3
            units_on_coefficient = 4
            units_started_up_coefficient = 5
            units_invested_coefficient = 6
            units_invested_available_coefficient = 7
            connections_invested_coefficient = 8
            connections_invested_available_coefficient = 9
            node_state_coefficient = 10
            storages_invested_coefficient = 11
            storages_invested_available_coefficient = 12
            connection_flow_coefficient_b = 13
            connection_flow_coefficient_c = 14

            objects = [["user_constraint", "constraint_x"]]
            relationships = [
                ["unit__from_node__user_constraint", ["unit_ab", "node_a", "constraint_x"]],
                ["unit__to_node__user_constraint", ["unit_ab", "node_b", "constraint_x"]],
                ["unit__user_constraint", ["unit_ab", "constraint_x"]],
                ["connection__user_constraint", ["connection_bc", "constraint_x"]],
                ["node__user_constraint", ["node_c", "constraint_x"]],
                ["connection__from_node__user_constraint", ["connection_bc", "node_b", "constraint_x"]],
                ["connection__to_node__user_constraint", ["connection_bc", "node_c", "constraint_x"]],

            ]
            object_parameter_values = [
                ["user_constraint", "constraint_x", "constraint_sense", Symbol(sense)],
                ["user_constraint", "constraint_x", "right_hand_side", rhs],
            ]
            relationship_parameter_values = [
                [relationships[1]..., "unit_flow_coefficient", unit_flow_coefficient_a],
                [relationships[2]..., "unit_flow_coefficient", unit_flow_coefficient_b],
                [relationships[3]..., "units_on_coefficient", units_on_coefficient],
                [relationships[3]..., "units_started_up_coefficient", units_started_up_coefficient],
                [relationships[3]..., "units_invested_coefficient", units_invested_coefficient],
                [relationships[3]..., "units_invested_available_coefficient", units_invested_available_coefficient],
                [relationships[4]..., "connections_invested_coefficient", connections_invested_coefficient],
                [relationships[4]..., "connections_invested_available_coefficient", connections_invested_available_coefficient],
                [relationships[5]..., "node_state_coefficient", node_state_coefficient],
                [relationships[5]..., "storages_invested_coefficient", storages_invested_coefficient],
                [relationships[5]..., "storages_invested_available_coefficient", storages_invested_available_coefficient],
                [relationships[6]..., "connection_flow_coefficient", connection_flow_coefficient_b],
                [relationships[7]..., "connection_flow_coefficient", connection_flow_coefficient_c],               
                
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:variables][:unit_flow]
            var_connection_flow = m.ext[:variables][:connection_flow]
            var_node_state = m.ext[:variables][:node_state]
            var_units_on = m.ext[:variables][:units_on]
            var_units_started_up = m.ext[:variables][:units_started_up]
            var_units_invested = m.ext[:variables][:units_invested]
            var_units_invested_available = m.ext[:variables][:units_invested_available]
            var_connections_invested = m.ext[:variables][:connections_invested]
            var_connections_invested_available = m.ext[:variables][:connections_invested_available]
            var_storages_invested = m.ext[:variables][:storages_invested]
            var_storages_invested_available = m.ext[:variables][:storages_invested_available]
            
            constraint = m.ext[:constraints][:user_constraint]

            @test length(constraint) == 2
            key_uf_a = (unit(:unit_ab), node(:node_a), direction(:from_node))
            key_uf_b = (unit(:unit_ab), node(:node_b), direction(:to_node))
            key_cf_b = (connection(:connection_bc), node(:node_b), direction(:from_node))
            key_cf_c = (connection(:connection_bc), node(:node_c), direction(:to_node))            

            s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
            t1h1, t1h2, t1h3, t1h4 = time_slice(m; temporal_block=temporal_block(:hourly))
            t2h1, t2h2 = time_slice(m; temporal_block=temporal_block(:two_hourly))
            t4h1 = time_slice(m; temporal_block=temporal_block(:investments_four_hourly))[1]           
            
            expected_con_ref = SpineOpt.sense_constraint(
                m,
                + 4 * units_invested_coefficient * var_units_invested[unit(:unit_ab), s_parent, t4h1]
                + 4 * units_invested_available_coefficient * var_units_invested_available[unit(:unit_ab), s_parent, t4h1]
                + 4 * connections_invested_coefficient * var_connections_invested[connection(:connection_bc), s_parent, t4h1]
                + 4 * connections_invested_available_coefficient * var_connections_invested_available[connection(:connection_bc), s_parent, t4h1]
                
                + 2 * storages_invested_coefficient * (
                    + var_storages_invested[node(:node_c), s_parent, t2h1]
                    + var_storages_invested[node(:node_c), s_parent, t2h2]
                )

                + 2 * storages_invested_available_coefficient * (
                    + var_storages_invested_available[node(:node_c), s_parent, t2h1]
                    + var_storages_invested_available[node(:node_c), s_parent, t2h2]
                )                      
                
                + 2 * units_on_coefficient * (
                    + var_units_on[unit(:unit_ab), s_parent, t2h1]
                    + var_units_on[unit(:unit_ab), s_child, t2h2] 
                )

                + 2 * units_started_up_coefficient * (
                    + var_units_started_up[unit(:unit_ab), s_parent, t2h1]
                    + var_units_started_up[unit(:unit_ab), s_child, t2h2] 
                )               
                
                + unit_flow_coefficient_a * (
                    + var_unit_flow[key_uf_a..., s_parent, t1h1]
                    + var_unit_flow[key_uf_a..., s_child, t1h2]
                    + var_unit_flow[key_uf_a..., s_child, t1h3]
                    + var_unit_flow[key_uf_a..., s_child, t1h4]                               
                )

                + 2 * unit_flow_coefficient_b * (
                    + var_unit_flow[key_uf_b..., s_parent, t2h1]
                    + var_unit_flow[key_uf_b..., s_parent, t2h2]                                                   
                )

                + 2 * connection_flow_coefficient_b * (
                    + var_connection_flow[key_cf_b..., s_parent, t2h1]
                    + var_connection_flow[key_cf_b..., s_parent, t2h2]                                                   
                )

                + connection_flow_coefficient_c * (
                    + var_connection_flow[key_cf_c..., s_parent, t1h1]
                    + var_connection_flow[key_cf_c..., s_parent, t1h2]
                    + var_connection_flow[key_cf_c..., s_parent, t1h3]
                    + var_connection_flow[key_cf_c..., s_parent, t1h4]
                )

                + node_state_coefficient * (
                    + var_node_state[node(:node_c), s_parent, t1h1]
                    + var_node_state[node(:node_c), s_parent, t1h2]
                    + var_node_state[node(:node_c), s_parent, t1h3]
                    + var_node_state[node(:node_c), s_parent, t1h4]
                ),
                Symbol(sense),
                rhs,
            )
            expected_con = constraint_object(expected_con_ref)            
            con_key = (user_constraint(:constraint_x), [s_parent, s_child], t4h1)            
            observed_con = constraint_object(constraint[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end