
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

function _test_constraint_investment_group_setup()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "investments_two_hourly"],
            ["temporal_block", "investments_four_hourly"],
            ["stochastic_structure", "investments_deterministic"],
            ["stochastic_structure", "investments_stochastic"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["unit", "unit_ab"],
            ["connection", "connection_bc"],
            ["investment_group", "ig"],
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "investments_two_hourly"]],
            ["model__temporal_block", ["instance", "investments_four_hourly"]],
            ["model__default_temporal_block", ["instance", "investments_four_hourly"]],
            ["model__stochastic_structure", ["instance", "investments_deterministic"]],
            ["model__stochastic_structure", ["instance", "investments_stochastic"]],
            ["model__default_stochastic_structure", ["instance", "investments_stochastic"]],
            ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["investments_stochastic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["investments_stochastic", "child"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
            ["node__investment_temporal_block", ["node_a", "investments_two_hourly"]],
            ["node__investment_temporal_block", ["node_b", "investments_four_hourly"]],
            ["node__investment_temporal_block", ["node_c", "investments_two_hourly"]],
            ["node__investment_stochastic_structure", ["node_a", "investments_stochastic"]],
            ["node__investment_stochastic_structure", ["node_b", "investments_deterministic"]],
            ["node__investment_stochastic_structure", ["node_c", "investments_deterministic"]],
            ["unit__investment_temporal_block", ["unit_ab", "investments_four_hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "investments_deterministic"]],
            ["connection__investment_temporal_block", ["connection_bc", "investments_four_hourly"]],
            ["connection__investment_stochastic_structure", ["connection_bc", "investments_deterministic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["unit__investment_group", ["unit_ab", "ig"]],
            ["connection__investment_group", ["connection_bc", "ig"]],
            ["node__investment_group", ["node_c", "ig"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T04:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["node", "node_c", "has_state", true],
            ["node", "node_c", "node_state_cap", 100],
            ["node", "node_c", "candidate_storages", 2],
            ["node", "node_c", "storage_investment_cost", 1000],
            ["unit", "unit_ab", "candidate_units", 3],
            ["unit", "unit_ab", "unit_investment_cost", 1000],
            ["connection", "connection_bc", "candidate_connections", 1],
            ["connection", "connection_bc", "connection_investment_cost", 1000],
            ["temporal_block", "investments_two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["temporal_block", "investments_four_hourly", "resolution", Dict("type" => "duration", "data" => "4h")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
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

function _test_equal_investments()
    @testset "equal_investments" begin
        url_in = _test_constraint_investment_group_setup()
        object_parameter_values = [["investment_group", "ig", "equal_investments", true]]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        constraint = m.ext[:spineopt].constraints[:investment_group_equal_investments]
        unit_ab = unit(:unit_ab)
        connection_bc = connection(:connection_bc)
        node_c = node(:node_c)
        parent = stochastic_scenario(:parent)
        t4h = first(time_slice(m; temporal_block=temporal_block(:investments_four_hourly)))
        key_head = (investment_group=investment_group(:ig), entity1=unit_ab)
        key_tail = (stochastic_scenario=parent, t=t4h)
        u_ab_inv_avail = m.ext[:spineopt].variables[:units_invested_available][unit_ab, parent, t4h]
        conn_bc_inv_avail = [m.ext[:spineopt].variables[:connections_invested_available][connection_bc, parent, t4h]]
        node_c_inv_avail = [
            m.ext[:spineopt].variables[:storages_invested_available][node_c, parent, t]
            for t in time_slice(m; temporal_block=temporal_block(:investments_two_hourly))
        ]
        @testset for entity2 in (connection_bc, node_c)
            con_key = (; key_head..., entity2=entity2, key_tail...)
            observed_con = constraint_object(constraint[con_key])
            other_inv_avail = Dict(connection_bc => conn_bc_inv_avail, node_c => node_c_inv_avail)[entity2]
            expected_con = @build_constraint(u_ab_inv_avail == sum(other_inv_avail))
            @test _is_constraint_equal(observed_con, expected_con)
        end
    end
end

function _test_min_max_entities_invested_available()
    @testset "min_max_entities_invested_available" begin
        url_in = _test_constraint_investment_group_setup()
        object_parameter_values = [
            ["investment_group", "ig", "minimum_entities_invested_available", 3],
            ["investment_group", "ig", "maximum_entities_invested_available", 8],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        constraint = m.ext[:spineopt].constraints[:investment_group_minimum_entities_invested_available]
        unit_ab = unit(:unit_ab)
        connection_bc = connection(:connection_bc)
        node_c = node(:node_c)
        parent = stochastic_scenario(:parent)
        t4h = first(time_slice(m; temporal_block=temporal_block(:investments_four_hourly)))
        con_key = (investment_group=investment_group(:ig), stochastic_scenario=parent, t=t4h)
        u_ab_inv_avail = m.ext[:spineopt].variables[:units_invested_available][unit_ab, parent, t4h]
        conn_bc_inv_avail = m.ext[:spineopt].variables[:connections_invested_available][connection_bc, parent, t4h]
        node_c_inv_avail = [
            m.ext[:spineopt].variables[:storages_invested_available][node_c, parent, t]
            for t in time_slice(m; temporal_block=temporal_block(:investments_two_hourly))
        ]
        observed_con = constraint_object(
            m.ext[:spineopt].constraints[:investment_group_minimum_entities_invested_available][con_key]
        )
        expected_con = @build_constraint(u_ab_inv_avail + conn_bc_inv_avail + sum(node_c_inv_avail) >= 3)
        @test _is_constraint_equal(observed_con, expected_con)
        observed_con = constraint_object(
            m.ext[:spineopt].constraints[:investment_group_maximum_entities_invested_available][con_key]
        )
        expected_con = @build_constraint(u_ab_inv_avail + conn_bc_inv_avail + sum(node_c_inv_avail) <= 8)
        @test _is_constraint_equal(observed_con, expected_con)
    end
end

function _test_min_max_capacity_invested_available()
    @testset "min_max_capacity_invested_available" begin
        url_in = _test_constraint_investment_group_setup()
        object_parameter_values = [
            ["investment_group", "ig", "minimum_capacity_invested_available", 300],
            ["investment_group", "ig", "maximum_capacity_invested_available", 800],
        ]
        relationships = [
            ("unit__from_node__investment_group", ("unit_ab", "node_a", "ig")),
            ("connection__to_node__investment_group", ("connection_bc", "node_c", "ig")),
        ]
        relationship_parameter_values = [
            ("unit__from_node", ("unit_ab", "node_a"), "unit_capacity", 150),
            ("connection__to_node", ("connection_bc", "node_c"), "connection_capacity", 250),
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
            relationships=relationships,
        )
        m = run_spineopt(url_in; log_level=0, optimize=false)
        unit_ab = unit(:unit_ab)
        connection_bc = connection(:connection_bc)
        parent = stochastic_scenario(:parent)
        t4h = first(time_slice(m; temporal_block=temporal_block(:investments_four_hourly)))
        con_key = (investment_group=investment_group(:ig), stochastic_scenario=parent, t=t4h)
        u_ab_inv_avail = m.ext[:spineopt].variables[:units_invested_available][unit_ab, parent, t4h]
        conn_bc_inv_avail = m.ext[:spineopt].variables[:connections_invested_available][connection_bc, parent, t4h]
        observed_con = constraint_object(
            m.ext[:spineopt].constraints[:investment_group_minimum_capacity_invested_available][con_key]
        )
        expected_con = @build_constraint(150 * u_ab_inv_avail + 250 * conn_bc_inv_avail >= 300)
        @test _is_constraint_equal(observed_con, expected_con)
        observed_con = constraint_object(
            m.ext[:spineopt].constraints[:investment_group_maximum_capacity_invested_available][con_key]
        )
        expected_con = @build_constraint(150 * u_ab_inv_avail + 250 * conn_bc_inv_avail <= 800)
        @test _is_constraint_equal(observed_con, expected_con)
    end
end

@testset "investment_group" begin
    _test_equal_investments()
    _test_min_max_entities_invested_available()
    _test_min_max_capacity_invested_available()
end
