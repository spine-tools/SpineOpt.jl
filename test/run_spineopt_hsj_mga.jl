import DataStructures: DefaultDict
using SpineOpt:
    init_hsj_weights,
    do_update_hsj_weights!,
    was_variable_active,
    update_hsj_weights!,
    get_scenario_variable_average
using JuMP 

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
            ["model", "instance", "model_algorithm", "hsj_mga_algorithm"],
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

function _test_run_hsj_spineopt_mga()
    @testset "run_spineopt_hsj_mga" begin
        url_in = _test_run_spineopt_mga_setup()
        candidate_units = 1
        candidate_connections = 1
        candidate_storages = 1
        fuel_cost = 5
        mga_slack = 0.05
        object_parameter_values = [
            ["unit", "unit_ab", "candidate_units", candidate_units],
            ["unit", "unit_bc", "candidate_units", candidate_units],
            ["unit", "unit_ab", "number_of_units", 0],
            ["unit", "unit_bc", "number_of_units", 0],
            ["unit", "unit_group_abbc", "units_invested_mga", true],
            ["unit", "unit_group_abbc", "units_invested__mga_weight", 1],
            ["unit", "unit_ab", "unit_investment_cost", 1],
            ["connection", "connection_ab", "candidate_connections", candidate_connections],
            ["connection", "connection_bc", "candidate_connections", candidate_connections],
            ["connection", "connection_group_abbc", "connections_invested_mga", true],
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
            ["node", "node_group_bc", "storages_invested_mga_weight", 1],
            ["model", "instance", "model_algorithm", "hsj_mga_algorithm"],
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
        m = run_spineopt(url_in; log_level=1, add_bridges=true)
    end
end

function _test_do_update_hsj_weights()
    @testset "do_update_hsj_weights" begin
        mga_indices = collect(0:1)
        function variable_indices(i)
            return [2*i+1, 2*i+2]
        end
        @testset "empty_iterator" begin
            variable_values = [0, 0, 0, 0]
            dict = DefaultDict(0)
            do_update_hsj_weights!([], variable_values, variable_indices, dict)
            @test dict[0] == 0
            @test dict[1] == 0
        end
        @testset "variable inactive" begin
            variable_values = [0, 0, 0, 0]
            dict = DefaultDict(0)
            do_update_hsj_weights!(mga_indices, variable_values, variable_indices, dict)
            @test dict[0] == 0
            @test dict[1] == 0
        end
        @testset "variable active" begin
            variable_values = [1, 1, 1, 0]
            dict = DefaultDict(0)
            do_update_hsj_weights!(mga_indices, variable_values, variable_indices, dict)
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "variable active with set weight" begin
            variable_values = [1, 1, 1, 0]
            dict = DefaultDict(0)
            dict[0] = 1
            dict[1] = 1
            do_update_hsj_weights!(mga_indices, variable_values, variable_indices, dict)
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "variable inactive with set weight" begin
            variable_values = [0, 0, 0, 0]
            dict = DefaultDict(0)
            dict[0] = 1
            dict[1] = 1
            do_update_hsj_weights!(mga_indices, variable_values, variable_indices, dict)
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "active and inactive variables" begin
            variable_values = [0, 0, 1, 0]
            dict = DefaultDict(0)
            do_update_hsj_weights!(mga_indices, variable_values, variable_indices, dict)
            @test dict[0] == 0
            @test dict[1] == 1
        end

    end 
end

function _test_was_variable_active()
    @testset "was_variable_active" begin
        @testset "variable_indices_list_empty" begin
            @test was_variable_active([1,2,3], []) == false
        end
        @testset "active single variable" begin
            @test was_variable_active([1], [1]) == true
        end
        @testset "all inactive" begin
            @test was_variable_active([0, 0, 0, 0], [1, 2, 3, 4]) == false
        end
        @testset "active and inactive" begin
            @test was_variable_active([0, 1, 0, 1], [1, 2, 3, 4]) == true
            
        end
    end
end

function _test_init_hsj_weights()
    @testset "init_hsj_weights" begin
        weights = init_hsj_weights()
        @test weights[:units_invested] == DefaultDict(0)
        @test weights[:connections_invested] == DefaultDict(0)
        @test weights[:storages_invested] == DefaultDict(0)
    end
end

function _test_update_hsj_weights()
    @testset "update_hsj_weights" begin
        group_parameters = Dict(
            :var_name => (
                (i) -> [2*i + 1, 2*i + 2],
                nothing,
                () -> [0, 1, 2, 3]
            )
        )
        variable_values = Dict(:var_name => [0, 0, 0, 1, 0, 0, 0, 1])
        hsj_weights = init_hsj_weights()
        hsj_weights[:var_name][2] = 1
        hsj_weights[:var_name][3] = 1

        update_hsj_weights!(variable_values, nothing, hsj_weights, group_parameters)
        @testset "inactive_weights" begin
            @test hsj_weights[:var_name][0] == 0
        end
        @testset "active weights" begin
            @test hsj_weights[:var_name][1] == 1
        end
        @testset "inactive, previously active" begin
            @test hsj_weights[:var_name][2] == 1
        end
        @testset "active, previously active" begin
            @test hsj_weights[:var_name][3] == 1 
        end  
    end
end

function _test_get_scenario_variable_average()
    @testset "get_scenario_variable_average" begin
        var_idxs = [1, 2, 3]
        m = Model()
        @variable(m, x[var_idxs])
        scenario_weights = [0.33, 0.6, 0.07]
        average = get_scenario_variable_average(x, var_idxs, (i) -> scenario_weights[i])
        @test average == 0.33x[1] + 0.6x[2] + 0.07x[3]
    end
end

@testset "run_spineopt_hsj_mga" begin
    _test_get_mga_constraint_ub()
    _test_init_hsj_weights()
    _test_do_update_hsj_weights()
    _test_was_variable_active()
    _test_update_hsj_weights()
    _test_get_scenario_variable_average()
    # _test_run_hsj_spineopt_mga()
end