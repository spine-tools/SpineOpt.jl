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

function _test_run_spineopt_mga_setup()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "investments_hourly"],
            ["temporal_block", "two_hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "investments_deterministic"],
            ["stochastic_structure", "stochastic"],
            ["unit", "unit_ab"],
            ["unit", "unit_bc"],
            ["unit", "unit_group_abbc"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["node", "node_group_bc"],
            ["connection", "connection_ab"],
            ["connection", "connection_bc"],
            ["connection", "connection_group_abbc"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
            # FIXME: maybe nicer way rather than outputs?
            ["output","units_invested"],
            ["output","connections_invested"],
            ["output","storages_invested"],
            ["output","total_costs"],
            ["report", "report_a"]
        ],
        :object_groups => [
                ["node", "node_group_bc", "node_b"],
                ["node", "node_group_bc", "node_c"],
                ["connection", "connection_group_abbc", "connection_ab"],
                ["connection", "connection_group_abbc", "connection_bc"],
                ["unit", "unit_group_abbc", "unit_ab"],
                ["unit", "unit_group_abbc", "unit_bc"],
                ],
        :relationships => [
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__default_investment_temporal_block", ["instance", "two_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
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
            ["units_on__temporal_block", ["unit_ab", "hourly"]],
            ["units_on__temporal_block", ["unit_bc", "hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "stochastic"]],
            ["units_on__stochastic_structure", ["unit_bc", "stochastic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__from_node", ["unit_bc", "node_b"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["unit__to_node", ["unit_bc", "node_c"]],
            ["report__output",["report_a", "units_invested"]],
            ["report__output",["report_a","connections_invested"]],
            ["report__output",["report_a","storages_invested"]],
            ["report__output",["report_a","total_costs"]],
            ["model__report",["instance","report_a"]],
            ["unit__node__node", ["unit_ab", "node_a", "node_b"]],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"]],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"]],
            ["connection__node__node", ["connection_ab", "node_b", "node_a"]],
            ["unit__node__node", ["unit_bc", "node_b", "node_c"]],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"]],
            ["unit__node__node", ["unit_bc", "node_c", "node_b"]],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_algorithm", "mga_algorithm"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h")
            ],
            ["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_a", "node_b"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_bc", "node_c", "node_b"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_bc", "node_b", "node_c"], "fix_ratio_out_in_unit_flow", 1.0],

        ],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function _test_run_spineopt_mga()
    @testset "run_spineopt_mga" begin
        url_in = _test_run_spineopt_mga_setup()
        candidate_units = 1
        candidate_connections = 1
        candidate_storages = 1
        units_invested_big_m_mga = storages_invested_big_m_mga = connections_invested_big_m_mga = 5
        fuel_cost = 5
        mga_slack = 0.05
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["unit", "unit_bc", "candidate_units", candidate_units],
            ["unit", "unit_ab", "number_of_units", 0],
            ["unit", "unit_bc", "number_of_units", 0],
            ["unit", "unit_group_abbc", "units_invested_mga", true],
            ["unit", "unit_group_abbc", "units_invested_big_m_mga", units_invested_big_m_mga],
            ["unit", "unit_group_abbc", "units_invested__mga_weight", 1],
            ["unit", "unit_ab", "unit_investment_cost", 1],
            ["connection", "connection_ab", "candidate_connections", candidate_connections],
            ["connection", "connection_bc", "candidate_connections", candidate_connections],
            ["connection", "connection_group_abbc", "connections_invested_mga", true],
            ["connection", "connection_group_abbc", "connections_invested_big_m_mga", connections_invested_big_m_mga],
            ["connection", "connection_group_abbc", "connections_invested_mga_weight", 1],
            ["node", "node_b", "candidate_storages", candidate_storages],
            ["node", "node_c", "candidate_storages", candidate_storages],
            ["node", "node_a", "balance_type", :balance_type_none],
            ["node", "node_b", "has_state", true],
            ["node", "node_c", "has_state", true],
            ["node", "node_b", "fix_node_state",0],
            ["node", "node_c", "fix_node_state",0],
            ["node", "node_b", "node_state_cap", 0],
            ["node", "node_c", "node_state_cap", 0],
            ["node", "node_group_bc", "storages_invested_mga", true],
            ["node", "node_group_bc", "storages_invested_big_m_mga", storages_invested_big_m_mga],
            ["node", "node_group_bc", "storages_invested_mga_weight", 1],
            ["model", "instance", "model_algorithm", "mga_algorithm"],
            ["model", "instance", "max_mga_slack", mga_slack],
            ["model", "instance", "max_mga_iterations", 2],
            # ["node", "node_a", "demand", 1],
            ["node", "node_b", "demand", 1],
            ["node", "node_c", "demand", 1],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", 5],
            ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", fuel_cost],
            ["unit__to_node", ["unit_bc", "node_c"], "unit_capacity", 5],
            ["connection__to_node", ["connection_ab","node_b"], "connection_capacity", 5],
            ["connection__to_node", ["connection_bc","node_c"], "connection_capacity", 5]
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=1)
        var_units_invested = m.ext[:spineopt].variables[:units_invested]
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_connections_invested = m.ext[:spineopt].variables[:connections_invested]
        var_storages_invested = m.ext[:spineopt].variables[:storages_invested]
        var_mga_aux_diff = m.ext[:spineopt].variables[:mga_aux_diff]
        var_mga_aux_binary = m.ext[:spineopt].variables[:mga_aux_binary]
        var_mga_aux_objective = m.ext[:spineopt].variables[:mga_objective]
        @testset "mga_diff_ub1" begin
            constraint = m.ext[:spineopt].constraints[:mga_diff_ub1]
            @test length(constraint) == 6
            scenarios = (stochastic_scenario(:parent),)
            time_slices = time_slice(m; temporal_block=temporal_block(:two_hourly))
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end - 1]
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (unit=unit(:unit_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (unit(:unit_ab), s, t)
                key2 = (unit(:unit_bc), s, t)
                var_u_inv_1 = var_units_invested[key1...]
                var_u_inv_2 = var_units_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_ab), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_bc), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key]
                    <= (var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                    + units_invested_big_m_mga*var_mga_aux_binary[key]
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (connection=connection(:connection_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (connection(:connection_ab), s, t)
                key2 = (connection(:connection_bc), s, t)
                var_u_inv_1 = var_connections_invested[key1...]
                var_u_inv_2 = var_connections_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_ab), tail...), mga_it
                )
                prev_mga_results_2 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_bc), tail...), mga_it
                )
                expected_con = @build_constraint(
                    var_mga_aux_diff[key]
                    <= (var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                    + connections_invested_big_m_mga * var_mga_aux_binary[key])
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (node=node(:node_group_bc), mga_iteration=mga_current_iteration)
                key1 = (node(:node_b), s, t)
                key2 = (node(:node_c), s, t)
                var_u_inv_1 = var_storages_invested[key1...]
                var_u_inv_2 = var_storages_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_b), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_c), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key]
                    <= (var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                    + storages_invested_big_m_mga*var_mga_aux_binary[key]
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            # FIXME: add for connection and node
        end
        @testset "mga_diff_ub2" begin
            constraint = m.ext[:spineopt].constraints[:mga_diff_ub2]
            @test length(constraint) == 6
            scenarios = (stochastic_scenario(:parent), )
            time_slices = time_slice(m; temporal_block=temporal_block(:two_hourly))
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end-1]
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (unit=unit(:unit_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (unit(:unit_ab), s, t)
                key2 = (unit(:unit_bc), s, t)
                var_u_inv_1 = var_units_invested[key1...]
                var_u_inv_2 = var_units_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_ab), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_bc), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key]
                    <= -(var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                    + units_invested_big_m_mga * (1 - var_mga_aux_binary[key])
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (connection=connection(:connection_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (connection(:connection_ab), s, t)
                key2 = (connection(:connection_bc), s, t)
                var_u_inv_1 = var_connections_invested[key1...]
                var_u_inv_2 = var_connections_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_ab), tail...), mga_it
                )
                prev_mga_results_2 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_bc), tail...), mga_it
                )
                expected_con = @build_constraint(
                    var_mga_aux_diff[key]
                    <= -(var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                    + connections_invested_big_m_mga * (1 - var_mga_aux_binary[key])
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (node=node(:node_group_bc), mga_iteration=mga_current_iteration)
                key1 = (node(:node_b), s, t)
                key2 = (node(:node_c), s, t)
                var_u_inv_1 = var_storages_invested[key1...]
                var_u_inv_2 = var_storages_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_b), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_c), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key]
                    <= -(var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                    + storages_invested_big_m_mga * (1 - var_mga_aux_binary[key]))
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            # FIXME: add for connection and node
        end
        @testset "mga_diff_lb1" begin
            constraint = m.ext[:spineopt].constraints[:mga_diff_lb1]
            @test length(constraint) == 6
            scenarios = (stochastic_scenario(:parent),)
            time_slices = time_slice(m; temporal_block=temporal_block(:two_hourly))
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end - 1]
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (unit=unit(:unit_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (unit(:unit_ab), s, t)
                key2 = (unit(:unit_bc), s, t)
                var_u_inv_1 = var_units_invested[key1...]
                var_u_inv_2 = var_units_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_ab), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_bc), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key] >= (var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (connection=connection(:connection_group_abbc),mga_iteration=mga_current_iteration)
                key1 = (connection(:connection_ab), s, t)
                key2 = (connection(:connection_bc), s, t)
                var_u_inv_1 = var_connections_invested[key1...]
                var_u_inv_2 = var_connections_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_ab), tail...), mga_it
                )
                prev_mga_results_2 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_bc), tail...), mga_it
                )
                expected_con = @build_constraint(
                    var_mga_aux_diff[key] >= (var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (node=node(:node_group_bc), mga_iteration=mga_current_iteration)
                key1 = (node(:node_b), s, t)
                key2 = (node(:node_c), s, t)
                var_u_inv_1 = var_storages_invested[key1...]
                var_u_inv_2 = var_storages_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_b), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_c), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key] >= (var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            # FIXME: add for connection and node
        end
        @testset "mga_diff_lb2" begin
            constraint = m.ext[:spineopt].constraints[:mga_diff_lb2]
            @test length(constraint) == 6
            scenarios = (stochastic_scenario(:parent), )
            time_slices = time_slice(m; temporal_block=temporal_block(:two_hourly))
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end - 1]
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (unit=unit(:unit_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (unit(:unit_ab), s, t)
                key2 = (unit(:unit_bc), s, t)
                var_u_inv_1 = var_units_invested[key1...]
                var_u_inv_2 = var_units_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_ab), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_bc), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key] >= -(var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                 key = (connection=connection(:connection_group_abbc),mga_iteration=mga_current_iteration)
                key1 = (connection(:connection_ab), s, t)
                key2 = (connection(:connection_bc), s, t)
                var_u_inv_1 = var_connections_invested[key1...]
                var_u_inv_2 = var_connections_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_ab), tail...), mga_it
                )
                prev_mga_results_2 = SpineOpt._mga_result(
                    m, :connections_invested, (connection=connection(:connection_bc), tail...), mga_it
                )
                expected_con = @build_constraint(
                    var_mga_aux_diff[key] >= -(var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (node=node(:node_group_bc),mga_iteration=mga_current_iteration)
                key1 = (node(:node_b), s, t)
                key2 = (node(:node_c), s, t)
                var_u_inv_1 = var_storages_invested[key1...]
                var_u_inv_2 = var_storages_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_b), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :storages_invested, (node=node(:node_c), tail...), mga_it)
                expected_con = @build_constraint(
                    var_mga_aux_diff[key] >= -(var_u_inv_1 - prev_mga_results_1 + var_u_inv_2 - prev_mga_results_2)
                )
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            # FIXME: add for connection and node
        end
        @testset "mga_slack_constraint" begin
            constraint = m.ext[:spineopt].constraints[:mga_slack_constraint]
            @test length(constraint) == 1
            scenarios = (stochastic_scenario(:parent),)
            time_slices = time_slice(m; temporal_block=temporal_block(:two_hourly))
            mga_first_iteration = SpineOpt.mga_iteration()[1]
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end - 1]
            @testset for (s, t) in zip(scenarios, time_slices)
                key1 = (unit(:unit_ab), s, t)
                key2 = (unit(:unit_ab), node(:node_b), direction(:to_node), s, t)
                var_u_inv_1 = var_units_invested[key1...]
                var_u_inv_2 = var_unit_flow[key2...]
                first_obj_result = SpineOpt._mga_result(
                    m, :total_costs, (model=model(:instance), t=t), mga_first_iteration
                )
                expected_con = @build_constraint(
                    var_u_inv_2 * 2 * fuel_cost + var_u_inv_1 <= first_obj_result * (1 + mga_slack)
                )
                con = constraint[model(:instance)]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
            # FIXME: add for connection and node
        end
        @testset "mga_objective_ub" begin
            constraint = m.ext[:spineopt].constraints[:mga_objective_ub]
            @test length(constraint) == 1
            scenarios = (stochastic_scenario(:parent),)
            t = SpineOpt.current_window(m)
            var_mga_objective = m.ext[:spineopt].variables[:mga_objective]
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end-1]
            key1 = (unit=unit(:unit_group_abbc), mga_iteration=mga_current_iteration)
            key2 = (connection=connection(:connection_group_abbc), mga_iteration=mga_current_iteration)
            key3 = (node=node(:node_group_bc), mga_iteration=mga_current_iteration)
            key4 = (model = model(:instance), t=t)
            mga_aux_diff_1 = var_mga_aux_diff[key1]
            mga_aux_diff_2 = var_mga_aux_diff[key2]
            mga_aux_diff_3 = var_mga_aux_diff[key3]
            var_mga_objective1 = var_mga_objective[key4]
            expected_con = @build_constraint(var_mga_objective1 <= mga_aux_diff_1 + mga_aux_diff_2 + mga_aux_diff_3)
            con = constraint[(model = model(:instance),)]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function _test_run_spineopt_mga_2()
    @testset "run_spineopt_mga_2" begin
        url_in = _test_run_spineopt_mga_setup()
        candidate_units = 1
        candidate_connections = 1
        candidate_storages = 1
        fuel_cost = 5
        mga_slack = 0.05
        points = [0, -0.5, -1, 1, 0.5, 0]
        deltas = [points[1]; [points[i] - points[i - 1] for i in Iterators.drop(eachindex(points), 1)]]
        mga_weights_1 = Dict("type" => "array", "value_type" => "float", "data" => points)
        points = [0, -0.5, -1, 1, 0.5, 0]
        deltas = [points[1]; [points[i] - points[i - 1] for i in Iterators.drop(eachindex(points), 1)]]
        mga_weights_2 = Dict("type" => "array", "value_type" => "float", "data" => points)
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["unit", "unit_bc", "candidate_units", candidate_units],
            ["unit", "unit_ab", "number_of_units", 0],
            ["unit", "unit_bc", "number_of_units", 0],
            ["unit", "unit_group_abbc", "units_invested_mga", true],
            ["unit", "unit_group_abbc", "units_invested__mga_weight", mga_weights_1],
            ["unit", "unit_ab", "unit_investment_cost", 1],
            ["unit", "unit_ab", "unit_investment_tech_lifetime", unparse_db_value(Hour(2))],
            ["unit", "unit_bc", "unit_investment_tech_lifetime", unparse_db_value(Hour(2))],
            ["connection", "connection_ab", "candidate_connections", candidate_connections],
            ["connection", "connection_bc", "candidate_connections", candidate_connections],
            ["connection", "connection_ab", "connection_investment_tech_lifetime", unparse_db_value(Hour(2))],
            ["connection", "connection_bc", "connection_investment_tech_lifetime", unparse_db_value(Hour(2))],
            ["connection", "connection_group_abbc", "connections_invested_mga", true],
            ["connection", "connection_group_abbc", "connections_invested_mga_weight",mga_weights_2],
            ["node", "node_b", "candidate_storages", candidate_storages],
            ["node", "node_c", "candidate_storages", candidate_storages],
            ["node", "node_b", "storage_investment_tech_lifetime", unparse_db_value(Hour(2))],
            ["node", "node_c", "storage_investment_tech_lifetime", unparse_db_value(Hour(2))],
            ["node", "node_a", "balance_type", :balance_type_none],
            ["node", "node_b", "has_state", true],
            ["node", "node_c", "has_state", true],
            ["node", "node_b", "fix_node_state", 0],
            ["node", "node_c", "fix_node_state", 0],
            ["node", "node_b", "node_state_cap", 0],
            ["node", "node_c", "node_state_cap", 0],
            ["node", "node_group_bc", "storages_invested_mga", true],
            ["node", "node_group_bc","storages_invested_mga_weight", mga_weights_1],
            ["model", "instance", "model_algorithm", "mga_algorithm"],
            ["model", "instance", "max_mga_slack", mga_slack],
            ["node", "node_b", "demand", 1],
            ["node", "node_c", "demand", 1],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", 5],
            ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", fuel_cost],
            ["unit__to_node", ["unit_bc", "node_c"], "unit_capacity", 5],
            ["connection__to_node", ["connection_ab","node_b"], "connection_capacity", 5],
            ["connection__to_node", ["connection_bc","node_c"], "connection_capacity", 5]
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=1)
        var_units_invested = m.ext[:spineopt].variables[:units_invested]
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_connections_invested = m.ext[:spineopt].variables[:connections_invested]
        var_storages_invested = m.ext[:spineopt].variables[:storages_invested]
        var_mga_aux_diff = m.ext[:spineopt].variables[:mga_aux_diff]
        var_mga_aux_binary = m.ext[:spineopt].variables[:mga_aux_binary]
        var_mga_aux_objective = m.ext[:spineopt].variables[:mga_objective]
        mga_results = m.ext[:spineopt].outputs
        t0 = start(SpineOpt.current_window(m))
        @testset "test mga_objective mga 2" begin
            constraint = m.ext[:spineopt].constraints[:mga_objective_ub]
            @test length(constraint) == 1
            scenarios = (stochastic_scenario(:parent),)
            t = SpineOpt.current_window(m)
            var_mga_objective = m.ext[:spineopt].variables[:mga_objective]
            mga_current_iteration = SpineOpt.mga_iteration()[end - 1]
            key1 = (unit=unit(:unit_group_abbc),mga_iteration=mga_current_iteration)
            key2 = (connection=connection(:connection_group_abbc), mga_iteration=mga_current_iteration)
            key3 = (node=node(:node_group_bc), mga_iteration=mga_current_iteration)
            key4 = (model = model(:instance), t=t)
            mga_aux_diff_1 = var_mga_aux_diff[key1]
            mga_aux_diff_2 = var_mga_aux_diff[key2]
            mga_aux_diff_3 = var_mga_aux_diff[key3]
            var_mga_objective1 = var_mga_objective[key4]
            expected_con = @build_constraint(var_mga_objective1 <= mga_aux_diff_1 + mga_aux_diff_2 + mga_aux_diff_3)
            con = constraint[(model = model(:instance),)]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
        ###
        @testset "test mga_diff_ub1" begin
            constraint = m.ext[:spineopt].constraints[:mga_diff_ub1]
            @test length(constraint) == 18  # TODO: should actually delete constraint...
            scenarios = (stochastic_scenario(:parent),)
            time_slices = time_slice(m; temporal_block=temporal_block(:two_hourly))
            mga_current_iteration = mga_it = SpineOpt.mga_iteration()[end - 1]
            @testset for (s, t) in zip(scenarios, time_slices)
                key = (unit=unit(:unit_group_abbc), mga_iteration=mga_current_iteration)
                key1 = (unit(:unit_ab), s, t)
                key2 = (unit(:unit_bc), s, t)
                var_u_inv_1 = var_units_invested[key1...]
                var_u_inv_2 = var_units_invested[key2...]
                tail = (stochastic_scenario=s, t=t)
                prev_mga_results_1 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_ab), tail...), mga_it)
                prev_mga_results_2 = SpineOpt._mga_result(m, :units_invested, (unit=unit(:unit_bc), tail...), mga_it)
                expected_con = @build_constraint(var_mga_aux_diff[key] == (var_u_inv_1 + var_u_inv_2))
                con = constraint[key...]
                observed_con = constraint_object(con)
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

@testset "run_spineopt_mga" begin
    _test_run_spineopt_mga()
    _test_run_spineopt_mga_2()
end
