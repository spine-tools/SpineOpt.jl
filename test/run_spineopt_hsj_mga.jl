import DataStructures: DefaultDict
using SpineOpt:
    init_hsj_weights,
    do_update_hsj_weights!,
    was_variable_active,
    update_hsj_weights!,
    get_scenario_variable_average,
    slack_correction,
    prepare_objective_mga!,
    update_mga_objective!,
    get_variable_group_values,
    iterative_mga!,
    add_mga_objective_constraint!,
    formulate_mga_objective!,
    VariableGroupParameters

    
using JuMP 
using HiGHS

array_to_dict(arr::AbstractArray) = Dict(k=>v for (k,v) in enumerate(arr))

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

function generate_simple_system(algorithm::String, no_iterations=nothing)
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
        ["unit", "unit_ab", "unit_investment_cost", 1],
        ["connection", "connection_ab", "candidate_connections", candidate_connections],
        ["connection", "connection_bc", "candidate_connections", candidate_connections],
        ["connection", "connection_group_abbc", "connections_invested_mga", true],
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
        ["model", "instance", "model_algorithm", algorithm],
        ["model", "instance", "max_mga_slack", mga_slack],
        # ["node", "node_a", "demand", 1],
        ["node", "node_b", "demand", 1],
        ["node", "node_c", "demand", 1],
    ]
    if no_iterations !== nothing
        push!(object_parameter_values, ["model", "instance", "max_mga_iterations", no_iterations])
    end
    relationship_parameter_values = [
        ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", 5],
        ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", fuel_cost],
        ["unit__to_node", ["unit_bc", "node_c"], "unit_capacity", 5],
        ["connection__to_node", ["connection_ab","node_b"], "connection_capacity", 5],
        ["connection__to_node", ["connection_bc","node_c"], "connection_capacity", 5]
    ]
    return object_parameter_values, relationship_parameter_values
end

function _test_run_spineopt_hsj_mga()
    @testset "run_spineopt_hsj_mga_no_max_iterations" begin
        url_in = _test_run_spineopt_mga_setup()
        object_parameter_values, relationship_parameter_values = generate_simple_system("hsj_mga_algorithm")
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=1, add_bridges=true)
        variable_values = m.ext[:spineopt].expressions[:variable_group_values]
        @test length(variable_values) == 1
        expected_values= Dict(
            0 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 1.0,
            )
        )
        for (iter, dict) in expected_values
            units_invested = sort(collect(variable_values[iter][:units_invested])) # Sort required for consistency!
            for (i, (unit, v1)) in enumerate(sort(dict)) # Sort required for consistency!
                @test unit == units_invested[i][1].unit
                @test isapprox(v1, units_invested[i][2])
            end
        end
    end
    @testset "run_spineopt_hsj_mga" begin
        url_in = _test_run_spineopt_mga_setup()
        object_parameter_values, relationship_parameter_values = generate_simple_system("hsj_mga_algorithm", 2)
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=1, add_bridges=true)
        variable_values = m.ext[:spineopt].expressions[:variable_group_values]
        @test length(variable_values) == 3
        expected_values= Dict(
            0 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 1.0,
            ),
            1 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 0.0,
            ),
            2 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 0.0,
            ),
        )
        for (iter, dict) in expected_values
            units_invested = sort(collect(variable_values[iter][:units_invested])) # Sort required for consistency!
            for (i, (unit, v1)) in enumerate(sort(dict)) # Sort required for consistency!
                @test unit == units_invested[i][1].unit
                @test isapprox(v1, units_invested[i][2])
            end
        end
    end
end

