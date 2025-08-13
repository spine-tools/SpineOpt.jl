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

function _test_objective_setup()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "two_hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "stochastic"],
            ["unit", "unit_ab"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
        ],
        :relationships => [
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["units_on__temporal_block", ["unit_ab", "two_hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["node__temporal_block", ["node_a", "two_hourly"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__stochastic_structure", ["node_a", "deterministic"]],
            ["node__stochastic_structure", ["node_b", "stochastic"]],
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
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ],
        :relationship_parameter_values => [[
            "stochastic_structure__stochastic_scenario",
            ["stochastic", "parent"],
            "stochastic_scenario_end",
            Dict("type" => "duration", "data" => "1h"),
        ]],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function test_fom_cost_case_1a()
    # When given a non-investable unit without defining `number_of_units`, 
    # the model uses the template default `number_of_units`=1. 
    @testset "fom_cost case 1a" begin
        url_in = _test_objective_setup()
        unit_capacity = 100
        fom_cost = 8
        number_of_units_template_default = 1
        object_parameter_values = [
            ["unit", "unit_ab", "fom_cost", fom_cost],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
        ]
        SpineInterface.import_data(
            url_in; 
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        
        # duration = length(time_slice(m; temporal_block=temporal_block(:two_hourly)))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        expected_obj = fom_cost * unit_capacity * sum(             
            number_of_units_template_default * length(t) for (s, t) in zip(scenarios, time_slices)
        )
        observed_obj = objective_function(m)
        @test observed_obj == expected_obj
    end
end

function test_fom_cost_case_1b()
    # When a non-investable unit with `number_of_units` explicitly defined ... 
    @testset "fom_cost case 1b" begin
        url_in = _test_objective_setup()
        unit_capacity = 100
        fom_cost = 8
        number_of_units = 2
        object_parameter_values = [
            ["unit", "unit_ab", "fom_cost", fom_cost],
            ["unit", "unit_ab", "number_of_units", number_of_units],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
        ]
        SpineInterface.import_data(
            url_in; 
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        expected_obj = fom_cost * unit_capacity * sum(             
            number_of_units * length(t) for (s, t) in zip(scenarios, time_slices)
        )
        observed_obj = objective_function(m)
        @test observed_obj == expected_obj
    end
end

function test_fom_cost_case_2a()
    # When given an investable unit without defining `number_of_units`, 
    # the model uses the new default `number_of_units`=0. 
    @testset "fom_cost case 2a" begin
        url_in = _test_objective_setup()
        unit_capacity = 100
        fom_cost = 8
        number_of_units_fomulation_default = 0
        candidate_units = 3
        object_parameter_values = [
            ["unit", "unit_ab", "fom_cost", fom_cost],
            ["unit", "unit_ab", "candidate_units", candidate_units],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
        ]
        SpineInterface.import_data(
            url_in; 
            relationships=relationships, 
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        expected_obj = fom_cost * unit_capacity * sum(             
            (number_of_units_fomulation_default + var_units_invested_available[unit(:unit_ab), s, t]) * length(t)
            for (s, t) in zip(scenarios, time_slices)
        )
        observed_obj = objective_function(m)
        @test observed_obj == expected_obj
    end
end

function test_fom_cost_case_2b()
    # When an investable unit with `number_of_units` explicitly defined ... 
    @testset "fom_cost case 2b" begin
        url_in = _test_objective_setup()
        unit_capacity = 100
        fom_cost = 8
        number_of_units = 2
        candidate_units = 3
        object_parameter_values = [
            ["unit", "unit_ab", "fom_cost", fom_cost],
            ["unit", "unit_ab", "number_of_units", number_of_units],
            ["unit", "unit_ab", "candidate_units", candidate_units],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
        ]
        SpineInterface.import_data(
            url_in; 
            relationships=relationships, 
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_units_invested_available = m.ext[:spineopt].variables[:units_invested_available]
        
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        expected_obj = fom_cost * unit_capacity * sum(             
            (number_of_units + var_units_invested_available[unit(:unit_ab), s, t]) * length(t)
            for (s, t) in zip(scenarios, time_slices)
        )
        observed_obj = objective_function(m)
        @test observed_obj == expected_obj
    end
end

function test_fuel_cost()
    @testset "fuel_cost" begin
        url_in = _test_objective_setup()
        fuel_cost = 125
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", fuel_cost]]
        SpineInterface.import_data(url_in; relationship_parameter_values=relationship_parameter_values)
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        unit_flow = m.ext[:spineopt].variables[:unit_flow]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = fuel_cost * sum(unit_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices))
        @test observed_obj == expected_obj
    end
end

function test_unit_investment_cost()
    @testset "unit_investment_cost" begin
        url_in = _test_objective_setup()
        unit_investment_cost = 1000
        candidate_units = 3
        object_parameter_values = [
            ["unit", "unit_ab", "unit_investment_cost", unit_investment_cost],
            ["unit", "unit_ab", "candidate_units", candidate_units],
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        SpineInterface.import_data(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        units_invested = m.ext[:spineopt].variables[:units_invested]
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = (
            unit_investment_cost * sum(units_invested[unit(:unit_ab), s, t] for (s, t) in zip(scenarios, time_slices))
        )
        @test observed_obj == expected_obj
    end
end

function test_node_slack_penalty()
    @testset "node_slack_penalty" begin
        url_in = _test_objective_setup()
        node_a_slack_penalty = 0.6
        node_b_slack_penalty = 0.4
        object_parameter_values = [
            ["node", "node_a", "node_slack_penalty", node_a_slack_penalty],
            ["node", "node_b", "node_slack_penalty", node_b_slack_penalty],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        node_slack_neg = m.ext[:spineopt].variables[:node_slack_neg]
        node_slack_pos = m.ext[:spineopt].variables[:node_slack_pos]
        n_a = node(:node_a)
        n_b = node(:node_b)
        s_parent = stochastic_scenario(:parent)
        s_child = stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(m; temporal_block=temporal_block(:hourly))
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = (
            + 2 * node_a_slack_penalty * node_slack_neg[n_a, s_parent, t2h]
            + 2 * node_a_slack_penalty * node_slack_pos[n_a, s_parent, t2h]
            + node_b_slack_penalty * node_slack_neg[n_b, s_parent, t1h1]
            + node_b_slack_penalty * node_slack_pos[n_b, s_parent, t1h1]
            + node_b_slack_penalty * node_slack_neg[n_b, s_child, t1h2]
            + node_b_slack_penalty * node_slack_pos[n_b, s_child, t1h2]
        )
        @test observed_obj == expected_obj
    end
end

function test_user_constraint_slack_penalty()
    @testset "user_constraint_slack_penalty" begin
        url_in = _test_objective_setup()
        uc_slack_penalty = 0.6
        objects = [["user_constraint", "ucx"]]
        relationships = [["node__user_constraint", ["node_a", "ucx"]]]
        object_parameter_values = [
            [objects[1]..., "user_constraint_slack_penalty", uc_slack_penalty],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        uc_slack_neg = m.ext[:spineopt].variables[:user_constraint_slack_neg]
        uc_slack_pos = m.ext[:spineopt].variables[:user_constraint_slack_pos]
        ucx = user_constraint(:ucx)
        s_parent = stochastic_scenario(:parent)
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = (
            + 2 * uc_slack_penalty * uc_slack_neg[ucx, s_parent, t2h]
            + 2 * uc_slack_penalty * uc_slack_pos[ucx, s_parent, t2h]
        )
        @test observed_obj == expected_obj
    end
end

function test_shut_down_cost()
    @testset "shut_down_cost" begin
        url_in = _test_objective_setup()
        shut_down_cost = 180
        object_parameter_values = [["unit", "unit_ab", "shut_down_cost", shut_down_cost]]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        units_shut_down = m.ext[:spineopt].variables[:units_shut_down]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        s_parent = stochastic_scenario(:parent)
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = shut_down_cost * units_shut_down[unit(:unit_ab), s_parent, t2h]
        @test observed_obj == expected_obj
    end
end

function test_start_up_cost()
    @testset "start_up_cost" begin
        url_in = _test_objective_setup()
        start_up_cost = 220
        object_parameter_values = [["unit", "unit_ab", "start_up_cost", start_up_cost]]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        units_started_up = m.ext[:spineopt].variables[:units_started_up]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        s_parent = stochastic_scenario(:parent)
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = start_up_cost * units_started_up[unit(:unit_ab), s_parent, t2h]
        @test observed_obj == expected_obj
    end
end

function test_vom_cost()
    @testset "vom_cost" begin
        url_in = _test_objective_setup()
        vom_cost = 150
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost]]
        SpineInterface.import_data(url_in; relationship_parameter_values=relationship_parameter_values)
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        unit_flow = m.ext[:spineopt].variables[:unit_flow]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = vom_cost * sum(unit_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices))
        @test observed_obj == expected_obj
    end
end

function test_connection_flow_cost()
    @testset "connection_flow_cost" begin
        url_in = _test_objective_setup()
        connection_flow_cost = 185
        objects = [["connection", "connection_ab"]]
        relationships = [["connection__to_node", ["connection_ab", "node_b"]]]
        relationship_parameter_values = [
            ["connection__to_node", ["connection_ab", "node_b"], "connection_flow_cost", connection_flow_cost]
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            relationship_parameter_values=relationship_parameter_values,
        )
        
        m = run_spineopt(url_in; log_level=0, optimize=false)
        connection_flow = m.ext[:spineopt].variables[:connection_flow]
        key = (connection(:connection_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(m; temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = connection_flow_cost * sum(
            connection_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices)
        )
        @test observed_obj == expected_obj
    end
end

function test_units_on_cost()
    @testset "units_on_cost" begin
        url_in = _test_objective_setup()
        units_on_cost = 913
        object_parameter_values = [["unit", "unit_ab", "units_on_cost", units_on_cost]]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        units_on = m.ext[:spineopt].variables[:units_on]        
        s_parent = stochastic_scenario(:parent)
        t2h = time_slice(m; temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = 2 * units_on_cost * units_on[unit(:unit_ab), s_parent, t2h]
        @test observed_obj == expected_obj
    end
end

@testset "objective" begin
    test_fom_cost_case_1a()
    test_fom_cost_case_1b()
    test_fom_cost_case_2a()
    test_fom_cost_case_2b()
    test_fuel_cost()
    test_unit_investment_cost()
    test_node_slack_penalty()
    test_user_constraint_slack_penalty()
    test_shut_down_cost()
    test_start_up_cost()
    test_vom_cost()
    test_connection_flow_cost()
    test_units_on_cost()
end
