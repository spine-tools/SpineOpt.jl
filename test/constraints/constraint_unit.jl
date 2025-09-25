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

function _test_constraint_unit_setup()
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
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["node", "node_group_bc"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "investments_hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "investments_deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["units_on__temporal_block", ["unit_ab", "hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "stochastic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["unit__to_node", ["unit_ab", "node_c"]],
            ["node__temporal_block", ["node_a", "hourly"]],
            ["node__temporal_block", ["node_b", "two_hourly"]],
            ["node__temporal_block", ["node_c", "hourly"]],
            ["node__stochastic_structure", ["node_a", "stochastic"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["node__stochastic_structure", ["node_c", "stochastic"]],
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
            ["model", "instance", "max_gap", "0.05"],
            ["model", "instance", "max_iterations", "2"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "investments_hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
            ["unit", "unit_ab", "units_on_cost", 1],  # Just to have units_on variables
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ]
        ],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function _test_constraint_unit_reserves_setup()
    objects = [["node", "node_group_a"], ["node", "reserves_a"], ["node", "reserves_bc"]]
    object_groups = [
        ["node", "node_group_a", "node_a"],
        ["node", "node_group_a", "reserves_a"],
        ["node", "node_group_bc", "reserves_bc"],
    ]
    relationships = [
        ["unit__from_node", ["unit_ab", "node_group_a"]],
        ["unit__from_node", ["unit_ab", "reserves_a"]],
        ["unit__to_node", ["unit_ab", "node_group_bc"]],
        ["unit__to_node", ["unit_ab", "reserves_bc"]],
        ["node__temporal_block", ["reserves_a", "hourly"]],
        ["node__stochastic_structure", ["reserves_a", "stochastic"]],
        ["node__temporal_block", ["reserves_bc", "hourly"]],
        ["node__stochastic_structure", ["reserves_bc", "deterministic"]],
    ]
    object_parameter_values = [
        ["node", "reserves_a", "is_reserve_node", true],
        ["node", "reserves_bc", "is_reserve_node", true],
    ]
    url_in = _test_constraint_unit_setup()
    SpineInterface.import_data(
        url_in; 
        objects=objects,
        relationships=relationships,
        object_parameter_values=object_parameter_values, 
        object_groups=object_groups,
    )
    url_in
end

function test_constraint_units_available()
    @testset "constraint_units_available" begin
        url_in = _test_constraint_unit_setup()
        number_of_units = 4
        candidate_units = 3
        unit_availability_factor = 0.5
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["unit", "unit_ab", "number_of_units", number_of_units],
            ["unit", "unit_ab", "unit_availability_factor", unit_availability_factor],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        constraint = m.ext[:spineopt].constraints[:units_available]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            key = (unit(:unit_ab), s, t)
            var_u_on = var_units_on[key...]
            var_u_inv_av = var_units_invested_available[key...]
            expected_con = @build_constraint(var_u_on <= number_of_units + var_u_inv_av)
            con_key = (unit(:unit_ab), s, t)
            con = constraint[con_key...]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_units_available_units_unavailable()
    @testset "constraint_units_available_units_unavailable" begin
        url_in = _test_constraint_unit_setup()
        number_of_units = 4
        candidate_units = 3 
        units_unavailable = 1
        unit_availability_factor = 0.5
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["unit", "unit_ab", "number_of_units", number_of_units],
            ["unit", "unit_ab", "units_unavailable", units_unavailable],
            ["unit", "unit_ab", "unit_availability_factor", unit_availability_factor],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        constraint = m.ext[:spineopt].constraints[:units_available]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            key = (unit(:unit_ab), s, t)
            var_u_on = var_units_on[key...]
            var_u_inv_av = var_units_invested_available[key...]
            expected_con = @build_constraint(var_u_on <= number_of_units + var_u_inv_av - units_unavailable)
            con_key = (unit(:unit_ab), s, t)
            con = constraint[con_key...]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
    @testset "constraint_units_available_units_unavailable_default" begin
        url_in = _test_constraint_unit_setup()
        candidate_units = 3
        number_of_units_when_candidates_units = 0 
        units_unavailable = 1
        unit_availability_factor = 0.5
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["unit", "unit_ab", "units_unavailable", units_unavailable],
            ["unit", "unit_ab", "unit_availability_factor", unit_availability_factor],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        constraint = m.ext[:spineopt].constraints[:units_available]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            key = (unit(:unit_ab), s, t)
            var_u_on = var_units_on[key...]
            var_u_inv_av = var_units_invested_available[key...]
            expected_con = @build_constraint(var_u_on <= number_of_units_when_candidates_units + var_u_inv_av - units_unavailable)
            con_key = (unit(:unit_ab), s, t)
            con = constraint[con_key...]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_unit_state_transition()
    @testset "constraint_unit_state_transition" begin
        url_in = _test_constraint_unit_setup()
        object_parameter_values = [
            ["unit", "unit_ab", "online_variable_type", "unit_online_variable_type_integer"],
            ["unit", "unit_ab", "start_up_cost", 1],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
        var_units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
        constraint = m.ext[:spineopt].constraints[:unit_state_transition]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        s0 = stochastic_scenario(:parent)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s1, t1) in zip(scenarios, time_slices)
            path = unique([s0, s1])
            var_key1 = (unit(:unit_ab), s1, t1)
            var_u_on1 = var_units_on[var_key1...]
            var_u_su1 = var_units_started_up[var_key1...]
            var_u_sd1 = var_units_shut_down[var_key1...]
            @testset for (u, t0, t1) in unit_dynamic_time_indices(m; unit=unit(:unit_ab), t_after=t1)
                var_key0 = (u, s0, t0)
                var_u_on0 = get(var_units_on, var_key0, 0)
                con_key = (u, path, t0, t1)
                expected_con = @build_constraint(var_u_on1 - var_u_on0 == var_u_su1 - var_u_sd1)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_units_out_of_service_transition()
    @testset "constraint_units_out_of_service_transition" begin
        url_in = _test_constraint_unit_setup()
        object_parameter_values = [
            ["unit", "unit_ab", "online_variable_type", "unit_online_variable_type_integer"],
            ["unit", "unit_ab", "outage_variable_type", "unit_online_variable_type_integer"],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_out_of_service = m.ext[:spineopt].variables[:units_out_of_service]
        var_units_taken_out_of_service = m.ext[:spineopt].variables[:units_taken_out_of_service]
        var_units_returned_to_service = m.ext[:spineopt].variables[:units_returned_to_service]
        constraint = m.ext[:spineopt].constraints[:units_out_of_service_transition]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        s0 = stochastic_scenario(:parent)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s1, t1) in zip(scenarios, time_slices)
            path = unique([s0, s1])
            var_key1 = (unit(:unit_ab), s1, t1)
            var_u_oos1 = var_units_out_of_service[var_key1...]
            var_u_toos1 = var_units_taken_out_of_service[var_key1...]
            var_u_rts1 = var_units_returned_to_service[var_key1...]
            @testset for (u, t0, t1) in unit_dynamic_time_indices(m; unit=unit(:unit_ab), t_after=t1)
                var_key0 = (u, s0, t0)
                var_u_oos0 = get(var_units_out_of_service, var_key0, 0)
                con_key = (u, path, t0, t1)
                expected_con = @build_constraint(var_u_oos1 - var_u_oos0 == var_u_toos1 - var_u_rts1)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_unit_flow_capacity_simple()
    @testset "constraint_unit_flow_capacity_simple" begin
        url_in = _test_constraint_unit_reserves_setup()
        ucap = 100
        uaf = 0.5
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", ucap],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", ucap],
        ]
        object_parameter_values = [
            ["unit", "unit_ab", "unit_availability_factor", uaf],
            ["model", "instance", "use_tight_compact_formulations", false],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
        var_units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
        constraint = m.ext[:spineopt].constraints[:unit_flow_capacity]
        @test length(constraint) == 4
        s_child = stochastic_scenario(:child)
        s_parent = stochastic_scenario(:parent)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
        s_by_t = Dict(t1h1 => s_parent, t1h2 => s_child)
        case_part = (Object(:min_up_time_gt_time_step, :case), Object(:one, :part))
        @testset for con_key in keys(constraint)
            con = constraint[con_key]
            u, n, d, s, t = con_key
            @test u.name == :unit_ab
            @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
            @test (n.name, s, t) in (
                (:node_group_a, [s_parent], t1h1),
                (:node_group_a, [s_child], t1h2),
                (:node_group_bc, [s_parent], t1h1),
                (:node_group_bc, [s_parent, s_child], t1h2),
            )
            var_u_on_t = var_units_on[u, s_by_t[t], t]
            lhs = if n.name == :node_group_a
                var_unit_flow[u, node(:node_a), d, s_by_t[t], t]
            elseif n.name == :node_group_bc
                var_u_flow_b = var_unit_flow[u, node(:node_b), d, s_parent, t2h]
                var_u_flow_c = var_unit_flow[u, node(:node_c), d, s_by_t[t], t]
                var_u_flow_b + var_u_flow_c
            end
            expected_con = @build_constraint(lhs <= uaf * ucap * var_u_on_t)
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_unit_flow_capacity_tight_and_compact()
    @testset "constraint_unit_flow_capacity_tight_and_compact" begin
        ucap = 100
        uaf = 0.5
        sul = 0.4
        sdl = 0.3
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", ucap],
            ["unit__from_node", ["unit_ab", "node_group_a"], "start_up_limit", sul],
            ["unit__from_node", ["unit_ab", "node_group_a"], "shut_down_limit", sdl],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", ucap],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "start_up_limit", sul],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "shut_down_limit", sdl],
        ]
        @testset for (case_name, part_names) in (
            :min_up_time_gt_time_step => (:one,), :min_up_time_le_time_step => (:one, :two), 
        )
            @testset for (ur, dr) in ((false, false), (false, true), (true, false), (true, true))
                url_in = _test_constraint_unit_reserves_setup()
                mup = unparse_db_value(case_name == :min_up_time_gt_time_step ? Minute(61) : Hour(1))
                object_parameter_values = [
                    ["unit", "unit_ab", "unit_availability_factor", uaf],
                    ["unit", "unit_ab", "min_up_time", mup],
                    ["node", "reserves_a", "downward_reserve", dr],
                    ["node", "reserves_bc", "upward_reserve", ur],
                    ["model", "instance", "use_tight_compact_formulations", true],
                ]
                SpineInterface.import_data(
                    url_in;
                    object_parameter_values=object_parameter_values,
                    relationship_parameter_values=relationship_parameter_values,
                )
                m = run_spineopt(url_in; log_level=0, optimize=false)
                var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
                var_units_on = m.ext[:spineopt].variables[:units_on]
                var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
                var_units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
                constraint = m.ext[:spineopt].constraints[:unit_flow_capacity]
                @test length(constraint) == 4 * length(part_names)
                s_child = stochastic_scenario(:child)
                s_parent = stochastic_scenario(:parent)
                t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
                t2h = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
                s_by_t = Dict(t1h1 => s_parent, t1h2 => s_child)
                case_part = (Object(:min_up_time_gt_time_step, :case), Object(:one, :part))
                @testset for con_key in keys(constraint)
                    con = constraint[con_key]
                    u, n, d, s, t, t_after, case, part = con_key
                    @test u.name == :unit_ab
                    @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
                    @test case.name == case_name
                    @test part.name in part_names
                    @test (n.name, s, t) in (
                        (:node_group_a, [s_parent, s_child], t1h1),
                        (:node_group_a, [s_child], t1h2),
                        (:node_group_bc, [s_parent, s_child], t1h1),
                        (:node_group_bc, [s_parent, s_child], t1h2),
                    )
                    var_u_on_t = var_units_on[u, s_by_t[t], t]
                    var_u_su_t = var_units_started_up[u, s_by_t[t], t]
                    var_u_sd_t_after = try
                        var_units_shut_down[u, s_by_t[t_after], t_after]
                    catch KeyError
                        0
                    end
                    lhs = if n.name == :node_group_a
                        var_u_flow_a = var_unit_flow[u, node(:node_a), d, s_by_t[t], t]
                        var_u_flow_reserves_a = dr ? var_unit_flow[u, node(:reserves_a), d, s_by_t[t], t] : 0
                        var_u_flow_a + var_u_flow_reserves_a
                    elseif n.name == :node_group_bc
                        var_u_flow_b = var_unit_flow[u, node(:node_b), d, s_parent, t2h]
                        var_u_flow_c = var_unit_flow[u, node(:node_c), d, s_by_t[t], t]
                        var_u_flow_reserves_bc = ur ? var_unit_flow[u, node(:reserves_bc), d, s_parent, t] : 0
                        var_u_flow_b + var_u_flow_c + var_u_flow_reserves_bc
                    end
                    var_u_sd_t_after_coeff, var_u_su_t_coeff = if case_name == :min_up_time_gt_time_step
                        1 - sdl, 1 - sul
                    elseif part.name == :one
                        1 - sdl, max(sdl - sul, 0)
                    else
                        max(sul - sdl, 0), 1 - sul
                    end
                    expected_con = @build_constraint(
                        lhs
                        <=
                        + uaf * ucap
                        * (var_u_on_t - var_u_sd_t_after_coeff * var_u_sd_t_after - var_u_su_t_coeff * var_u_su_t)
                    )
                    observed_con = constraint_object(con)
                    @test _is_constraint_equal(observed_con, expected_con)
                end
            end
        end
    end
end

function test_constraint_minimum_operating_point()
    @testset "constraint_minimum_operating_point" begin
        uc = 100
        mop = 0.25
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", uc],
            ["unit__from_node", ["unit_ab", "node_group_a"], "minimum_operating_point", mop],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", uc],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "minimum_operating_point", mop],
        ]
        @testset for (ur, dr) in ((false, false), (false, true), (true, false), (true, true))
            url_in = _test_constraint_unit_reserves_setup()
            object_parameter_values = [
                ["node", "reserves_a", "upward_reserve", ur],
                ["node", "reserves_bc", "downward_reserve", dr],
                ["node", "reserves_a", "is_non_spinning", ur],
                ["node", "reserves_bc", "is_non_spinning", dr],
            ]        
            SpineInterface.import_data(
                url_in;
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_nonspin_units_started_up = m.ext[:spineopt].variables[:nonspin_units_started_up]
            var_nonspin_units_shut_down = m.ext[:spineopt].variables[:nonspin_units_shut_down]
            constraint = m.ext[:spineopt].constraints[:minimum_operating_point]
            @test length(constraint) == 3
            s_child = stochastic_scenario(:child)
            s_parent = stochastic_scenario(:parent)
            t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
            t2h = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
            s_by_t = Dict(t1h1 => s_parent, t1h2 => s_child)
            @testset for con_key in keys(constraint)
                u, n, d, s_path, t = con_key
                @test u.name == :unit_ab
                @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
                @test (n.name, s_path, t) in (
                    (:node_group_a, [s_parent], t1h1),
                    (:node_group_a, [s_child], t1h2),
                    (:node_group_bc, [s_parent, s_child], t2h)
                )
                n.name == :node_group_bc || continue
                lhs = if n.name == :node_group_a
                    (
                        + var_unit_flow[u, node(:node_a), d, s_by_t[t], t]
                        - (ur ? var_unit_flow[u, node(:reserves_a), d, s_by_t[t], t] : 0)
                    )
                elseif n.name == :node_group_bc
                    (
                        + 2 * var_unit_flow[u, node(:node_b), d, s_parent, t2h]
                        + var_unit_flow[u, node(:node_c), d, s_parent, t1h1]
                        + var_unit_flow[u, node(:node_c), d, s_child, t1h2]
                        - (dr ? sum(var_unit_flow[u, node(:reserves_bc), d, s_parent, t] for t in (t1h1, t1h2)) : 0)
                    )
                end
                rhs = if n.name == :node_group_a
                    (
                        + var_units_on[u, s_by_t[t], t]
                        - (ur ? var_nonspin_units_started_up[u, node(:reserves_a), s_by_t[t], t] : 0)
                    )
                elseif n.name == :node_group_bc
                    (
                        + var_units_on[u, s_parent, t1h1] + var_units_on[u, s_child, t1h2]
                        - (dr ? var_nonspin_units_shut_down[u, node(:reserves_bc), s_parent, t1h1] : 0)
                        # NOTE: var_nonspin_units_shut_down[u, node(:reserves_bc), s_parent, t1h2] is not included
                        # because it's not in the stochastic path. The path is (s_parent, t1h1) -> (s_child, t1h2)
                    )
                end
                expected_con = @build_constraint(lhs >= mop * uc * rhs)
                observed_con = constraint_object(constraint[con_key])
                @test _is_constraint_equal(observed_con, expected_con) 
            end
        end
    end
end

function test_constraint_non_spinning_reserves_lower_bound()
    @testset "constraint_non_spinning_reserves_lower_bound" begin
        url_in = _test_constraint_unit_reserves_setup()
        uc = 100
        mop = 0.25
        object_parameter_values = [
            ["node", "reserves_a", "is_non_spinning", true], ["node", "reserves_bc", "is_non_spinning", true]
        ]
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", uc],
            ["unit__from_node", ["unit_ab", "node_group_a"], "minimum_operating_point", mop],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", uc],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "minimum_operating_point", mop],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        constraint = m.ext[:spineopt].constraints[:non_spinning_reserves_lower_bound]
        @test length(constraint) == 3
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_nonspin_units_started_up = m.ext[:spineopt].variables[:nonspin_units_started_up]
        var_nonspin_units_shut_down = m.ext[:spineopt].variables[:nonspin_units_shut_down]
        s_child = stochastic_scenario(:child)
        s_parent = stochastic_scenario(:parent)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
        s_by_t = Dict(t1h1 => s_parent, t1h2 => s_child)
        @testset for con_key in keys(constraint)
            u, n, d, s_path, t = con_key
            @test u.name == :unit_ab
            @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
            @test (n.name, s_path, t) in (
                (:node_group_a, [s_parent], t1h1),
                (:node_group_a, [s_parent, s_child], t1h2),
                (:node_group_bc, [s_parent, s_child], t2h)
            )
            lhs = if n.name == :node_group_a
                var_nonspin_units_shut_down[u, node(:reserves_a), s_by_t[t], t]
            elseif n.name == :node_group_bc
                sum(var_nonspin_units_started_up[u, node(:reserves_bc), s_parent, t] for t in (t1h1, t1h2))
            end
            rhs = if n.name == :node_group_a
                var_unit_flow[u, node(:reserves_a), d, s_by_t[t], t]
            elseif n.name == :node_group_bc
                sum(var_unit_flow[u, node(:reserves_bc), d, s_parent, t] for t in (t1h1, t1h2))
            end
            expected_con = @build_constraint(mop * uc * lhs <= rhs)
            observed_con = constraint_object(constraint[con_key])
            @test _is_constraint_equal(observed_con, expected_con) 
        end
    end
end

function test_constraint_non_spinning_reserves_upper_bounds()
    @testset "constraint_non_spinning_reserves_upper_bounds" begin
        @testset for limit_name in ("start_up_limit", "shut_down_limit")
            constraint_name = Dict(
                "start_up_limit" => :non_spinning_reserves_start_up_upper_bound,
                "shut_down_limit" => :non_spinning_reserves_shut_down_upper_bound,
            )[limit_name]
            url_in = _test_constraint_unit_reserves_setup()
            uc = 100
            l = 0.5
            object_parameter_values = [
                ["node", "reserves_a", "is_non_spinning", true], ["node", "reserves_bc", "is_non_spinning", true]
            ]
            relationship_parameter_values = [
                ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", uc],
                ["unit__from_node", ["unit_ab", "node_group_a"], limit_name, l],
                ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", uc],
                ["unit__to_node", ["unit_ab", "node_group_bc"], limit_name, l],
            ]
            SpineInterface.import_data(
                url_in;
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            constraint = m.ext[:spineopt].constraints[constraint_name]
            @test length(constraint) == 3
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            var_nonspin_units_started_up = m.ext[:spineopt].variables[:nonspin_units_started_up]
            var_nonspin_units_shut_down = m.ext[:spineopt].variables[:nonspin_units_shut_down]
            s_child = stochastic_scenario(:child)
            s_parent = stochastic_scenario(:parent)
            t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
            t2h = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
            s_by_t = Dict(t1h1 => s_parent, t1h2 => s_child)
            @testset for con_key in keys(constraint)
                u, n, d, s_path, t = con_key
                @test u.name == :unit_ab
                @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
                @test (n.name, s_path, t) in (
                    (:node_group_a, [s_parent], t1h1),
                    (:node_group_a, [s_parent, s_child], t1h2),
                    (:node_group_bc, [s_parent, s_child], t2h)
                )
                lhs = if n.name == :node_group_a
                    var_unit_flow[u, node(:reserves_a), d, s_by_t[t], t]
                elseif n.name == :node_group_bc
                    sum(var_unit_flow[u, node(:reserves_bc), d, s_parent, t] for t in (t1h1, t1h2))
                end
                rhs = if n.name == :node_group_a
                    var_nonspin_units_shut_down[u, node(:reserves_a), s_by_t[t], t]
                elseif n.name == :node_group_bc
                    sum(var_nonspin_units_started_up[u, node(:reserves_bc), s_parent, t] for t in (t1h1, t1h2))
                end
                expected_con = @build_constraint(lhs <= l * uc * rhs)
                observed_con = constraint_object(constraint[con_key])
                @test _is_constraint_equal(observed_con, expected_con) 
            end
        end
    end
end

function test_constraint_operating_point_bounds()
    @testset "constraint_operating_point_bounds" begin
        url_in = _test_constraint_unit_setup()
        unit_capacity = 100
        points = [0.1, 0.5, 1.0]
        deltas = [points[1]; [points[i] - points[i - 1] for i in 2:lastindex(points)]]
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        relationships = [["unit__to_node", ["unit_ab", "node_a"]]]
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", unit_capacity],
            ["unit__from_node", ["unit_ab", "node_a"], "operating_points", operating_points],
        ]
        SpineInterface.import_data(
            url_in; relationships=relationships, relationship_parameter_values=relationship_parameter_values 
        )
        # When the parameter ordered_unit_flow_op use its default false value,
        # SpineOpt does not generate this consraint.
        m = run_spineopt(url_in; log_level=0, optimize=false)
        constraint = m.ext[:spineopt].constraints[:operating_point_bounds]
        @test isempty(constraint)
        relationship_parameter_values = [["unit__from_node", ["unit_ab", "node_a"], "ordered_unit_flow_op", true]]
        SpineInterface.import_data(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_unit_flow_op_active = m.ext[:spineopt].variables[:unit_flow_op_active]
        constraint = m.ext[:spineopt].constraints[:operating_point_bounds]
        @test length(constraint) == 6
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            @testset for (i, delta) in enumerate(deltas)
                var_units_on_key = (unit(:unit_ab), s, t)
                var_us_on = var_units_on[var_units_on_key...]
                var_u_flow_op_active_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                var_u_flow_op_active = var_unit_flow_op_active[var_u_flow_op_active_key...]
                expected_con = @build_constraint(var_u_flow_op_active - var_us_on <= 0)
                observed_con_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, [s], t)
                # [s] for a stochastic path from the given scenario s
                observed_con = constraint_object(constraint[observed_con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_operating_point_rank()
    @testset "constraint_operating_point_rank" begin
        url_in = _test_constraint_unit_setup()
        unit_capacity = 100
        points = [0.1, 0.5, 1.0]
        deltas = [points[1]; [points[i] - points[i - 1] for i in 2:lastindex(points)]]
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        relationships = [["unit__to_node", ["unit_ab", "node_a"]]]
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", unit_capacity],
            ["unit__from_node", ["unit_ab", "node_a"], "operating_points", operating_points]
        ]
        SpineInterface.import_data(
            url_in; relationships=relationships, relationship_parameter_values=relationship_parameter_values 
        )
        # When the parameter ordered_unit_flow_op use its default false value,
        # SpineOpt does not generate this consraint.
        m = run_spineopt(url_in; log_level=0, optimize=false)
        constraint = m.ext[:spineopt].constraints[:operating_point_rank]
        @test isempty(constraint)
        relationship_parameter_values = [["unit__from_node", ["unit_ab", "node_a"], "ordered_unit_flow_op", true]]
        SpineInterface.import_data(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow_op_active = m.ext[:spineopt].variables[:unit_flow_op_active]
        constraint = m.ext[:spineopt].constraints[:operating_point_rank]
        @test length(constraint) == 4
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            @testset for (i, delta) in enumerate(deltas)
                var_u_flow_op_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                if i > 1
                    var_u_flow_op_active_key_1 = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                    var_u_flow_op_active_1 = var_unit_flow_op_active[var_u_flow_op_active_key_1...]
                    var_u_flow_op_active_key_2 = (unit(:unit_ab), node(:node_a), direction(:from_node), i-1, s, t)
                    var_u_flow_op_active_2 = var_unit_flow_op_active[var_u_flow_op_active_key_2...]
                    expected_con = @build_constraint(var_u_flow_op_active_1 - var_u_flow_op_active_2 <= 0)
                    observed_con = constraint_object(constraint[var_u_flow_op_active_key_1...])
                    @test _is_constraint_equal(observed_con, expected_con)
                else
                    var_u_flow_op_active_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                    @test get(constraint, var_u_flow_op_active_key, nothing) === nothing
                end
            end
        end
    end
end

function test_constraint_unit_flow_op_bounds()
    @testset "constraint_unit_flow_op_bounds" begin
        url_in = _test_constraint_unit_setup()
        unit_capacity = 100
        points = [0.1, 0.5, 1.0]
        deltas = [points[1]; [points[i] - points[i - 1] for i in 2:lastindex(points)]]
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        relationships = [
            ["unit__to_node", ["unit_ab", "node_a"]],
        ]
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", unit_capacity],
            ["unit__from_node", ["unit_ab", "node_a"], "operating_points", operating_points]
        ]
        SpineInterface.import_data(
            url_in; relationship_parameter_values=relationship_parameter_values, relationships=relationships
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        # When the parameter ordered_unit_flow_op use its default false value,
        # the constraint should use the variable units_on for flow bound.
        var_units_on = m.ext[:spineopt].variables[:units_on]
        constraint = m.ext[:spineopt].constraints[:unit_flow_op_bounds]
        @test length(constraint) == 6
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            @testset for (i, delta) in enumerate(deltas)
                var_u_flow_op_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                var_u_flow_op = var_unit_flow_op[var_u_flow_op_key...]
                var_units_on_key = (unit(:unit_ab), s, t)
                var_us_on = var_units_on[var_units_on_key...]
                expected_con = @build_constraint(var_u_flow_op - delta * var_us_on * unit_capacity <= 0)
                observed_con = constraint_object(constraint[var_u_flow_op_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end

        # When the parameter ordered_unit_flow_op is set to true,
        # the constraint should use the variable unit_flow_op_active for flow limit.
        ordered_unit_flow_op = true
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "ordered_unit_flow_op", ordered_unit_flow_op],
        ]
        SpineInterface.import_data(
            url_in;  
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        var_unit_flow_op_active = m.ext[:spineopt].variables[:unit_flow_op_active]
        constraint = m.ext[:spineopt].constraints[:unit_flow_op_bounds]
        @test length(constraint) == 6
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            @testset for (i, delta) in enumerate(deltas)
                var_u_flow_op_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                var_u_flow_op = var_unit_flow_op[var_u_flow_op_key...]
                var_u_flow_op_active_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                var_u_flow_op_active = var_unit_flow_op_active[var_u_flow_op_active_key...]
                expected_con = @build_constraint(var_u_flow_op - delta * var_u_flow_op_active * unit_capacity <= 0)
                observed_con = constraint_object(constraint[var_u_flow_op_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_unit_flow_op_rank()
    @testset "constraint_unit_flow_op_rank" begin
        url_in = _test_constraint_unit_setup()
        unit_capacity = 100
        points = [0.1, 0.5, 1.0]
        deltas = [points[1]; [points[i] - points[i - 1] for i in 2:lastindex(points)]]
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        relationships = [
            ["unit__to_node", ["unit_ab", "node_a"]],
        ]
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", unit_capacity],
            ["unit__from_node", ["unit_ab", "node_a"], "operating_points", operating_points]
        ]
        SpineInterface.import_data(
            url_in; 
            relationships=relationships, 
            relationship_parameter_values=relationship_parameter_values 
        )

        # When the parameter ordered_unit_flow_op use its default false value,
        # SpineOpt does not generate this consraint.
        m = run_spineopt(url_in; log_level=0, optimize=false)
        constraint = m.ext[:spineopt].constraints[:unit_flow_op_rank]
        @test isempty(constraint)

        ordered_unit_flow_op = true
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "ordered_unit_flow_op", ordered_unit_flow_op],
        ]
        SpineInterface.import_data(
            url_in;  
            relationship_parameter_values=relationship_parameter_values 
        )

        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        var_unit_flow_op_active = m.ext[:spineopt].variables[:unit_flow_op_active]
        constraint = m.ext[:spineopt].constraints[:unit_flow_op_rank]
        @test length(constraint) == 4
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            @testset for (i, delta) in enumerate(deltas)
                var_u_flow_op_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                var_u_flow_op = var_unit_flow_op[var_u_flow_op_key...]
                if i < lastindex(deltas)
                    var_u_flow_op_active_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i+1, s, t)
                    var_u_flow_op_active = var_unit_flow_op_active[var_u_flow_op_active_key...]
                    expected_con = @build_constraint(var_u_flow_op - delta * var_u_flow_op_active * unit_capacity >= 0)
                    observed_con = constraint_object(constraint[var_u_flow_op_key...])
                    @test _is_constraint_equal(observed_con, expected_con)
                else
                    var_u_flow_op_active_key = (unit(:unit_ab), node(:node_a), direction(:from_node), i, s, t)
                    @test get(constraint, var_u_flow_op_active_key, nothing) === nothing
                end
            end
        end
    end
end

function test_constraint_unit_flow_op_sum()
    @testset "constraint_unit_flow_op_sum" begin
        url_in = _test_constraint_unit_setup()
        unit_capacity = 100
        points = [0.1, 0.5, 1.0]
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "operating_points", operating_points],
        ]
        SpineInterface.import_data(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        constraint = m.ext[:spineopt].constraints[:unit_flow_op_sum]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            subkey = (unit(:unit_ab), node(:node_a), direction(:from_node))
            key = (subkey..., s, t)
            var_u_flow = var_unit_flow[key...]
            vars_u_flow_op = [var_unit_flow_op[(subkey..., i, s, t)...] for i in 1:length(points)]
            expected_con = @build_constraint(var_u_flow == sum(vars_u_flow_op))
            observed_con = constraint_object(constraint[key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_ratio_unit_flow()
    @testset "constraint_ratio_unit_flow" begin
        flow_ratio = 0.8
        units_on_coeff = 0.2
        start_flow = 1.3
        class = "unit__node__node"
        relationship = ["unit_ab", "node_a", "node_b"]
        senses_by_prefix = Dict("min" => >=, "fix" => ==, "max" => <=)
        classes_by_prefix = Dict("in" => "unit__from_node", "out" => "unit__to_node")
        @testset for (p, a, b) in (
            ("min", "in", "in"),
            ("fix", "in", "in"),
            ("max", "in", "in"),
            ("min", "in", "out"),
            ("fix", "in", "out"),
            ("max", "in", "out"),
            ("min", "out", "in"),
            ("fix", "out", "in"),
            ("max", "out", "in"),
            ("min", "out", "out"),
            ("fix", "out", "out"),
            ("max", "out", "out"),
        )
            url_in = _test_constraint_unit_setup()
            ratio = join([p, "ratio", a, b, "unit_flow"], "_")
            coeff = join([p, "units_on_coefficient", a, b], "_")
            relationships = [
                [classes_by_prefix[a], ["unit_ab", "node_a"]],
                [classes_by_prefix[b], ["unit_ab", "node_b"]],
                [class, relationship],
            ]
            relationship_parameter_values =[
                [class, relationship, ratio, flow_ratio],
                [class, relationship, coeff, units_on_coeff],
                [class, relationship, "unit_start_flow", start_flow],
            ]
            sense = senses_by_prefix[p]
            SpineInterface.import_data(
                url_in; relationships=relationships, relationship_parameter_values=relationship_parameter_values
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
            constraint = m.ext[:spineopt].constraints[Symbol(ratio)]
            @test length(constraint) == 1
            path = [stochastic_scenario(:parent), stochastic_scenario(:child)]
            t_long = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
            t_short1, t_short2 = time_slice(m; temporal_block=temporal_block(:hourly))
            directions_by_prefix = Dict("in" => direction(:from_node), "out" => direction(:to_node))
            d_a = directions_by_prefix[a]
            d_b = directions_by_prefix[b]
            var_u_flow_b_key = (unit(:unit_ab), node(:node_b), d_b, stochastic_scenario(:parent), t_long)
            var_u_flow_a1_key = (unit(:unit_ab), node(:node_a), d_a, stochastic_scenario(:parent), t_short1)
            var_u_flow_a2_key = (unit(:unit_ab), node(:node_a), d_a, stochastic_scenario(:child), t_short2)
            var_u_on_a1_key = (unit(:unit_ab), stochastic_scenario(:parent), t_short1)
            var_u_on_a2_key = (unit(:unit_ab), stochastic_scenario(:child), t_short2)
            var_u_flow_b = var_unit_flow[var_u_flow_b_key...]
            var_u_flow_a1 = var_unit_flow[var_u_flow_a1_key...]
            var_u_flow_a2 = var_unit_flow[var_u_flow_a2_key...]
            var_u_on_a1 = var_units_on[var_u_on_a1_key...]
            var_u_on_a2 = var_units_on[var_u_on_a2_key...]
            var_u_su_a1 = var_units_started_up[var_u_on_a1_key...]
            var_u_su_a2 = var_units_started_up[var_u_on_a2_key...]
            con_key = (unit(:unit_ab), node(:node_a), node(:node_b), path, t_long)
            sf_sign = if p == "fix"
                if a == "in" && b == "out"
                    1
                elseif a == "out" && b == "in"
                    -1
                else
                    0
                end
            else
                0
            end
            expected_con = SpineOpt.build_sense_constraint(
                var_u_flow_a1 + var_u_flow_a2,
                sense,
                + 2 * flow_ratio * var_u_flow_b
                + units_on_coeff * (var_u_on_a1 + var_u_on_a2)
                + sf_sign * start_flow * (var_u_su_a1 + var_u_su_a2),
            )
            observed_con = constraint_object(constraint[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_total_cumulated_unit_flow()
    @testset "constraint_total_cumulated_unit_flow" begin
        total_cumulated_flow_bound = 100
        senses_by_prefix = Dict("min" => >=, "max" => <=)
        classes_by_prefix = Dict("from_node" => "unit__from_node", "to_node" => "unit__to_node")
        @testset for (p, a) in (
            ("min", "from_node"),
            ("min", "to_node"),
            ("max", "from_node"),
            ("max", "to_node"),
        )
            url_in = _test_constraint_unit_setup()
            cumulated = join([p,"total" , "cumulated", "unit_flow", a], "_")
            relationships = [
                [classes_by_prefix[a], ["unit_ab", "node_a"]],
            ]
            relationship_parameter_values =
                [[classes_by_prefix[a], ["unit_ab", "node_a"], cumulated, total_cumulated_flow_bound]]
            sense = senses_by_prefix[p]
            SpineInterface.import_data(
                url_in;
                relationships=relationships,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            constraint = m.ext[:spineopt].constraints[Symbol(cumulated)]
            @test length(constraint) == 1
            path = [stochastic_scenario(:parent), stochastic_scenario(:child)]
            t_long = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
            t_short1, t_short2 = time_slice(m; temporal_block=temporal_block(:hourly))
            directions_by_prefix = Dict("from_node" => direction(:from_node), "to_node" => direction(:to_node))
            d_a = directions_by_prefix[a]
            var_u_flow_a1_key = (unit(:unit_ab), node(:node_a), d_a, stochastic_scenario(:parent), t_short1)
            var_u_flow_a2_key = (unit(:unit_ab), node(:node_a), d_a, stochastic_scenario(:child), t_short2)
            var_u_flow_a1 = var_unit_flow[var_u_flow_a1_key...]
            var_u_flow_a2 = var_unit_flow[var_u_flow_a2_key...]
            con_key = (unit(:unit_ab), node(:node_a), d_a, path)
            expected_con = SpineOpt.build_sense_constraint(
                var_u_flow_a1 + var_u_flow_a2,
                sense,
                total_cumulated_flow_bound
            )
            observed_con = constraint_object(constraint[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_min_up_time()
    @testset "constraint_min_up_time" begin
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for min_up_minutes in (60, 120, 210)
            url_in = _test_constraint_unit_setup()
            min_up_time = Dict("type" => "duration", "data" => string(min_up_minutes, "m"))
            object_parameter_values =
                [["unit", "unit_ab", "min_up_time", min_up_time], ["model", "instance", "model_end", model_end]]
            SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
            m = run_spineopt(url_in; log_level=0, optimize=false)            
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
            constraint = m.ext[:spineopt].constraints[:min_up_time]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = -(
                length(time_slice(m; temporal_block=temporal_block(:hourly))), round(parent_end, Hour(1)).value
            )
            tail_hours = round(Minute(min_up_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                var_u_on_key = (unit(:unit_ab), s, t)
                var_u_on = var_units_on[var_u_on_key...]
                vars_u_su = [var_units_started_up[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                expected_con = @build_constraint(var_u_on >= sum(vars_u_su))
                con_key = (unit(:unit_ab), path, t)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_units_out_of_service_contiguity()
    @testset "constraint_units_out_of_service_contiguity" begin
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for scheduled_outage_duration_minutes in (60, 120, 210)
            url_in = _test_constraint_unit_setup()
            scheduled_outage_duration = Dict(
                "type" => "duration", "data" => string(scheduled_outage_duration_minutes, "m")
            )
            object_parameter_values = [
                ["unit", "unit_ab", "scheduled_outage_duration", scheduled_outage_duration],
                ["unit", "unit_ab", "outage_variable_type", "unit_online_variable_type_integer"],
                ["model", "instance", "model_end", model_end],                
            ]
            SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
            m = run_spineopt(url_in; log_level=0, optimize=false)            
            var_units_out_of_service = m.ext[:spineopt].variables[:units_out_of_service]
            var_units_taken_out_of_service = m.ext[:spineopt].variables[:units_taken_out_of_service]
            constraint = m.ext[:spineopt].constraints[:units_out_of_service_contiguity]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = -(
                length(time_slice(m; temporal_block=temporal_block(:hourly))), round(parent_end, Hour(1)).value
            )
            tail_hours = round(Minute(scheduled_outage_duration_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                var_u_oos_key = (unit(:unit_ab), s, t)
                var_u_oos = var_units_out_of_service[var_u_oos_key...]
                vars_u_toos = [var_units_taken_out_of_service[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                expected_con = @build_constraint(var_u_oos >= sum(vars_u_toos))
                con_key = (unit(:unit_ab), path, t)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_min_scheduled_outage_duration()
    @testset "constraint_min_scheduled_outage_duration" begin
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for scheduled_outage_duration_minutes in (60, 120, 210)
            url_in = _test_constraint_unit_setup()
            scheduled_outage_duration = Dict(
                "type" => "duration", "data" => string(scheduled_outage_duration_minutes, "m")
            )
            object_parameter_values = [
                ["unit", "unit_ab", "scheduled_outage_duration", scheduled_outage_duration],
                ["unit", "unit_ab", "outage_variable_type", "unit_online_variable_type_integer"],
                ["model", "instance", "model_end", model_end],                
            ]
            SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_units_out_of_service = m.ext[:spineopt].variables[:units_out_of_service]            
            constraint = m.ext[:spineopt].constraints[:min_scheduled_outage_duration]
            constraint_t = current_window(m)
            @test length(constraint) == 2
            s_path = [stochastic_scenario(:parent), stochastic_scenario(:child)]
            scenarios = [[stochastic_scenario(:parent)]; repeat([stochastic_scenario(:child)], 4)]
            time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
            vars_u_oos = [var_units_out_of_service[unit(:unit_ab), s, t] for (s, t) in zip(scenarios, time_slices)]
            @testset for bound in (Object(:lb, :bound), Object(:ub, :bound))
                expected_con = if bound.name == :lb
                    @build_constraint(scheduled_outage_duration_minutes / 60 <= sum(vars_u_oos))
                else
                    @build_constraint(sum(vars_u_oos) <= scheduled_outage_duration_minutes / 60 + 1)
                end
                con_key = (unit(:unit_ab), s_path, constraint_t, bound)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end    
        end
    end
end

function test_constraint_min_up_time_with_non_spinning_reserves()
    @testset "constraint_min_up_time_with_non_spinning_reserves" begin
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for min_up_minutes in (60, 120, 210)
            url_in = _test_constraint_unit_setup()
            min_up_time = Dict("type" => "duration", "data" => string(min_up_minutes, "m"))
            object_parameter_values = [
                ["unit", "unit_ab", "min_up_time", min_up_time],
                ["model", "instance", "model_end", model_end],
                ["node", "node_a", "is_reserve_node", true],
                ["node", "node_a", "is_non_spinning", true],
            ]
            relationship_parameter_values = [
                ["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", 0],
            ]
            SpineInterface.import_data(
                url_in;
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
            var_nonspin_units_shut_down = m.ext[:spineopt].variables[:nonspin_units_shut_down]
            constraint = m.ext[:spineopt].constraints[:min_up_time]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = -(
                length(time_slice(m; temporal_block=temporal_block(:hourly))), round(parent_end, Hour(1)).value
            )
            tail_hours = round(Minute(min_up_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                var_u_on_key = (unit(:unit_ab), s, t)
                var_u_on = var_units_on[var_u_on_key...]
                vars_u_su = [var_units_started_up[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                var_ns_sd_key = (unit(:unit_ab), node(:node_a), s, t)
                var_ns_sd = var_nonspin_units_shut_down[var_ns_sd_key...]
                expected_con = @build_constraint(var_u_on - var_ns_sd >= sum(vars_u_su))
                con_key = (unit(:unit_ab), path, t)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_min_down_time()
    @testset "constraint_min_down_time" begin
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for min_down_minutes in (45, 150, 300)
            url_in = _test_constraint_unit_setup()
            number_of_units = 4
            candidate_units = 3
            min_down_time = Dict("type" => "duration", "data" => string(min_down_minutes, "m"))
            object_parameter_values = [
                ["unit", "unit_ab", "candidate_units", candidate_units],
                ["unit", "unit_ab", "number_of_units", number_of_units],
                ["unit", "unit_ab", "min_down_time", min_down_time],
                ["model", "instance", "model_end", model_end]
            ]
            relationships = [
                ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
                ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
            ]
            SpineInterface.import_data(
                url_in; relationships=relationships, object_parameter_values=object_parameter_values
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
            var_units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
            constraint = m.ext[:spineopt].constraints[:min_down_time]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = length(
                time_slice(m; temporal_block=temporal_block(:hourly))) - round(parent_end, Hour(1)
            ).value
            tail_hours = round(Minute(min_down_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                var_u_inv_av_on_key = (unit(:unit_ab), s, t)
                var_u_inv_av = var_units_invested_available[var_u_inv_av_on_key...]
                var_u_on = var_units_on[var_u_inv_av_on_key...]
                vars_u_sd = [var_units_shut_down[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                expected_con = @build_constraint(number_of_units + var_u_inv_av - var_u_on >= sum(vars_u_sd))
                con_key = (unit(:unit_ab), path, t)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_min_down_time_with_non_spinning_reserves()
    @testset "constraint_min_down_time_with_non_spinning_reserves" begin
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for min_down_minutes in (90, 150, 300)  # TODO: make it work for 45, 75
            url_in = _test_constraint_unit_setup()
            number_of_units = 4
            candidate_units = 3
            min_down_time = Dict("type" => "duration", "data" => string(min_down_minutes, "m"))
            object_parameter_values = [
                ["unit", "unit_ab", "candidate_units", candidate_units],
                ["unit", "unit_ab", "number_of_units", number_of_units],
                ["unit", "unit_ab", "min_down_time", min_down_time],
                ["model", "instance", "model_end", model_end],
                ["node", "node_a", "is_reserve_node", true],
                ["node", "node_a", "is_non_spinning", true],
            ]
            relationships = [
                ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
                ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
            ]
            relationship_parameter_values = [
                ["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", 0],
            ]
            SpineInterface.import_data(
                url_in;
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
            var_units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
            var_nonspin_units_started_up = m.ext[:spineopt].variables[:nonspin_units_started_up]
            constraint = m.ext[:spineopt].constraints[:min_down_time]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = length(
                time_slice(m; temporal_block=temporal_block(:hourly))) - round(parent_end, Hour(1)
            ).value
            tail_hours = round(Minute(min_down_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                var_u_inv_av_on_key = (unit(:unit_ab), s, t)
                var_u_inv_av = var_units_invested_available[var_u_inv_av_on_key...]
                var_u_on = var_units_on[var_u_inv_av_on_key...]
                vars_u_sd = [var_units_shut_down[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                var_ns_su_key = (unit(:unit_ab), node(:node_a), s, t)
                var_ns_su = var_nonspin_units_started_up[var_ns_su_key...]
                expected_con = @build_constraint(
                    number_of_units + var_u_inv_av - var_u_on >= sum(vars_u_sd) + var_ns_su
                )
                con_key = (unit(:unit_ab), path, t)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_units_invested_available()
    @testset "constraint_units_invested_available" begin
        url_in = _test_constraint_unit_setup()
        candidate_units = 7
        object_parameter_values = [["unit", "unit_ab", "candidate_units", candidate_units]]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        constraint = m.ext[:spineopt].constraints[:units_invested_available]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            key = (unit(:unit_ab), s, t)
            var = var_units_invested_available[key...]
            expected_con = @build_constraint(var <= candidate_units)
            con = constraint[key...]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_units_invested_available_mp()
    @testset "constraint_units_invested_available_mp" begin
        url_in = _test_constraint_unit_setup()
        candidate_units = 7
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["model", "instance", "model_type", "spineopt_benders"],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "investments_hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "investments_deterministic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        m_mp = master_model(m)
        var_units_invested_available = m_mp.ext[:spineopt].variables[:units_invested_available]
        constraint = m_mp.ext[:spineopt].constraints[:units_invested_available]
        @test length(constraint) == 2
        time_slices = time_slice(m_mp; temporal_block=temporal_block(:investments_hourly))
        @testset for t in time_slices
            key = (unit(:unit_ab), stochastic_scenario(:parent), t)
            var = var_units_invested_available[key...]
            expected_con = @build_constraint(var <= candidate_units)
            con = constraint[key...]
            observed_con = constraint_object(con)
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_units_invested_transition()
    @testset "constraint_units_invested_transition" begin
        url_in = _test_constraint_unit_setup()
        candidate_units = 4
        object_parameter_values = [["unit", "unit_ab", "candidate_units", candidate_units]]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        var_units_invested = m.ext[:spineopt].variables[:units_invested]
        var_units_mothballed = m.ext[:spineopt].variables[:units_mothballed]
        constraint = m.ext[:spineopt].constraints[:units_invested_transition]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        s0 = stochastic_scenario(:parent)
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        @testset for (s1, t1) in zip(scenarios, time_slices)
            path = unique([s0, s1])
            var_key1 = (unit(:unit_ab), s1, t1)
            var_u_inv_av1 = var_units_invested_available[var_key1...]
            var_u_inv_1 = var_units_invested[var_key1...]
            var_u_moth_1 = var_units_mothballed[var_key1...]
            @testset for (u, t0, t1) in unit_investment_dynamic_time_indices(m; unit=unit(:unit_ab), t_after=t1)
                var_key0 = (u, s0, t0)
                var_u_inv_av0 = get(var_units_invested_available, var_key0, 0)
                con_key = (u, path, t0, t1)
                expected_con = @build_constraint(var_u_inv_av1 - var_u_inv_1 + var_u_moth_1 == var_u_inv_av0)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_units_invested_transition_mp()
    @testset "constraint_units_invested_transition_mp" begin
        url_in = _test_constraint_unit_setup()
        candidate_units = 4
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["model", "instance", "model_type", "spineopt_benders"],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "investments_hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "investments_deterministic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        m_mp = master_model(m)
        var_units_invested_available = m_mp.ext[:spineopt].variables[:units_invested_available]
        var_units_invested = m_mp.ext[:spineopt].variables[:units_invested]
        var_units_mothballed = m_mp.ext[:spineopt].variables[:units_mothballed]
        constraint = m_mp.ext[:spineopt].constraints[:units_invested_transition]
        @test length(constraint) == 2
        s0 = stochastic_scenario(:parent)
        time_slices = time_slice(m_mp; temporal_block=temporal_block(:hourly))
        @testset for t1 in time_slices
            path = [s0]
            var_key1 = (unit(:unit_ab), s0, t1)
            var_u_inv_av1 = var_units_invested_available[var_key1...]
            var_u_inv_1 = var_units_invested[var_key1...]
            var_u_moth_1 = var_units_mothballed[var_key1...]
            @testset for (u, t0, t1) in unit_investment_dynamic_time_indices(m_mp; unit=unit(:unit_ab), t_after=t1)
                var_key0 = (u, s0, t0)
                var_u_inv_av0 = get(var_units_invested_available, var_key0, 0)
                con_key = (u, path, t0, t1)
                expected_con = @build_constraint(var_u_inv_av1 - var_u_inv_1 + var_u_moth_1 == var_u_inv_av0)
                observed_con = constraint_object(constraint[con_key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_unit_lifetime()
    @testset "constraint_unit_lifetime" begin
        candidate_units = 3
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for lifetime_minutes in (30, 180, 240)
            url_in = _test_constraint_unit_setup()
            unit_investment_tech_lifetime = Dict("type" => "duration", "data" => string(lifetime_minutes, "m"))
            object_parameter_values = [
                ["unit", "unit_ab", "candidate_units", candidate_units],
                ["unit", "unit_ab", "unit_investment_tech_lifetime", unit_investment_tech_lifetime],
                ["model", "instance", "model_end", model_end],
            ]
            relationships = [
                ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
                ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
            ]
            SpineInterface.import_data(
                url_in; relationships=relationships, object_parameter_values=object_parameter_values
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
            var_units_invested = m.ext[:spineopt].variables[:units_invested]
            constraint = m.ext[:spineopt].constraints[:unit_lifetime]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = length(
                time_slice(m; temporal_block=temporal_block(:hourly))) - round(parent_end, Hour(1)
            ).value
            tail_hours = round(Minute(lifetime_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                key = (unit(:unit_ab), path, t)
                var_u_inv_av_key = (unit(:unit_ab), s, t)
                var_u_inv_av = var_units_invested_available[var_u_inv_av_key...]
                vars_u_inv = [var_units_invested[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                expected_con = @build_constraint(var_u_inv_av >= sum(vars_u_inv))
                observed_con = constraint_object(constraint[key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_unit_lifetime_sense()
    @testset "constraint_unit_lifetime_sense" begin
        candidate_units = 3
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        lifetime_minutes = 240
        senses = Dict(">=" => >=, "==" => ==, "<=" => <=)
        url_in = _test_constraint_unit_setup()
        unit_investment_tech_lifetime = Dict("type" => "duration", "data" => string(lifetime_minutes, "m"))
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        @testset for (sense_key, sense_value) in senses
            object_parameter_values = [
                ["unit", "unit_ab", "candidate_units", candidate_units],
                ["unit", "unit_ab", "unit_investment_tech_lifetime", unit_investment_tech_lifetime],
                ["unit", "unit_ab", "unit_investment_lifetime_sense", sense_key],
                ["model", "instance", "model_end", model_end],
            ]
            SpineInterface.import_data(
                url_in; relationships=relationships, object_parameter_values=object_parameter_values
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
            var_units_invested = m.ext[:spineopt].variables[:units_invested]
            constraint = m.ext[:spineopt].constraints[:unit_lifetime]
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = length(
                time_slice(m; temporal_block=temporal_block(:hourly))) - round(parent_end, Hour(1)
            ).value
            tail_hours = round(Minute(lifetime_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:child)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m; temporal_block=temporal_block(:hourly)))
                reverse(history_time_slice(m; temporal_block=temporal_block(:hourly)))
            ][1:(head_hours + tail_hours)]
            h = length(constraint)
            s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
            s, t = s_set[1], t_set[1]
            path = reverse(unique(s_set))
            key = (unit(:unit_ab), path, t)
            var_u_inv_av_key = (unit(:unit_ab), s, t)
            var_u_inv_av = var_units_invested_available[var_u_inv_av_key...]
            vars_u_inv = [var_units_invested[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
            expected_con = SpineOpt.build_sense_constraint(var_u_inv_av - sum(vars_u_inv), sense_value, 0)
            observed_con = constraint_object(constraint[key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_unit_lifetime_mp()
    @testset "constraint_unit_lifetime_mp" begin
        candidate_units = 3
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T05:00:00")
        @testset for lifetime_minutes in (30, 180, 240)
            url_in = _test_constraint_unit_setup()
            unit_investment_tech_lifetime = Dict("type" => "duration", "data" => string(lifetime_minutes, "m"))
            object_parameter_values = [
                ["unit", "unit_ab", "candidate_units", candidate_units],
                ["unit", "unit_ab", "unit_investment_tech_lifetime", unit_investment_tech_lifetime],
                ["model", "instance", "model_end", model_end],
                ["model", "instance", "model_type", "spineopt_benders"],
            ]
            relationships = [
                ["unit__investment_temporal_block", ["unit_ab", "investments_hourly"]],
                ["unit__investment_stochastic_structure", ["unit_ab", "investments_deterministic"]],
            ]
            SpineInterface.import_data(
                url_in; relationships=relationships, object_parameter_values=object_parameter_values
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            m_mp = master_model(m)
            var_units_invested_available = m_mp.ext[:spineopt].variables[:units_invested_available]
            var_units_invested = m_mp.ext[:spineopt].variables[:units_invested]
            constraint = m_mp.ext[:spineopt].constraints[:unit_lifetime]
            @test length(constraint) == 5
            parent_end = stochastic_scenario_end(
                stochastic_structure=stochastic_structure(:stochastic),
                stochastic_scenario=stochastic_scenario(:parent),
            )
            head_hours = length(time_slice(m_mp; temporal_block=temporal_block(:investments_hourly))) - Hour(1).value
            tail_hours = round(Minute(lifetime_minutes), Hour(1)).value
            scenarios = [
                repeat([stochastic_scenario(:parent)], head_hours)
                repeat([stochastic_scenario(:parent)], tail_hours)
            ]
            time_slices = [
                reverse(time_slice(m_mp; temporal_block=temporal_block(:investments_hourly)))
                reverse(history_time_slice(m_mp; temporal_block=temporal_block(:investments_hourly)))
            ][1:(head_hours + tail_hours)]
            @testset for h in 1:length(constraint)
                s_set, t_set = scenarios[h:(h + tail_hours - 1)], time_slices[h:(h + tail_hours - 1)]
                s, t = s_set[1], t_set[1]
                path = reverse(unique(s_set))
                key = (unit(:unit_ab), path, t)
                var_u_inv_av_key = (unit(:unit_ab), s, t)
                var_u_inv_av = var_units_invested_available[var_u_inv_av_key...]
                vars_u_inv = [var_units_invested[unit(:unit_ab), s, t] for (s, t) in zip(s_set, t_set)]
                expected_con = @build_constraint(var_u_inv_av >= sum(vars_u_inv))
                observed_con = constraint_object(constraint[key...])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_ramp_up()
    @testset "constraint_ramp_up" begin
        rul = 0.8
        sul = 0.5
        uc = 200
        mop = 0.2
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_group_a"], "ramp_up_limit", rul],
            ["unit__from_node", ["unit_ab", "node_group_a"], "start_up_limit", sul],
            ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", uc],
            ["unit__from_node", ["unit_ab", "node_group_a"], "minimum_operating_point", mop],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "ramp_up_limit", rul],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "start_up_limit", sul],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", uc],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "minimum_operating_point", mop],
        ]
        @testset for (ur, dr) in ((false, false), (false, true), (true, false), (true, true))
            url_in = _test_constraint_unit_reserves_setup()
            object_parameter_values = [
                ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "3h")],
                ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T06:00:00")],
                ["node", "reserves_a", "downward_reserve", dr],
                ["node", "reserves_bc", "upward_reserve", ur],
            ]
            SpineInterface.import_data(
                url_in;
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
            constraint = m.ext[:spineopt].constraints[:ramp_up]
            @test length(constraint) == 4
            t3h0, t3h1, t3h2 = vcat(
                history_time_slice(m; temporal_block=temporal_block(:hourly)),
                time_slice(m; temporal_block=temporal_block(:hourly)),
            )
            t2h0, t2h1, t2h2, t2h3 = vcat(
                history_time_slice(m; temporal_block=temporal_block(:two_hourly)),
                time_slice(m; temporal_block=temporal_block(:two_hourly)),
            )
            s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
            s_by_t = Dict(
                t3h0 => s_parent,
                t3h1 => s_parent,
                t3h2 => s_child,
                t2h0 => s_parent,
                t2h1 => s_parent,
                t2h2 => s_child,
                t2h3 => s_child,
            )
            overlap_2hourly = Dict(t2h0 => 2.0/3, t2h1 => 2.0/3, t2h2 => 1.0/3, t2h3 => 2.0/3)

            @testset for con_key in keys(constraint)
                u, n, d, s, t_before, t_after = con_key
                @test u.name == :unit_ab
                @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
                @test (s, t_before, t_after) in (([s_parent], t3h0, t3h1), ([s_parent, s_child], t3h1, t3h2))
                lhs = if n.name == :node_group_a
                    n_a, r_a = node(:node_a), node(:reserves_a)
                    (
                        + var_unit_flow[u, n_a, d, s_by_t[t_after], t_after]
                        - var_unit_flow[u, n_a, d, s_by_t[t_before], t_before]
                        + (dr ? var_unit_flow[u, r_a, d, s_by_t[t_after], t_after] : 0)
                    )
                elseif n.name == :node_group_bc
                    n_b, n_c, r_bc = node(:node_b), node(:node_c), node(:reserves_bc)
                    var_u_flow_c_delta = (
                        + var_unit_flow[u, n_c, d, s_by_t[t_after], t_after]
                        - var_unit_flow[u, n_c, d, s_by_t[t_before], t_before]
                    )
                    var_u_flow_b_t_delta = if t_after == t3h1
                        (
                            + overlap_2hourly[t2h1] * var_unit_flow[u, n_b, d, s_parent, t2h1]
                            + overlap_2hourly[t2h2] * var_unit_flow[u, n_b, d, s_parent, t2h2]
                            - overlap_2hourly[t2h0] * var_unit_flow[u, n_b, d, s_parent, t2h0]
                        )
                    elseif t_after == t3h2
                        (
                            + overlap_2hourly[t2h3] * var_unit_flow[u, n_b, d, s_parent, t2h3]
                            - overlap_2hourly[t2h1] * var_unit_flow[u, n_b, d, s_parent, t2h1]
                            # - var_unit_flow[u, n_b, d, s_parent, t2h2]
                        )
                    end
                    (
                        + var_u_flow_c_delta + var_u_flow_b_t_delta
                        + (ur ? var_unit_flow[u, r_bc, d, s_parent, t_after] : 0)
                    )
                end
                var_u_on_t_after = var_units_on[u, s_by_t[t_after], t_after]
                var_u_on_t_before =var_units_on[u, s_by_t[t_before], t_before]
                var_u_su_t_after = var_units_started_up[u, s_by_t[t_after], t_after]
                expected_con = @build_constraint(
                    + lhs
                    <=
                    + uc
                        * ((sul - mop) * var_u_su_t_after + mop  * var_u_on_t_after - mop * var_u_on_t_before
                        + 3 * 0.5 * rul * var_u_on_t_before + 3 * 0.5 * rul * var_u_on_t_after)
                )
                observed_con = constraint_object(constraint[con_key])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_ramp_down()
    @testset "constraint_ramp_down" begin
        rdl = 0.8
        sdl = 0.5
        uc = 200
        mop = 0.2
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_group_a"], "ramp_down_limit", rdl],
            ["unit__from_node", ["unit_ab", "node_group_a"], "shut_down_limit", sdl],
            ["unit__from_node", ["unit_ab", "node_group_a"], "unit_capacity", uc],
            ["unit__from_node", ["unit_ab", "node_group_a"], "minimum_operating_point", mop],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "ramp_down_limit", rdl],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "shut_down_limit", sdl],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "unit_capacity", uc],
            ["unit__to_node", ["unit_ab", "node_group_bc"], "minimum_operating_point", mop],
        ]
        @testset for (ur, dr) in ((false, false), (false, true), (true, false), (true, true))
            url_in = _test_constraint_unit_reserves_setup()
            object_parameter_values = [
                ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "3h")],
                ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T06:00:00")],
                ["node", "reserves_a", "upward_reserve", ur],
                ["node", "reserves_bc", "downward_reserve", dr],
            ]
            SpineInterface.import_data(
                url_in;
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
            constraint = m.ext[:spineopt].constraints[:ramp_down]
            @test length(constraint) == 4
            t3h0, t3h1, t3h2 = vcat(
                history_time_slice(m; temporal_block=temporal_block(:hourly)),
                time_slice(m; temporal_block=temporal_block(:hourly)),
            )
            t2h0, t2h1, t2h2, t2h3 = vcat(
                history_time_slice(m; temporal_block=temporal_block(:two_hourly)),
                time_slice(m; temporal_block=temporal_block(:two_hourly)),
            )
            s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
            s_by_t = Dict(
                t3h0 => s_parent,
                t3h1 => s_parent,
                t3h2 => s_child,
                t2h0 => s_parent,
                t2h1 => s_parent,
                t2h2 => s_child,
                t2h3 => s_child,
            )
            overlap_2hourly = Dict(t2h0 => 2.0/3, t2h1 => 2.0/3, t2h2 => 1.0/3, t2h3 => 2.0/3)

            @testset for con_key in keys(constraint)
                u, n, d, s, t_before, t_after = con_key
                @test u.name == :unit_ab
                @test (n.name, d.name) in ((:node_group_a, :from_node), (:node_group_bc, :to_node))
                @test (s, t_before, t_after) in (([s_parent], t3h0, t3h1), ([s_parent, s_child], t3h1, t3h2))
                lhs = if n.name == :node_group_a
                    n_a, r_a = node(:node_a), node(:reserves_a)
                    (
                        + var_unit_flow[u, n_a, d, s_by_t[t_before], t_before]
                        - var_unit_flow[u, n_a, d, s_by_t[t_after], t_after]
                        + (ur ? var_unit_flow[u, r_a, d, s_by_t[t_after], t_after] : 0)
                    )
                elseif n.name == :node_group_bc
                    n_b, n_c, r_bc = node(:node_b), node(:node_c), node(:reserves_bc)
                    var_u_flow_c_delta =  (
                        + var_unit_flow[u, n_c, d, s_by_t[t_before], t_before]
                        - var_unit_flow[u, n_c, d, s_by_t[t_after], t_after]
                    )
                    var_u_flow_b_t_delta = if t_after == t3h1
                        (
                            + overlap_2hourly[t2h0] * var_unit_flow[u, n_b, d, s_parent, t2h0]
                            - overlap_2hourly[t2h1] * var_unit_flow[u, n_b, d, s_parent, t2h1]
                            - overlap_2hourly[t2h2] * var_unit_flow[u, n_b, d, s_parent, t2h2]
                        )
                    elseif t_after == t3h2
                        (
                            + overlap_2hourly[t2h1] * var_unit_flow[u, n_b, d, s_parent, t2h1]
                            - overlap_2hourly[t2h3] * var_unit_flow[u, n_b, d, s_parent, t2h3]
                        )
                    end
                    (
                        + var_u_flow_c_delta + var_u_flow_b_t_delta
                        + (dr ? var_unit_flow[u, r_bc, d, s_parent, t_after] : 0)
                    )
                end
                # units on and units shut down variables
                var_u_on_t_after = var_units_on[u, s_by_t[t_after], t_after]
                var_u_on_t_before = var_units_on[u, s_by_t[t_before], t_before]
                var_u_sd_t_after = var_units_shut_down[u, s_by_t[t_after], t_after]
                expected_con = @build_constraint(
                    + lhs
                    <=
                    + uc
                    * ((sdl - mop) * var_u_sd_t_after + mop * var_u_on_t_before - mop * var_u_on_t_after
                        + 3 * 0.5 * rdl * var_u_on_t_before + 3 * 0.5 * rdl * var_u_on_t_after)
                )
                observed_con = constraint_object(constraint[con_key])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
end

function test_constraint_user_constraint()
    @testset "constraint_user_constraint(single unit)" begin
        @testset for sense in ("==", ">=", "<=")
            url_in = _test_constraint_unit_setup()
            rhs = 40
            unit_flow_coefficient_a = 25
            unit_flow_coefficient_b = 30
            units_on_coefficient = 20
            units_started_up_coefficient = 35
            objects = [["user_constraint", "constraint_x"]]
            relationships = [
                ["unit__from_node__user_constraint", ["unit_ab", "node_a", "constraint_x"]],
                ["unit__to_node__user_constraint", ["unit_ab", "node_b", "constraint_x"]],
                ["unit__user_constraint", ["unit_ab", "constraint_x"]],
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
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
            constraint = m.ext[:spineopt].constraints[:user_constraint]
            @test length(constraint) == 1
            key_a = (unit(:unit_ab), node(:node_a), direction(:from_node))
            key_b = (unit(:unit_ab), node(:node_b), direction(:to_node))
            s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
            t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
            t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
            expected_con = SpineOpt.build_sense_constraint(
                + unit_flow_coefficient_a
                * (var_unit_flow[key_a..., s_parent, t1h1] + var_unit_flow[key_a..., s_child, t1h2]) +
                2 * unit_flow_coefficient_b * var_unit_flow[key_b..., s_parent, t2h] +
                units_on_coefficient
                * (var_units_on[unit(:unit_ab), s_parent, t1h1] + var_units_on[unit(:unit_ab), s_child, t1h2]) +
                units_started_up_coefficient * (
                    var_units_started_up[unit(:unit_ab), s_parent, t1h1]
                    + var_units_started_up[unit(:unit_ab), s_child, t1h2]
                ),
                Symbol(sense),
                2 * rhs,
            )
            con_key = (user_constraint(:constraint_x), [s_parent, s_child], t2h)
            observed_con = constraint_object(constraint[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_user_constraint_with_unit_operating_segments()
    @testset "constraint_user_constraint_with_unit_operating_segments" begin
        @testset for sense in ("==", ">=", "<=")
            url_in = _test_constraint_unit_setup()
            rhs = 40
            unit_flow_coefficient_a = 25
            unit_flow_coefficient_b = 30
            units_on_coefficient = 20
            units_started_up_coefficient = 35
            points = [0.1, 0.5, 1.0]
            operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
            objects = [["user_constraint", "constraint_x"]]
            relationships = [
                ["unit__from_node__user_constraint", ["unit_ab", "node_a", "constraint_x"]],
                ["unit__to_node__user_constraint", ["unit_ab", "node_b", "constraint_x"]],
                ["unit__user_constraint", ["unit_ab", "constraint_x"]],
            ]
            object_parameter_values = [
                ["user_constraint", "constraint_x", "constraint_sense", Symbol(sense)],
                ["user_constraint", "constraint_x", "right_hand_side", rhs],
            ]
            relationship_parameter_values = [
                ["unit__from_node", ["unit_ab", "node_a"], "operating_points", operating_points],
                ["unit__to_node", ["unit_ab", "node_b"], "operating_points", operating_points],
                [relationships[1]..., "unit_flow_coefficient", unit_flow_coefficient_a],
                [relationships[2]..., "unit_flow_coefficient", unit_flow_coefficient_b],
                [relationships[3]..., "units_on_coefficient", units_on_coefficient],
                [relationships[3]..., "units_started_up_coefficient", units_started_up_coefficient],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in; log_level=0, optimize=false)
            var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
            var_units_on = m.ext[:spineopt].variables[:units_on]
            var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
            constraint = m.ext[:spineopt].constraints[:user_constraint]
            @test length(constraint) == 1
            key_a = (unit(:unit_ab), node(:node_a), direction(:from_node))
            key_b = (unit(:unit_ab), node(:node_b), direction(:to_node))
            s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
            t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
            t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
            expected_con = SpineOpt.build_sense_constraint(
                + unit_flow_coefficient_a * sum(
                    var_unit_flow_op[key_a..., i, s_parent, t1h1] + var_unit_flow_op[key_a..., i, s_child, t1h2]
                    for i in 1:3
                )
                + 2 * sum(unit_flow_coefficient_b * var_unit_flow_op[key_b..., i, s_parent, t2h] for i in 1:3)
                + units_on_coefficient
                * (var_units_on[unit(:unit_ab), s_parent, t1h1] + var_units_on[unit(:unit_ab), s_child, t1h2])
                + units_started_up_coefficient * (
                    + var_units_started_up[unit(:unit_ab), s_parent, t1h1]
                    + var_units_started_up[unit(:unit_ab), s_child, t1h2]
                ),
                Symbol(sense),
                2 * rhs,
            )
            con_key = (user_constraint(:constraint_x), [s_parent, s_child], t2h)
            observed_con = constraint_object(constraint[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function test_constraint_ratio_unit_flow_fix_ratio_pw()
    @testset "constraint_ratio_unit_flow_fix_ratio_pw" begin
        url_in = _test_constraint_unit_setup()
        fix_units_on_coefficient_in_out = 200
        unit_start_flow = 100
        points = [0.1, 0.5, 1.0]
        inc_hrs = [10, 20, 30]
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        fix_ratio_in_out_unit_flow = Dict("type" => "array", "value_type" => "float", "data" => inc_hrs)
        relationships = [["unit__node__node", ["unit_ab", "node_a", "node_b"]]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "operating_points", operating_points],
            [relationships[1]..., "fix_ratio_in_out_unit_flow", fix_ratio_in_out_unit_flow],
            [relationships[1]..., "fix_units_on_coefficient_in_out", fix_units_on_coefficient_in_out],
            [relationships[1]..., "unit_start_flow", unit_start_flow],
        ]
        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
        constraint = m.ext[:spineopt].constraints[:fix_ratio_in_out_unit_flow]
        @test length(constraint) == 1
        key_a = (unit(:unit_ab), node(:node_a), direction(:from_node))
        key_b = (unit(:unit_ab), node(:node_b), direction(:to_node))
        key_u_a_b = (unit(:unit_ab), node(:node_a), node(:node_b))
        s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        expected_con = @build_constraint(
            + var_unit_flow[key_a..., s_parent, t1h1] + var_unit_flow[key_a..., s_child, t1h2]
            ==
            + 2 * sum(inc_hrs[i] * var_unit_flow_op[key_b..., i, s_parent, t2h] for i in 1:3)
            + fix_units_on_coefficient_in_out
            * (var_units_on[unit(:unit_ab), s_parent, t1h1] + var_units_on[unit(:unit_ab), s_child, t1h2])
            + unit_start_flow * (
                + var_units_started_up[unit(:unit_ab), s_parent, t1h1]
                + var_units_started_up[unit(:unit_ab), s_child, t1h2]
            )
        )
        con_key = (key_u_a_b..., [s_parent, s_child], t2h)
        observed_con = constraint_object(constraint[con_key...])
        @test _is_constraint_equal(observed_con, expected_con)
    end
end

function test_constraint_ratio_unit_flow_fix_ratio_pw_simple()
    @testset "constraint_ratio_unit_flow_fix_ratio_pw_simple" begin
        url_in = _test_constraint_unit_setup()
        fix_units_on_coefficient_in_out = 200
        unit_start_flow = 0
        points = [0.1, 0.5, 1.0]
        inc_hrs = 10
        operating_points = Dict("type" => "array", "value_type" => "float", "data" => points)
        relationships = [["unit__node__node", ["unit_ab", "node_a", "node_b"]]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "operating_points", operating_points],
            [relationships[1]..., "fix_ratio_in_out_unit_flow", inc_hrs],
            [relationships[1]..., "fix_units_on_coefficient_in_out", fix_units_on_coefficient_in_out],
            [relationships[1]..., "unit_start_flow", unit_start_flow],
        ]
        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
        constraint = m.ext[:spineopt].constraints[:fix_ratio_in_out_unit_flow]
        @test length(constraint) == 1
        key_a = (unit(:unit_ab), node(:node_a), direction(:from_node))
        key_b = (unit(:unit_ab), node(:node_b), direction(:to_node))
        key_u_a_b = (unit(:unit_ab), node(:node_a), node(:node_b))
        s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        expected_con = @build_constraint(
            + var_unit_flow[key_a..., s_parent, t1h1] + var_unit_flow[key_a..., s_child, t1h2]
            ==
            + 2 * sum(inc_hrs * var_unit_flow_op[key_b..., i, s_parent, t2h] for i in 1:3)
            + fix_units_on_coefficient_in_out
            * (var_units_on[unit(:unit_ab), s_parent, t1h1] + var_units_on[unit(:unit_ab), s_child, t1h2])
        )
        con_key = (key_u_a_b..., [s_parent, s_child], t2h)
        observed_con = constraint_object(constraint[con_key...])
        @test _is_constraint_equal(observed_con, expected_con)
    end
end

function test_constraint_ratio_unit_flow_fix_ratio_pw_simple2()
    @testset "constraint_ratio_unit_flow_fix_ratio_pw_simple2" begin
        url_in = _test_constraint_unit_setup()
        fix_units_on_coefficient_in_out = 200
        unit_start_flow = 0
        inc_hrs = 10
        relationships = [["unit__node__node", ["unit_ab", "node_a", "node_b"]]]
        relationship_parameter_values = [
            [relationships[1]..., "fix_ratio_in_out_unit_flow", inc_hrs],
            [relationships[1]..., "fix_units_on_coefficient_in_out", fix_units_on_coefficient_in_out],
            [relationships[1]..., "unit_start_flow", unit_start_flow],
        ]
        SpineInterface.import_data(
            url_in;
            relationships=relationships,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_unit_flow_op = m.ext[:spineopt].variables[:unit_flow_op]
        var_units_on = m.ext[:spineopt].variables[:units_on]
        var_units_started_up = m.ext[:spineopt].variables[:units_started_up]
        constraint = m.ext[:spineopt].constraints[:fix_ratio_in_out_unit_flow]
        @test length(constraint) == 1
        key_a = (unit(:unit_ab), node(:node_a), direction(:from_node))
        key_b = (unit(:unit_ab), node(:node_b), direction(:to_node))
        key_u_a_b = (unit(:unit_ab), node(:node_a), node(:node_b))
        s_parent, s_child = stochastic_scenario(:parent), stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        expected_con = @build_constraint(
            + var_unit_flow[key_a..., s_parent, t1h1] + var_unit_flow[key_a..., s_child, t1h2]
            == 2 * inc_hrs * var_unit_flow[key_b..., s_parent, t2h]
            + fix_units_on_coefficient_in_out
            * (var_units_on[unit(:unit_ab), s_parent, t1h1] + var_units_on[unit(:unit_ab), s_child, t1h2])
        )
        con_key = (key_u_a_b..., [s_parent, s_child], t2h)
        observed_con = constraint_object(constraint[con_key...])
        @test _is_constraint_equal(observed_con, expected_con)
    end
end

@testset "unit-based constraints" begin
    test_constraint_units_available()
    test_constraint_units_available_units_unavailable()
    test_constraint_unit_state_transition()
    test_constraint_unit_flow_capacity_simple()
    test_constraint_unit_flow_capacity_tight_and_compact()
    test_constraint_minimum_operating_point()
    test_constraint_operating_point_bounds()
    test_constraint_operating_point_rank()
    test_constraint_unit_flow_op_bounds()
    test_constraint_unit_flow_op_rank()
    test_constraint_unit_flow_op_sum()
    test_constraint_ratio_unit_flow()
    test_constraint_total_cumulated_unit_flow()
    test_constraint_min_up_time()
    test_constraint_units_out_of_service_contiguity()
    test_constraint_min_scheduled_outage_duration()
    test_constraint_min_up_time_with_non_spinning_reserves()
    test_constraint_min_down_time()
    test_constraint_min_down_time_with_non_spinning_reserves()
    test_constraint_units_invested_available()
    test_constraint_units_invested_available_mp()
    test_constraint_units_invested_transition()
    test_constraint_units_invested_transition_mp()
    test_constraint_unit_lifetime()
    test_constraint_unit_lifetime_sense()
    test_constraint_unit_lifetime_mp()
    test_constraint_ramp_up()
    test_constraint_ramp_down()
    test_constraint_non_spinning_reserves_lower_bound()
    test_constraint_non_spinning_reserves_upper_bounds()
    test_constraint_user_constraint()
    test_constraint_user_constraint_with_unit_operating_segments()
    test_constraint_ratio_unit_flow_fix_ratio_pw()
    test_constraint_ratio_unit_flow_fix_ratio_pw_simple()
    test_constraint_ratio_unit_flow_fix_ratio_pw_simple2()
end