function _test_run_spineopt_fuzzy_mga()
    @testset "run_spineopt_fuzzy_mga_no_max_iterations" begin
        url_in = _test_run_spineopt_mga_setup()
        object_parameter_values, relationship_parameter_values = generate_simple_system("fuzzy_mga_algorithm")
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=1, add_bridges=true)
        variable_values = m.ext[:spineopt].expressions[:variable_group_values]
        @test length(variable_values) == 1
        expected_values= Dict(
            0 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 1.0,
            ),
        )
        for (iter, dict) in expected_values
            units_invested = sort(collect(variable_values[iter][:units_invested])) # Sort required for consistency!
            for (i, (unit, v1)) in enumerate(sort(dict)) # Sort required for consistency!
                @test unit == units_invested[i][1].unit
                @test isapprox(v1, units_invested[i][2])
            end
        end
    end
    @testset "run_spineopt_fuzzy_mga" begin
        url_in = _test_run_spineopt_mga_setup()
        object_parameter_values, relationship_parameter_values = generate_simple_system("fuzzy_mga_algorithm", 2)
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=1, add_bridges=true)
        variable_values = m.ext[:spineopt].expressions[:variable_group_values]
        @test length(variable_values) == 3
        expected_values= Dict(
            0 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 1.0,
            ),
            1 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 0.0,
            ),
            2 => Dict(
                unit(:unit_ab) => 0.0,
                unit(:unit_bc) => 0.0,
            ),
        )
        for (iter, dict) in expected_values
            units_invested = sort(collect(variable_values[iter][:units_invested])) # Sort required for consistency!
            for (i, (unit, v1)) in enumerate(sort(dict)) # Sort required for consistency!
                @test unit == units_invested[i][1].unit
                @test isapprox(v1, units_invested[i][2])
            end
        end
    end
end

function _test_do_update_hsj_weights()
    @testset "do_update_hsj_weights" begin
        mga_indices = collect(0:1)
        function variable_indices(i)
            return [2*i+1, 2*i+2]
        end
        @testset "empty_iterator" begin
            variable_values = array_to_dict([0, 0, 0, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, [])
            do_update_hsj_weights!(group, variable_values, dict, Val(:hsj_mga_algorithm))
            @test dict[0] == 0
            @test dict[1] == 0
        end
        @testset "variable inactive" begin
            variable_values = array_to_dict([0, 0, 0, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:hsj_mga_algorithm))
            @test dict[0] == 0
            @test dict[1] == 0
        end
        @testset "variable active" begin
            variable_values = array_to_dict([1, 1, 1, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:hsj_mga_algorithm))
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "variable active with set weight" begin
            variable_values = array_to_dict([1, 1, 1, 0])
            dict = DefaultDict(0)
            dict[0] = 1
            dict[1] = 1
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:hsj_mga_algorithm))
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "variable inactive with set weight" begin
            variable_values = array_to_dict([0, 0, 0, 0])
            dict = DefaultDict(0)
            dict[0] = 1
            dict[1] = 1
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:hsj_mga_algorithm))
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "active and inactive variables" begin
            variable_values = array_to_dict([0, 0, 1, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:hsj_mga_algorithm))
            @test dict[0] == 0
            @test dict[1] == 1
        end
    end
    @testset "do_update_fuzzy_hsj_weights" begin
        mga_indices = collect(0:1)
        function variable_indices(i)
            return [2*i+1, 2*i+2]
        end 

        @testset "empty_iterator" begin
            variable_values = array_to_dict([0, 0, 0, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, [])
            do_update_hsj_weights!(group, variable_values, dict, Val(:fuzzy_mga_algorithm))
            @test dict[0] == 0
            @test dict[1] == 0
        end
        @testset "variable inactive" begin
            variable_values = array_to_dict([0, 0, 0, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:fuzzy_mga_algorithm))
            @test dict[0] == 0
            @test dict[1] == 0
        end
        @testset "variable active" begin
            variable_values = array_to_dict([1, 1, 1, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:fuzzy_mga_algorithm))
            @test dict[0] == 1
            @test dict[1] == 2
        end
        @testset "variable active with set weight" begin
            variable_values = array_to_dict([1, 1, 1, 0])
            dict = DefaultDict(0)
            dict[0] = 1
            dict[1] = 1
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:fuzzy_mga_algorithm))
            @test dict[0] == 1
            @test dict[1] == 2
        end
        @testset "variable inactive with set weight" begin
            variable_values = array_to_dict([0, 0, 0, 0])
            dict = DefaultDict(0)
            dict[0] = 1
            dict[1] = 1
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:fuzzy_mga_algorithm))
            @test dict[0] == 1
            @test dict[1] == 1
        end
        @testset "active and inactive variables" begin
            variable_values = array_to_dict([0, 0, 1, 0])
            dict = DefaultDict(0)
            group = VariableGroupParameters(variable_indices, i->1/2, mga_indices)
            do_update_hsj_weights!(group, variable_values, dict, Val(:fuzzy_mga_algorithm))
            @test dict[0] == 0
            @test dict[1] == 2
        end
    end 
end

