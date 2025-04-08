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

function _test_run_spineopt_investments_setup()
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    start, end_ = DateTime(2000), DateTime(2000, 1, 8)
    res = Hour(1)
    inds = collect(start:res:end_)
    season_duration = Week(12)
    season_length = div(season_duration, res)
    season_count = div(end_ - start, season_duration, RoundUp)
    demand_vals = vcat((fill(100 + 50 * (-1) ^ k, season_length) for k in 1:season_count)...)
    demand_ts = TimeSeries(inds, demand_vals)
    half_day_duration = Hour(12)
    half_day_length = div(half_day_duration, res)
    half_day_count = div(end_ - start, half_day_duration, RoundUp)
    vom_cost_vals = vcat((fill(0.75 + 0.25 * (-1) ^ k, half_day_length) for k in 1:half_day_count)...)
    vom_cost_ts = TimeSeries(inds, vom_cost_vals)
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "operations"],
            ["temporal_block", "investments"],
            ["stochastic_structure", "deterministic"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["connection", "connection_ab"],
            ["unit", "unit_a"],
            ["unit", "unit_b"],
            ["stochastic_scenario", "realisation"],
            ["report", "report_x"],
            ["output", "units_invested"],
            ["output", "storages_invested"],
            ["output", "connections_invested"],
            ["output", "variable_om_costs"],
        ],
        :relationships => [
            ["unit__to_node", ["unit_a", "node_a"]],
            ["unit__to_node", ["unit_b", "node_b"]],
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
            ["model__default_temporal_block", ["instance", "operations"]],
            ["model__default_stochastic_structure", ["instance", "deterministic"]],
            ["model__default_investment_temporal_block", ["instance", "investments"]],
            ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "realisation"]],
            ["report__output", ["report_x", "units_invested"]],
            ["report__output", ["report_x", "storages_invested"]],
            ["report__output", ["report_x", "connections_invested"]],
            ["model__report", ["instance", "report_x"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", unparse_db_value(start)],
            ["model", "instance", "model_end", unparse_db_value(end_)],
            ["model", "instance", "duration_unit", "hour"],
            ["temporal_block", "operations", "resolution", unparse_db_value(Hour(1))],
            ["temporal_block", "investments", "resolution", unparse_db_value(Year(1))],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
            ["node", "node_b", "demand", unparse_db_value(demand_ts)],
            ["node", "node_a", "has_state", true],
            ["node", "node_a", "initial_node_state", 0],
            ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"],
        ],
        :relationship_parameter_values => [
            ["unit__to_node", ["unit_a", "node_a"], "vom_cost", unparse_db_value(vom_cost_ts)],
            ["unit__to_node", ["unit_b", "node_b"], "unit_capacity", 200],
            ["unit__to_node", ["unit_b", "node_b"], "vom_cost", 1],
        ]
    )
    _load_test_data(url_in, test_data)
    url_in, url_out, file_path_out
end

function _test_capacity_investments()
    @testset "capacity_investments" begin
        url_in, url_out, file_path_out = _test_run_spineopt_investments_setup()
        object_parameter_values = [
            ["model", "instance", "use_connection_intact_flow", false],
            ["unit", "unit_a", "number_of_units", 10],
            ["unit", "unit_a", "candidate_units", 40],
            ["unit", "unit_a", "unit_investment_cost", 0],
            ["unit", "unit_a", "unit_investment_variable_type", "unit_investment_variable_type_continuous"],
            ["node", "node_a", "number_of_storages", 5],
            ["node", "node_a", "candidate_storages", 20],
            ["node", "node_a", "storage_investment_cost", 0],
            ["node", "node_a", "storage_investment_variable_type", "storage_investment_variable_type_continuous"],
            ["connection", "connection_ab", "number_of_connections", 5],
            ["connection", "connection_ab", "candidate_connections", 20],
            ["connection", "connection_ab", "connection_investment_cost", 0],
            [
                "connection",
                "connection_ab",
                "connection_investment_variable_type",
                "connection_investment_variable_type_continuous"
            ],
            ["node", "node_a", "node_state_cap", 1]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_a", "node_a"], "unit_capacity", 1],
            ["connection__from_node", ["connection_ab", "node_a"], "connection_capacity", 1],
        ]
        import_count, errors = SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        @test isempty(errors)
        rm(file_path_out; force=true)
        m = run_spineopt(url_in, url_out; log_level=3)
        Y = Module()
        @eval Y using SpineInterface
        using_spinedb(url_out, Y)
        @test Y.units_invested(unit=Y.unit(:unit_a), t=DateTime(2000)) == 40
        @test Y.connections_invested(connection=Y.connection(:connection_ab), t=DateTime(2000)) == 20
        @test Y.storages_invested(node=Y.node(:node_a), t=DateTime(2000)) == 20
    end
end

@testset "run_spineopt_investments" begin
    _test_capacity_investments()
end