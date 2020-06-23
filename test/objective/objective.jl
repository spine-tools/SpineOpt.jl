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

@testset "objective" begin
    url_in = "sqlite:///$(@__DIR__)/test.sqlite"
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
            ["units_on_resolution", ["unit_ab", "node_a"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
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
    @testset "fixed_om_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        unit_capacity = 100
        number_of_units = 4
        fom_cost = 125
        object_parameter_values = [
            ["unit", "unit_ab", "number_of_units", number_of_units],
            ["unit", "unit_ab", "fom_cost", fom_cost]
        ]
        relationship_parameter_values = [["unit__from_node", ["unit_ab", "node_a"], "unit_capacity", unit_capacity]]
        db_api.import_data_to_url(
            url_in; 
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in; log_level=0)
        t_count = length(time_slice(temporal_block=temporal_block(:two_hourly)))
        duration = 2
        expected_obj = AffExpr(unit_capacity * number_of_units * fom_cost * duration * t_count)
        observed_obj = objective_function(m)
        @test observed_obj == expected_obj
    end
    @testset "fuel_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        fuel_cost = 125
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", fuel_cost]]
        db_api.import_data_to_url(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        unit_flow = m.ext[:variables][:unit_flow]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = fuel_cost * sum(unit_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices))
        @test observed_obj == expected_obj
    end
    @testset "investment_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        unit_investment_cost = 1000
        candidate_units = 3
        object_parameter_values = [
            ["unit", "unit_ab", "unit_investment_cost", unit_investment_cost],
            ["unit", "unit_ab", "candidate_units", candidate_units]
        ]
        relationships = [
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
        ]
        db_api.import_data_to_url(url_in; relationships=relationships, object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        units_invested = m.ext[:variables][:units_invested]
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = (
            unit_investment_cost * sum(units_invested[unit(:unit_ab), s, t] for (s, t) in zip(scenarios, time_slices))
        )
        @test observed_obj == expected_obj
    end
    @testset "objective_penalties" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        node_a_slack_penalty = 0.6
        node_b_slack_penalty = 0.4
        object_parameter_values = [
            ["node", "node_a", "node_slack_penalty", node_a_slack_penalty],
            ["node", "node_b", "node_slack_penalty", node_b_slack_penalty],
        ]
        db_api.import_data_to_url(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        node_slack_neg = m.ext[:variables][:node_slack_neg]
        node_slack_pos = m.ext[:variables][:node_slack_pos]
        n_a = node(:node_a)
        n_b = node(:node_b)
        s_parent = stochastic_scenario(:parent)
        s_child = stochastic_scenario(:child)
        t1h1, t1h2 = time_slice(temporal_block=temporal_block(:hourly))
        t2h = time_slice(temporal_block=temporal_block(:two_hourly))[1]
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
    @testset "operating_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        operating_cost = 180
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "operating_cost", operating_cost]]
        db_api.import_data_to_url(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        unit_flow = m.ext[:variables][:unit_flow]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = operating_cost * sum(unit_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices))
        @test observed_obj == expected_obj
    end
    @testset "shut_down_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        shut_down_cost = 180
        object_parameter_values = [["unit", "unit_ab", "shut_down_cost", shut_down_cost]]
        db_api.import_data_to_url(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        units_shut_down = m.ext[:variables][:units_shut_down]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        s_parent = stochastic_scenario(:parent)
        t2h = time_slice(temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = shut_down_cost * units_shut_down[unit(:unit_ab), s_parent, t2h]
        @test observed_obj == expected_obj
    end
    @testset "start_up_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        start_up_cost = 220
        object_parameter_values = [["unit", "unit_ab", "start_up_cost", start_up_cost]]
        db_api.import_data_to_url(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        units_started_up = m.ext[:variables][:units_started_up]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        s_parent = stochastic_scenario(:parent)
        t2h = time_slice(temporal_block=temporal_block(:two_hourly))[1]
        observed_obj = objective_function(m)
        expected_obj = start_up_cost * units_started_up[unit(:unit_ab), s_parent, t2h]
        @test observed_obj == expected_obj
    end
    @testset "vom_cost" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        vom_cost = 150
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost]]
        db_api.import_data_to_url(url_in; relationship_parameter_values=relationship_parameter_values)
        m = run_spineopt(url_in; log_level=0)
        unit_flow = m.ext[:variables][:unit_flow]
        key = (unit(:unit_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        expected_obj = vom_cost * sum(unit_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices))
        @test observed_obj == expected_obj
    end
    @testset "connection_flow_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        connection_flow_cost = 185
        objects = [["connection", "connection_ab"]]
        relationships = [["connection__to_node", ["connection_ab", "node_b"]]]
        object_parameter_values = [["connection", "connection_ab", "connection_flow_cost", connection_flow_cost]]
        db_api.import_data_to_url(
            url_in; 
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values
        )
        m = run_spineopt(url_in; log_level=0)
        connection_flow = m.ext[:variables][:connection_flow]
        key = (connection(:connection_ab), node(:node_b), direction(:to_node))
        scenarios = (stochastic_scenario(:parent), stochastic_scenario(:child))
        time_slices = time_slice(temporal_block=temporal_block(:hourly))
        observed_obj = objective_function(m)
        _dismember_function(observed_obj)
        expected_obj = connection_flow_cost * sum(connection_flow[(key..., s, t)...] for (s, t) in zip(scenarios, time_slices))
        @test observed_obj == expected_obj
    end
end