function _test_was_variable_active()
    @testset "was_variable_active" begin
        @testset "variable_indices_list_empty" begin
            @test was_variable_active(array_to_dict([1,2,3]), []) == false
        end
        @testset "active single variable" begin
            @test was_variable_active(array_to_dict([1]), [1]) == true
        end
        @testset "all inactive" begin
            @test was_variable_active(array_to_dict([0, 0, 0, 0]), [1, 2, 3, 4]) == false
        end
        @testset "active and inactive" begin
            @test was_variable_active(array_to_dict([0, 1, 0, 1]), [1, 2, 3, 4]) == true
            
        end
    end
end

function _test_slack_correction()
    @testset "slack_correction" begin
        @testset "objective greater than 0" begin
            @test isapprox(slack_correction(0.01, 100), 0.01)
        end
        @testset "objective equal to 0" begin
            @test isapprox(slack_correction(0.01, 0), 0.01)
        end
        @testset "objective lower than 0" begin
            @test isapprox(slack_correction(0.01, -100), -0.01)
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
            :var_name => VariableGroupParameters(
                (i) -> [2*i + 1, 2*i + 2],
                () -> nothing,
                [0, 1, 2, 3]
            )
        )
        variable_values = Dict(:var_name => array_to_dict([0, 0, 0, 1, 0, 0, 0, 1]))
        hsj_weights = init_hsj_weights()
        hsj_weights[:var_name][2] = 1
        hsj_weights[:var_name][3] = 1

        update_hsj_weights!(variable_values, hsj_weights, group_parameters, Val(:hsj_mga_algorithm))
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

function _test_get_scenario_variable_value_average()
    @testset "get_scenario_variable_value_average" begin
        var_idxs = [1, 2, 3]
        variable_values = [3, 2, 4]
        scenario_weights = [0.33, 0.6, 0.07]
        average = get_scenario_variable_average(variable_values, var_idxs, (i) -> scenario_weights[i])
        @test isapprox(average, 2.47)
    end
end

function _test_prepare_objective_hsj_mga()
    @testset "prepare_objective_hsj_mga" begin
        m = Model()
        @variable(m, x[1:6] >= 0)
        var_indxs = (i) -> [2*i+1, 2*i+2]
        stochastic_weights = [0.5, 0.5, 0.5, 0.5, 0.33, 0.67]
        var_stoch_weights = (i) -> stochastic_weights[i]
        var_values = array_to_dict([1, 0, 0, 0, 1, 1])
        mga_weights = Dict(0 => 1, 1=>0, 2=>1) 
        @testset "empty mga indices" begin
            mga_idxs = []
            group = VariableGroupParameters(var_indxs, var_stoch_weights, mga_idxs)
            res = prepare_objective_mga!(group, x, var_values, mga_weights, Val(:hsj_mga_algorithm))
            @test res == 0
        end
        @testset "nonempty mga indices" begin
            mga_idxs = [0, 1, 2]
            group = VariableGroupParameters(var_indxs, var_stoch_weights, mga_idxs)
            res = prepare_objective_mga!(group, x, var_values, mga_weights, Val(:hsj_mga_algorithm))
            @test res == 0.5x[1] + 0.5x[2] + 0.33x[5] + 0.67x[6]
        end
    end
    @testset "prepare_objective_fuzzy_mga" begin
        var_indxs = (i) -> [2*i+1, 2*i+2]
        stochastic_weights = [0.5, 0.5, 0.5, 0.5, 0.33, 0.67]
        var_stoch_weights = (i) -> stochastic_weights[i]
        var_values = array_to_dict([1, 0, 0, 0, 1, 1])
        mga_weights = Dict(0 => 1, 1=>0, 2=>1) 
        @testset "empty mga indices" begin
            m = Model(HiGHS.Optimizer)
            @variable(m, 0 <= x[1:6] )
            mga_idxs = []
            group = VariableGroupParameters(var_indxs, var_stoch_weights, mga_idxs)
            res = prepare_objective_mga!(group, x, var_values, mga_weights, Val(:fuzzy_mga_algorithm))
            @test res == 1
        end
        @testset "nonempty mga indices" begin
            m = Model(HiGHS.Optimizer)
            @variable(m, 0 <= x[1:6] )
            mga_idxs = [0, 1, 2]
            group = VariableGroupParameters(var_indxs, var_stoch_weights, mga_idxs)
            res = prepare_objective_mga!(group, x, var_values, mga_weights, Val(:fuzzy_mga_algorithm))
            mga_expression = 0.5x[1] + 0.5x[2] + 0.33x[5] + 0.67x[6]
            @test res == (mga_expression - 1.5) / -1.5
        end
    end
