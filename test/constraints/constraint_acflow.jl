function _test_acflow_setup()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "two_hourly"],
            ["temporal_block", "inve_daily"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "stochastic"],
            ["stochastic_structure", "investments_deterministic"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
            ["grid", "grid1"],
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
            ["report__output", ["report1", "node_voltage_squared"]]
        ],
        :object_groups => [["node", "node_group_bc", "node_b"], ["node", "node_group_bc", "node_c"]],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["temporal_block", "inve_daily", "resolution", Dict("type" => "duration", "data" => "24h")],
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

function test_constraint_connection_flows()
    @testset "conbasic" begin
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
        var_f_real = m.ext[:spineopt].variables[:connection_flow]
       
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        s_path = [stochastic_scenario(:parent), stochastic_scenario(:child)]

        println(
            let
                t_long = TimeSlice(
                    DateTime("2000-01-01T00:00"),
                    DateTime("2000-01-01T02:00"),
                )

                slices = to_time_slice(m; t=t_long)
                time_slice(m; temporal_block=temporal_block(:hourly), t = slices)
            end
        )
        for (s, t) in zip(s_path, time_slices)
            println("$s ja $t")
            flowind = (connection(:connection_bc), node(:node_b), direction(:from_node), s, t)
            nodeind = (node(:node_b), s, t)
            twonodeind = (node(:node_b), node(:node_c), s, t)
            expected_con = @build_constraint(var_f_real[flowind...] 
                + 2.5 * var_v_cos[twonodeind...] + 2.5 * var_v_sin[twonodeind...] 
                - 2.5 * var_v_sq[nodeind...] == 0)
            con_key = (connection(:connection_bc), node(:node_b), direction(:from_node), s, t)
            observed_con = constraint_object(c1[con_key...])
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

@testset "acflow constraints" begin
    test_constraint_connection_flows()
end
