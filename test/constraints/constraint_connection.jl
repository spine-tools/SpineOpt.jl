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

@testset "connection-based constraints" begin
    url_in = "sqlite:///$(@__DIR__)/test.sqlite"
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
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario", 
                ["stochastic", "parent"], 
                "stochastic_scenario_end", 
                Dict("type" => "duration", "data" => "1h")
            ]
        ]
    )
    @testset "constraint_connection_flow_capacity" begin
        connection_capacity = 200
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        relationship_parameter_values = [
            ["connection__from_node", ["connection_ab", "node_a"], "connection_capacity", connection_capacity]
        ]
        db_api.import_data_to_url(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        var_connection_flow = m.ext[:variables][:connection_flow]
        constraint = m.ext[:constraints][:connection_flow_capacity]
        @test length(constraint) == 2
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(temporal_block=temporal_block(:hourly))
        @testset for (s, t) in zip(scenarios, time_slices)
            key = (connection(:connection_ab), node(:node_a), direction(:from_node), s, t)
            var_conn_flow = var_connection_flow[key...]
            expected_con = @build_constraint(var_conn_flow <= connection_capacity)
            con_key = (connection(:connection_ab), node(:node_a), direction(:from_node), [s], t)
            observed_con = constraint_object(constraint[con_key])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
    @testset "constraint_connection_flow_ptdf" begin
        # TODO: node_ptdf_threshold
        conn_r = 0.9
        conn_x = 0.1
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
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
            ["connection", "connection_ab", "connection_monitored", "value_true"],
            ["connection", "connection_ab", "connection_reactance", conn_x],
            ["connection", "connection_ab", "connection_resistance", conn_r],
            ["connection", "connection_bc", "connection_monitored", "value_true"],
            ["connection", "connection_bc", "connection_reactance", conn_x],
            ["connection", "connection_bc", "connection_resistance", conn_r],
            ["connection", "connection_ca", "connection_monitored", "value_true"],
            ["connection", "connection_ca", "connection_reactance", conn_x],
            ["connection", "connection_ca", "connection_resistance", conn_r],
            ["commodity", "electricity", "commodity_physics", "commodity_physics_ptdf"],
            ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
        ]
        relationship_parameter_values = [
            ["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ca", "node_a", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ca", "node_c", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
        ]
        db_api.import_data_to_url(
            url_in; 
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0)
        var_connection_flow = m.ext[:variables][:connection_flow]
        var_node_injection = m.ext[:variables][:node_injection]
        constraint = m.ext[:constraints][:connection_flow_ptdf]
        @test length(constraint) == 5
        @testset for (conn_name, n_to_name, n_inj_name, scen_names, t_block) in (
                (:connection_ab, :node_b, :node_b, (:parent,), :two_hourly),
                (:connection_bc, :node_c, :node_c, (:parent, :child), :hourly),
                (:connection_ca, :node_a, :node_c, (:parent, :child), :hourly)
            )
            conn = connection(conn_name)
            n_to = node(n_to_name)
            n_inj = node(n_inj_name)
            scenarios = (stochastic_scenario(s) for s in scen_names)
            time_slices = time_slice(temporal_block=temporal_block(t_block))
            @testset for (s, t) in zip(scenarios, time_slices)
                var_conn_flow_to = var_connection_flow[conn, n_to, direction(:to_node), s, t]
                var_conn_flow_from = var_connection_flow[conn, n_to, direction(:from_node), s, t]
                var_n_inj = var_node_injection[n_inj, s, t]
                ptdf_val = SpineOpt.ptdf(connection=conn, node=n_inj)
                expected_con = @build_constraint(var_conn_flow_to - var_conn_flow_from == ptdf_val * var_n_inj)
                observed_con = constraint_object(constraint[conn, n_to, [s], t])
                @test _is_constraint_equal(observed_con, expected_con)
            end
        end
    end
    @testset "constraint_connection_flow_lodf" begin
        conn_r = 0.9
        conn_x = 0.1
        conn_emergency_cap_ab = 80
        conn_emergency_cap_bc = 100
        conn_emergency_cap_ca = 150
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
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
            ["connection", "connection_ab", "connection_monitored", "value_true"],
            ["connection", "connection_ab", "connection_reactance", conn_x],
            ["connection", "connection_ab", "connection_resistance", conn_r],
            ["connection", "connection_bc", "connection_monitored", "value_true"],
            ["connection", "connection_bc", "connection_reactance", conn_x],
            ["connection", "connection_bc", "connection_resistance", conn_r],
            ["connection", "connection_ca", "connection_monitored", "value_true"],
            ["connection", "connection_ca", "connection_reactance", conn_x],
            ["connection", "connection_ca", "connection_resistance", conn_r],
            ["commodity", "electricity", "commodity_physics", "commodity_physics_lodf"],
            ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
            ["connection", "connection_ca", "connection_contingency", "value_true"],
        ]
        relationship_parameter_values = [
            ["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ca", "node_a", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ca", "node_c", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__from_node", ["connection_ab", "node_a"], "connection_emergency_capacity", conn_emergency_cap_ab],
            ["connection__from_node", ["connection_bc", "node_b"], "connection_emergency_capacity", conn_emergency_cap_bc],
            ["connection__from_node", ["connection_ca", "node_c"], "connection_emergency_capacity", conn_emergency_cap_ca],
        ]
        db_api.import_data_to_url(
            url_in; 
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0)
        var_connection_flow = m.ext[:variables][:connection_flow]
        constraint = m.ext[:constraints][:connection_flow_lodf]
        @test length(constraint) == 3
        conn_cont = connection(:connection_ca)
        n_cont_to = node(:node_a)
        d_to = direction(:to_node)
        d_from = direction(:from_node)
        s_parent = stochastic_scenario(:parent)
        s_child = stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(temporal_block=temporal_block(:hourly))
        t2h = time_slice(temporal_block=temporal_block(:two_hourly))[1]
        # connection_ab
        conn_mon = connection(:connection_ab)
        n_mon_to = node(:node_b)
        expected_con = @build_constraint(
            - 1
            <=
            (
                + var_connection_flow[conn_mon, n_mon_to, d_to, s_parent, t2h]
                - var_connection_flow[conn_mon, n_mon_to, d_from, s_parent, t2h]
                + SpineOpt.lodf(connection1=conn_cont, connection2=conn_mon)
                * (
                    + var_connection_flow[conn_cont, n_cont_to, d_to, s_parent, t1h1]
                    + var_connection_flow[conn_cont, n_cont_to, d_to, s_child, t1h2]
                    - var_connection_flow[conn_cont, n_cont_to, d_from, s_parent, t1h1]
                    - var_connection_flow[conn_cont, n_cont_to, d_from, s_child, t1h2]
                )
            )
            / conn_emergency_cap_ab 
            <= 
            + 1
        )
        observed_con = constraint_object(constraint[conn_cont, conn_mon, [s_parent, s_child], t2h])
        @test _is_constraint_equal(observed_con, expected_con)
        # connection_bc -- t1h1
        conn_mon = connection(:connection_bc)
        n_mon_to = node(:node_c)
        expected_con = @build_constraint(
            - 1
            <=
            (
                + var_connection_flow[conn_mon, n_mon_to, d_to, s_parent, t1h1]
                - var_connection_flow[conn_mon, n_mon_to, d_from, s_parent, t1h1]
                + SpineOpt.lodf(connection1=conn_cont, connection2=conn_mon)
                * (
                    + var_connection_flow[conn_cont, n_cont_to, d_to, s_parent, t1h1]
                    - var_connection_flow[conn_cont, n_cont_to, d_from, s_parent, t1h1]
                )
            )
            / conn_emergency_cap_bc
            <= 
            + 1
        )
        observed_con = constraint_object(constraint[conn_cont, conn_mon, [s_parent], t1h1])
        @test _is_constraint_equal(observed_con, expected_con)
        # connection_bc -- t1h2
        expected_con = @build_constraint(
            - 1
            <=
            (
                + var_connection_flow[conn_mon, n_mon_to, d_to, s_child, t1h2]
                - var_connection_flow[conn_mon, n_mon_to, d_from, s_child, t1h2]
                + SpineOpt.lodf(connection1=conn_cont, connection2=conn_mon)
                * (
                    + var_connection_flow[conn_cont, n_cont_to, d_to, s_child, t1h2]
                    - var_connection_flow[conn_cont, n_cont_to, d_from, s_child, t1h2]
                )
            )
            / conn_emergency_cap_bc
            <= 
            + 1
        )
        observed_con = constraint_object(constraint[conn_cont, conn_mon, [s_child], t1h2])
        @test _is_constraint_equal(observed_con, expected_con)
    end
    @testset "constraint_ratio_out_in_connection_flow" begin
        flow_ratio = 0.8
        model_end = Dict("type" => "date_time", "data" => "2000-01-01T04:00:00")
        class = "connection__node__node"
        relationship = ["connection_ab", "node_b", "node_a"]
        object_parameter_values = [["model", "instance", "model_end", model_end]]
        relationships = [[class, relationship]]
        senses_by_prefix = Dict("min" => >=, "fix" => ==, "max" => <=)
        @testset for conn_flow_minutes_delay in (150, 180, 225)
            connection_flow_delay = Dict("type" => "duration", "data" => string(conn_flow_minutes_delay, "m"))
            h_delay = div(conn_flow_minutes_delay, 60)
            rem_minutes_delay = (conn_flow_minutes_delay % 60) / 60
            @testset for p in ("min", "fix", "max")
                _load_template(url_in)
                db_api.import_data_to_url(url_in; test_data...)
                sense = senses_by_prefix[p]
                ratio = string(p, "_ratio_out_in_connection_flow")
                relationship_parameter_values = [
                    [class, relationship, "connection_flow_delay", connection_flow_delay],
                    [class, relationship, ratio, flow_ratio]
                ]
                db_api.import_data_to_url(
                    url_in; 
                    relationships=relationships, 
                    object_parameter_values=object_parameter_values,
                    relationship_parameter_values=relationship_parameter_values
                )
                m = run_spineopt(url_in; log_level=0)
                var_connection_flow = m.ext[:variables][:connection_flow]
                constraint = m.ext[:constraints][Symbol(ratio)]
                @test length(constraint) == 6
                conn = connection(:connection_ab)
                n_from = node(:node_a)
                n_to = node(:node_b)
                d_from = direction(:from_node)
                d_to = direction(:to_node)
                scenarios_from = [repeat([stochastic_scenario(:child)], 3); repeat([stochastic_scenario(:parent)], 5)]
                time_slices_from = [
                    reverse(time_slice(temporal_block=temporal_block(:hourly)));
                    reverse(SpineOpt.history_time_slice(temporal_block=temporal_block(:hourly)))
                ]
                s_to = stochastic_scenario(:parent)
                @testset for (i, t_to) in enumerate(reverse(time_slice(temporal_block=temporal_block(:hourly))))
                    coeffs = (1 - rem_minutes_delay, rem_minutes_delay)
                    s_set = scenarios_from[i + h_delay: i + h_delay + 1]
                    t_set = time_slices_from[i + h_delay: i + h_delay + 1]
                    vars_conn_flow_from = (
                        var_connection_flow[conn, n_from, d_from, s_from, t_from] 
                        for (s_from, t_from) in zip(s_set, t_set)
                    )
                    expected_con_ref = SpineOpt.sense_constraint(
                        m,
                        0,
                        sense,
                        flow_ratio * sum(c * v for (c, v) in zip(coeffs, vars_conn_flow_from))
                    )
                    expected_con = constraint_object(expected_con_ref)
                    path = reverse(unique(s_set))
                    con_key = (conn, n_to, n_from, path, t_to)
                    observed_con = constraint_object(constraint[con_key])
                    @test _is_constraint_equal(observed_con, expected_con)                    
                end
                @testset for (j, t_to) in enumerate(reverse(time_slice(temporal_block=temporal_block(:two_hourly))))
                    coeffs = (1 - rem_minutes_delay, 1, rem_minutes_delay)
                    i = 2 * j - 1
                    s_set = scenarios_from[i + h_delay: i + h_delay + 2]
                    t_set = time_slices_from[i + h_delay: i + h_delay + 2]
                    vars_conn_flow_from = (
                        var_connection_flow[conn, n_from, d_from, s_from, t_from] 
                        for (s_from, t_from) in zip(s_set, t_set)
                    )
                    var_conn_flow_to = var_connection_flow[conn, n_to, d_to, s_to, t_to]
                    expected_con_ref = SpineOpt.sense_constraint(
                        m,
                        2 * var_conn_flow_to,
                        sense,
                        flow_ratio * sum(c * v for (c, v) in zip(coeffs, vars_conn_flow_from))
                    )
                    expected_con = constraint_object(expected_con_ref)
                    path = reverse(unique(s_set))
                    con_key = (conn, n_to, n_from, path, t_to)
                    observed_con = constraint_object(constraint[con_key])
                    @test _is_constraint_equal(observed_con, expected_con)                    
                end
            end
        end
    end
end