end

function _test_update_hsj_mga_objective()
    @testset "update_hsj_mga_objective" begin
        m = Model()
        @variable(m, x[1:6])
        x_indxs = (i) -> [2*i+1, 2*i+2]
        x_stochastic_weights = [0.5, 0.5, 0.5, 0.5, 0.33, 0.67]
        x_stoch_weights = (i) -> x_stochastic_weights[i]
        x_mga_weights = Dict(0 => 1, 1=>0, 2=>1) 
        
        @variable(m, y[1:4])
        y_indxs = (i) -> [2*i+1, 2*i+2]
        y_stochastic_weights = [0.5, 0.5, 0.2, 0.8]
        y_stoch_weights = (i) -> y_stochastic_weights[i]
        y_mga_weights = Dict(0 => 0, 1=>1) 

        hsj_weights = Dict(:x => x_mga_weights, :y => y_mga_weights)
        variables = Dict(:x => x, :y => y)
        variable_values = Dict(:x => array_to_dict([0, 0, 0, 0, 0, 0]), :y => array_to_dict([0, 0, 0, 0]))
        @testset "empty variable mga indices" begin
            x_mga_idxs = []
            y_mga_idxs = [0, 1]
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, Dict(), Val(:hsj_mga_algorithm))
            @test res[:objective] == 0.2y[3] + 0.8y[4]
        end
        @testset "all empty variable mga indices" begin
            x_mga_idxs = []
            y_mga_idxs = []
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, Dict(), Val(:hsj_mga_algorithm))
            @test res[:objective] == 0
        end
        @testset "nonempty variable mga indices" begin
            x_mga_idxs = [0, 1, 2]
            y_mga_idxs = [0, 1]
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, Dict(), Val(:hsj_mga_algorithm))
            @test res[:objective] == 0.5x[1] + 0.5x[2] + 0.33x[5] + 0.67x[6] + 0.2y[3] + 0.8y[4]
        end
    end
    @testset "update_fuzzy_mga_objective" begin
    
        m = Model(HiGHS.Optimizer)
        @variable(m, 0 <= x[1:2] <= 1)
        @variable(m, 0 <= y[1:2] <= 1)
        f(m) = 3 -x[1] + x[2] - y[1] + y[2]
        @objective(m, Min, f(m))
        set_silent(m)
        optimize!(m)
        constr = add_mga_objective_constraint!(m, 0.5, Val(:fuzzy_mga_algorithm))
        variables =  Dict(:x => x, :y => y)

        x_indxs = (i) -> [i]
        x_stochastic_weights = [1, 1]
        x_stoch_weights = (i) -> x_stochastic_weights[i]
        y_indxs = (i) -> [1, 2]
        y_stochastic_weights = [0.5, 0.5]
        y_stoch_weights = (i) -> y_stochastic_weights[i]
        
        variable_values = Dict(:x => array_to_dict([1, 0]), :y => array_to_dict([1, 0]))

        @testset "Empty mga indices" begin
            hsj_weights = Dict(:x => Dict(1 => 1, 2=> 0) , :y => Dict(1=>1))
            x_mga_idxs = []
            y_mga_idxs = []
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, constr, Val(:fuzzy_mga_algorithm))
            optimize!(m)
            @test value(res[:variable]) == 1
            @test value(constr) == 1
        end
        @testset "Normal groups" begin
            hsj_weights = Dict(:x => Dict(1 => 1, 2=> 0) , :y => Dict(1=>1))
            x_mga_idxs = [1, 2]
            y_mga_idxs = [1]
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, constr, Val(:fuzzy_mga_algorithm))
            optimize!(m)
            @test isapprox(value(res[:variable]), 1/5)
            @test isapprox(value(x[1]), 4/5)
            @test isapprox(value(y[1]), 4/5)
            @test isapprox(value(x[2]), 0)
            @test isapprox(value(y[2]), 0)
        end
        @testset "Skipped group" begin
            hsj_weights = Dict(:x => Dict(1 => 0, 2=> 0) , :y => Dict(1=>1))
            x_mga_idxs = [1, 2]
            y_mga_idxs = [1]
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, constr, Val(:fuzzy_mga_algorithm))
            optimize!(m)
            @test isapprox(value(res[:variable]), 1/3)
            @test isapprox(value(x[1]), 1)
            @test isapprox(value(y[1]), 2/3)
            @test isapprox(value(x[2]), 0)
            @test isapprox(value(y[2]), 0)
        end
        @testset "All groups skipped" begin
            hsj_weights = Dict(:x => Dict(1 => 0, 2=> 0) , :y => Dict(1=>0))
            x_mga_idxs = [1, 2]
            y_mga_idxs = [1]
            group_parameters = Dict(
                :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
                :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
            )
            res = update_mga_objective!(m, hsj_weights, variables, variable_values, group_parameters, constr, Val(:fuzzy_mga_algorithm))
            optimize!(m)
            @test value(res[:variable]) == 1
            @test value(constr) == 1
        end
    end
end

function _test_get_variable_group_values()
    @testset "get_variable_group_values" begin
        m = Model(HiGHS.Optimizer)
        @variable(m, x[1:2])
        @constraint(m, x[1] == 1)
        @constraint(m, x[2] == 2)
        @variable(m, y[1:4])
        @constraint(m, y[1] == 3)
        @constraint(m, y[2] == 4)
        @constraint(m, y[3] == 5)
        @constraint(m, y[4] == 6)
        set_silent(m)
        optimize!(m)
        
        x_indxs = (i) -> [2*i+1, 2*i+2]
        y_indxs = (i) -> [2*i+1, 2*i+2]
        variables = Dict(:x => x, :y => y)
        x_mga_idxs = [0]
        y_mga_idxs = [0, 1]
        
        group_parameters = Dict(
            :x => VariableGroupParameters(x_indxs, () -> nothing, x_mga_idxs),
            :y => VariableGroupParameters(y_indxs, () -> nothing, y_mga_idxs),
        )
        res = get_variable_group_values(variables, group_parameters)
        @test res[:x][1] == 1
        @test res[:x][2] == 2
        @test res[:y][1] == 3
        @test res[:y][2] == 4
        @test res[:y][3] == 5
        @test res[:y][4] == 6
    end
end

function _test_iterative_mga()
    @testset "iterative hsj mga" begin
        m = Model(HiGHS.Optimizer)
        @variable(m, x[1:2] >= 0)
        x_indxs = (i) -> [i]
        x_stoch_weights = (i) -> 1
        
        @variable(m, y[1] >= 0)
        y_indxs = (i) -> [i]
        y_stoch_weights = (i) -> 1
        variables = Dict(:x => x, :y => y)
        @constraint(m, x[1] + x[2] + y[1] <= 1)
        @objective(m, Min, -x[1] - x[2] - y[1])
        x_mga_idxs = [1, 2]
        y_mga_idxs = [1]
        variable_group_parameters = Dict(
            :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
            :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
        )
        max_mga_iters = 2
        slack = 0.05
        set_silent(m)
        res = iterative_mga!(
            m,
            variables,
            variable_group_parameters,
            max_mga_iters,
            slack,
            Val(:hsj_mga_algorithm)
        )
        atol = slack + 1e-6
        @test isapprox(res[0][:x][1], 1, atol=atol)
        @test isapprox(res[0][:x][2], 0, atol=atol)
        @test isapprox(res[0][:y][1], 0, atol=atol)
        @test isapprox(res[1][:x][1], 0, atol=atol)
        @test isapprox(res[1][:x][2], 1, atol=atol)
        @test isapprox(res[1][:y][1], 0, atol=atol)
        @test isapprox(res[2][:x][1], 0, atol=atol)
        @test isapprox(res[2][:x][2], 0, atol=atol)
        @test isapprox(res[2][:y][1], 1, atol=atol)
    end
    @testset "iterative fuzzy mga" begin
        m = Model(HiGHS.Optimizer)
        @variable(m, x[1:2] >= 0)
        x_indxs = (i) -> [i]
        x_stoch_weights = (i) -> 1
        
        @variable(m, y[1:2] >= 0)
        y_indxs = (i) -> [i]
        y_stoch_weights = (i) -> 1
        variables = Dict(:x => x, :y => y)
        goal_function = (m) -> 3 -x[1] - x[2] - y[1] - y[2]
        @constraint(m, x[1] + x[2] <= 1)
        @constraint(m, y[1] + y[2] <= 1)
        @objective(m, Min, goal_function(m))
        x_mga_idxs = [1, 2]
        y_mga_idxs = [1, 2]
        variable_group_parameters = Dict(
            :x => VariableGroupParameters(x_indxs, x_stoch_weights, x_mga_idxs),
            :y => VariableGroupParameters(y_indxs, y_stoch_weights, y_mga_idxs),
        )
        max_mga_iters = 2
        
        slack = 0.5
        set_silent(m)
        res = iterative_mga!(
            m,
            variables,
            variable_group_parameters,
            max_mga_iters,
            slack,
            Val(:fuzzy_mga_algorithm)
        )
        atol = 1e-6
        @test isapprox(res[0][:x][1], 1, atol=atol)
        @test isapprox(res[0][:x][2], 0, atol=atol)
        @test isapprox(res[0][:y][1], 1, atol=atol)
        @test isapprox(res[0][:y][2], 0, atol=atol)
        @test isapprox(res[1][:x][1], 0, atol=atol)
        @test isapprox(res[1][:x][2], 1, atol=atol)
        @test isapprox(res[1][:y][1], 0, atol=atol)
        @test isapprox(res[1][:y][2], 1, atol=atol)
        @test isapprox(res[2][:x][1] + res[2][:x][2], 4/5, atol=atol)
        @test isapprox(res[2][:y][1] + res[2][:y][2], 4/5, atol=atol)

    end   
end

function _test_add_objective_constraint()
    @testset "add_hsj_objective_constraint" begin
        m = Model(HiGHS.Optimizer)
        @variable(m, x[1:2] >= 0)
        @constraint(m, x[1] + x[2] == 1)
        goal_function(m) = 1 + x[1]
        @objective(m, Min, goal_function(m))
        set_silent(m)
        optimize!(m)
        slack = 0.05
        add_mga_objective_constraint!(m, slack, Val(:hsj_mga_algorithm))
        @objective(m, Min, x[2])
        set_silent(m)
        optimize!(m)
        @test isapprox(value(x[1]), 0.05)
        @test isapprox(value(x[2]), 0.95)
    end
    @testset "add_fuzzy_objective_constraint" begin
        m = Model(HiGHS.Optimizer)
        @variable(m, x[1:2] >= 0)
        @constraint(m, x[1] + x[2] == 1)
        goal_function(m) = 1 + x[1]
        @objective(m, Min, goal_function(m))
        set_silent(m)
        optimize!(m)
        slack = 0.05
        res = add_mga_objective_constraint!(m, slack, Val(:fuzzy_mga_algorithm))
        @test _is_expression_equal(res, -(20x[1] - 1))
    end
end

function _test_formulate_mga_objective()
    @testset "formulate_hsj_mga_objective" begin
        m = Model()
        @variable(m, x)
        @variable(m, y)
        groups = Dict(
            :x => x,
            :y => y
        )
        formulation = formulate_mga_objective!(m, groups, Dict(), Val(:hsj_mga_algorithm))
        @test formulation[:objective] == x + y
    end
    @testset "formulate_fuzzy_mga_objective" begin
        m = Model()
        @variable(m, s1)
        @variable(m, s2)
        groups = Dict(
            :s1 => s1,
            :s2 => s2
        )
        @variable(m, sc)
        constraint = sc
        formulation = formulate_mga_objective!(m, groups, constraint, Val(:fuzzy_mga_algorithm))
        s_min = formulation[:variable]
        constr1 = constraint_object(formulation[:heterogeneity_metric][:s1])
        benchmark1 = @build_constraint(s_min <= s1)
        @test _is_constraint_equal(constr1, benchmark1)
        constr2 = constraint_object(formulation[:heterogeneity_metric][:s2])
        benchmark2 = @build_constraint(s_min <= s2)
        @test _is_constraint_equal(constr2, benchmark2)
        constr3 = constraint_object(formulation[:objective_metric])
        benchmark3 = @build_constraint(s_min <= sc)
        @test _is_constraint_equal(constr3, benchmark3)
        @test formulation[:objective] == s_min + 1e-4 * (s1 + s2 + sc)
    end
end

@testset "run_spineopt_hsj_mga" begin
    _test_slack_correction()
    _test_init_hsj_weights()
    _test_do_update_hsj_weights()
    _test_was_variable_active()
    _test_update_hsj_weights()
    _test_get_scenario_variable_average()
    _test_get_scenario_variable_value_average()
    _test_prepare_objective_hsj_mga()
    _test_add_objective_constraint()
    _test_formulate_mga_objective()
    _test_get_variable_group_values()
    _test_update_hsj_mga_objective()
    _test_iterative_mga()
    _test_run_spineopt_hsj_mga()
    _test_run_spineopt_fuzzy_mga()
end