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

module Y
using SpineInterface
end

function _test_run_spineopt_benders_setup()
    url_in = "sqlite://"
    file_path_out = tempname(cleanup=true)
    url_out = "sqlite:///$file_path_out"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "unused_structure"],
            ["unit", "unit_ab"],
            ["node", "node_b"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "unused_child"],
            ["report", "report_x"],
            ["output", "unit_flow"],
            ["output", "variable_om_costs"],
        ],
        :relationships => [
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["units_on__temporal_block", ["unit_ab", "hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["unused_structure", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["unused_structure", "unused_child"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "unused_child"]],
            ["report__output", ["report_x", "unit_flow"]],
            ["report__output", ["report_x", "variable_om_costs"]],
            ["model__report", ["instance", "report_x"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T00:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["output", "unit_flow", "output_resolution", Dict("type" => "duration", "data" => "1h")],
            ["output", "variable_om_costs", "output_resolution", Dict("type" => "duration", "data" => "1h")],
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"]
        ],
    )
    _load_test_data(url_in, test_data)
    url_in, url_out, file_path_out
end

function _test_benders_unit()
    @testset "benders_unit" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        res = 6
        dem = ucap = 10
        rf = 6
        look_ahead = 3
        vom_cost_ = 2
        vom_cost_alt = vom_cost_ / 2
        op_cost_no_inv = ucap * vom_cost_ * (24 + look_ahead)
        op_cost_inv = ucap * vom_cost_alt * (24 + look_ahead)
        do_not_inv_cost = op_cost_no_inv - op_cost_inv + 1 # minimum cost at which investment is not profitable, 271.0
        do_inv_cost = do_not_inv_cost - 2  # maximum cost at which investment is profitable, 269.0
        @testset for should_invest in (true, false)
            u_inv_cost = should_invest ? do_inv_cost : do_not_inv_cost
            url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
            objects = [
                ["unit", "unit_ab_alt"],
                ["output", "total_costs"],
                ["output", "units_invested"],
                ["output", "units_mothballed"],
                ["output", "units_invested_available"],
                ["output", "unit_investment_costs"],
                ["temporal_block", "investments_hourly"],
            ]
            relationships = [
                ["unit__to_node", ["unit_ab_alt", "node_b"]],
                ["units_on__temporal_block", ["unit_ab_alt", "hourly"]],
                ["units_on__stochastic_structure", ["unit_ab_alt", "deterministic"]],
                ["model__temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
                ["report__output", ["report_x", "total_costs"]],
                ["report__output", ["report_x", "units_invested"]],
                ["report__output", ["report_x", "units_mothballed"]],
                ["report__output", ["report_x", "units_invested_available"]],
                ["report__output", ["report_x", "unit_investment_costs"]],
            ]
            object_parameter_values = [
                ["model", "instance", "roll_forward", unparse_db_value(Hour(rf))],
                ["model", "instance", "model_type", "spineopt_benders"],
                ["model", "instance", "max_iterations", 10],
                ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
                ["node", "node_b", "demand", dem],
                ["unit", "unit_ab_alt", "number_of_units", 0],
                ["unit", "unit_ab_alt", "candidate_units", 1],
                ["unit", "unit_ab_alt", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "unit_ab_alt", "online_variable_type", "unit_online_variable_type_integer"],
                ["unit", "unit_ab_alt", "unit_investment_cost", u_inv_cost],
                ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(rf + look_ahead))],
                ["temporal_block", "investments_hourly", "block_end", unparse_db_value(Hour(24 + look_ahead))],
                ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(res))],
                ["temporal_block", "investments_hourly", "resolution", unparse_db_value(Hour(res))],
            ]
            relationship_parameter_values = [
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost_],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "vom_cost", vom_cost_alt],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values
            )
            run_spineopt(url_in, url_out; log_level=0)
            using_spinedb(url_out, Y)
            @testset "total_cost" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 23)
                    exp_total_costs = if should_invest
                        t == DateTime(2000, 1, 1) ? u_inv_cost + 60 : 60
                    else
                        120
                    end
                    @test Y.total_costs(model=Y.model(:instance), t=t) == exp_total_costs
                end
            end
            @testset "unit_investment_costs" begin
                @test Y.objective_unit_investment_costs(model=Y.model(:instance), t=DateTime(2000, 1, 1)) == (
                    should_invest ? u_inv_cost : 0
                )
            end
            @testset "invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested(unit=Y.unit(:unit_ab_alt), t=t) == (
                        should_invest && t == DateTime(2000, 1, 1) ? 1 : 0
                    )
                end
            end
            @testset "mothballed" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_mothballed(unit=Y.unit(:unit_ab_alt), t=t) == 0
                end
            end
            @testset "available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested_available(unit=Y.unit(:unit_ab_alt), t=t) == (should_invest ? 1 : 0)
                end
            end
        end
    end
end

function _test_benders_storage()
    @testset "benders_storage" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        res = 6 # resolution
        dem = ucap = 10
        fixuflow = 2 * dem # 20
        rf = 6 # row forward
        look_ahead = 3
        penalty = 100
        op_cost_no_inv = (fixuflow - dem) * penalty * (24 + look_ahead) # (20-10)*100*(24+3) = 27000
        op_cost_inv = 0
        do_not_inv_cost = op_cost_no_inv - op_cost_inv + 1 # minimum cost at which investment is not profitable, 27001
        do_inv_cost = do_not_inv_cost - 2  # maximum cost at which investment is profitable, 26999
        @testset for should_invest in (true, false)
            s_inv_cost = should_invest ? do_inv_cost : do_not_inv_cost
            url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
            objects = [
                ["unit", "unit_a"],
                ["node", "node_a"],
                ["output", "total_costs"],
                ["output", "storages_invested"],
                ["output", "storages_decommissioned"],
                ["output", "storages_invested_available"],
                ["output", "node_state"],
                ["output", "node_slack_neg"],
                ["temporal_block", "investments_hourly"],
            ]
            relationships = [
                ["unit__to_node", ["unit_a", "node_a"]],
                ["unit__from_node", ["unit_ab", "node_a"]],
                ["unit__node__node", ["unit_ab", "node_b", "node_a"]],
                ["units_on__stochastic_structure", ["unit_a", "deterministic"]],
                ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
                ["node__temporal_block", ["node_a", "hourly"]],
                ["node__stochastic_structure", ["node_a", "deterministic"]],
                ["model__temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
                ["report__output", ["report_x", "total_costs"]],
                ["report__output", ["report_x", "storages_invested"]],
                ["report__output", ["report_x", "storages_decommissioned"]],
                ["report__output", ["report_x", "storages_invested_available"]],
                ["report__output", ["report_x", "node_slack_neg"]],
                ["report__output", ["report_x", "node_state"]],
            ]
            object_parameter_values = [
                ["model", "instance", "roll_forward", unparse_db_value(Hour(rf))],
                ["model", "instance", "model_type", "spineopt_benders"],
                ["model", "instance", "max_iterations", 10],
                ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
                ["node", "node_a", "has_state", true],
                ["node", "node_a", "node_state_cap", 1000],
                ["node", "node_a", "initial_node_state", 0],
                # ["node", "node_a", "initial_storages_invested", 0],
                ["node", "node_a", "candidate_storages", 1],
                ["node", "node_a", "storage_investment_cost", s_inv_cost],
                ["node", "node_a", "storage_investment_variable_type", "variable_type_integer"],
                ["node", "node_b", "demand", dem],
                ["node", "node_a", "node_slack_penalty", penalty],
                ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(rf + look_ahead))],
                ["temporal_block", "investments_hourly", "block_end", unparse_db_value(Hour(24 + look_ahead))],
                ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(res))],
                ["temporal_block", "investments_hourly", "resolution", unparse_db_value(Hour(res))],
            ]
            relationship_parameter_values = [
                ["unit__to_node", ["unit_a", "node_a"], "fix_unit_flow", fixuflow],
                ["unit__node__node", ["unit_ab", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values
            )
            m = run_spineopt(url_in, url_out; log_level=0)
            using_spinedb(url_out, Y)
            @testset "total_cost" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 23)
                    exp_total_costs = if should_invest
                        t == DateTime(2000, 1, 1) ? s_inv_cost : 0
                    else
                        6000
                    end
                    @test Y.total_costs(model=Y.model(:instance), t=t) == exp_total_costs
                end
            end
            @testset "invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.storages_invested(node=Y.node(:node_a), t=t) == (
                        should_invest && t == DateTime(2000, 1, 1) ? 1 : 0
                    )
                end
            end
            @testset "decommissioned" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.storages_decommissioned(node=Y.node(:node_a), t=t) == 0
                end
            end
            @testset "available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.storages_invested_available(node=Y.node(:node_a), t=t) == (should_invest ? 1 : 0)
                end
            end
            @testset "node_slack_neg" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.node_slack_neg(node=Y.node(:node_a), t=t) == (should_invest ? 0 : 10)
                end
            end
            @testset "node_state" begin
                @testset for (k, t) in enumerate(DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 23))
                    @test Y.node_state(node=Y.node(:node_a), t=t) == (should_invest ? 60 * k : 0)
                end
            end
        end
    end
end

function _test_benders_unit_storage()
    @testset "benders_unit_storage" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        res = 6
        dem = ucap = 10
        ucap2 = 2 * dem
        mop = 0.9
        rf = 6
        look_ahead = 3
        penalty = 100
        u_inv_cost = 180
        op_cost_no_inv = (mop * ucap2 - dem) * penalty * (24 + look_ahead)
        op_cost_inv = 0
        do_not_inv_cost = op_cost_no_inv - op_cost_inv + 1 # minimum cost at which investment is not profitable
        do_inv_cost = do_not_inv_cost - 2  # maximum cost at which investment is profitable
        @testset for should_invest in (true, false)
            s_inv_cost = should_invest ? do_inv_cost : do_not_inv_cost
            url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
            objects = [
                ["unit", "unit_a"],
                ["node", "node_a"],
                ["output", "total_costs"],
                ["output", "units_invested"],
                ["output", "units_mothballed"],
                ["output", "units_invested_available"],
                ["output", "storages_invested"],
                ["output", "storages_decommissioned"],
                ["output", "storages_invested_available"],
                ["output", "node_state"],
                ["output", "node_slack_neg"],
                ["temporal_block", "investments_hourly"],
            ]
            relationships = [
                ["unit__to_node", ["unit_a", "node_a"]],
                ["unit__from_node", ["unit_ab", "node_a"]],
                ["unit__node__node", ["unit_ab", "node_b", "node_a"]],
                ["units_on__temporal_block", ["unit_a", "hourly"]],
                ["units_on__stochastic_structure", ["unit_a", "deterministic"]],
                ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
                ["node__temporal_block", ["node_a", "hourly"]],
                ["node__stochastic_structure", ["node_a", "deterministic"]],
                ["model__temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
                ["report__output", ["report_x", "total_costs"]],
                ["report__output", ["report_x", "units_invested"]],
                ["report__output", ["report_x", "units_mothballed"]],
                ["report__output", ["report_x", "units_invested_available"]],
                ["report__output", ["report_x", "storages_invested"]],
                ["report__output", ["report_x", "storages_decommissioned"]],
                ["report__output", ["report_x", "storages_invested_available"]],
                ["report__output", ["report_x", "node_slack_neg"]],
                ["report__output", ["report_x", "node_state"]],
            ]
            object_parameter_values = [
                ["model", "instance", "roll_forward", unparse_db_value(Hour(rf))],
                ["model", "instance", "model_type", "spineopt_benders"],
                ["model", "instance", "max_iterations", 100],
                ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
                ["unit", "unit_a", "number_of_units", 0],
                ["unit", "unit_a", "candidate_units", 1],
                ["unit", "unit_a", "unit_investment_cost", u_inv_cost],
                ["unit", "unit_a", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "unit_a", "online_variable_type", "unit_online_variable_type_integer"],
                ["node", "node_a", "has_state", true],
                ["node", "node_a", "node_state_cap", 1000],
                ["node", "node_a", "initial_node_state", 0],
                ["node", "node_a", "candidate_storages", 1],
                ["node", "node_a", "storage_investment_cost", s_inv_cost],
                ["node", "node_a", "storage_investment_variable_type", "variable_type_integer"],
                ["node", "node_b", "demand", dem],
                ["node", "node_a", "node_slack_penalty", penalty],
                ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(rf + look_ahead))],
                ["temporal_block", "investments_hourly", "block_end", unparse_db_value(Hour(24 + look_ahead))],
                ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(res))],
                ["temporal_block", "investments_hourly", "resolution", unparse_db_value(Hour(res))],
            ]
            relationship_parameter_values = [
                ["unit__node__node", ["unit_ab", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_a", "node_a"], "unit_capacity", ucap2],
                ["unit__to_node", ["unit_a", "node_a"], "minimum_operating_point", mop],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values
            )
            m = run_spineopt(url_in, url_out; log_level=0)
            using_spinedb(url_out, Y)
            @testset "total_cost" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 23)
                    exp_total_costs = if should_invest
                        t == DateTime(2000, 1, 1) ? s_inv_cost : 0
                    else
                        4800
                    end
                    @test Y.total_costs(model=Y.model(:instance), t=t) == exp_total_costs
                end
            end
            @testset "units_invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested(unit=Y.unit(:unit_a), t=t) == (t == DateTime(2000, 1, 1) ? 1 : 0)
                end
            end
            @testset "units_mothballed" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_mothballed(unit=Y.unit(:unit_a), t=t) == 0
                end
            end
            @testset "units_invested_available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested_available(unit=Y.unit(:unit_a), t=t) == 1
                end
            end
            @testset "storages_invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.storages_invested(node=Y.node(:node_a), t=t) == (
                        should_invest && t == DateTime(2000, 1, 1) ? 1 : 0
                    )
                end
            end
            @testset "storages_decommissioned" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.storages_decommissioned(node=Y.node(:node_a), t=t) == 0
                end
            end
            @testset "storages_invested_available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.storages_invested_available(node=Y.node(:node_a), t=t) == (should_invest ? 1 : 0)
                end
            end
            @testset "node_slack_neg" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.node_slack_neg(node=Y.node(:node_a), t=t) == (should_invest ? 0 : 8)
                end
            end
            @testset "node_state" begin
                state = 0
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    hour_count = t < DateTime(2000, 1, 2) ? rf : rf / 2
                    if state < dem * hour_count
                        # store
                        incr = (mop * ucap2 - dem)  # 8
                        state += incr * hour_count
                    else
                        # release
                        state -= dem * hour_count
                    end
                    @test Y.node_state(node=Y.node(:node_a), t=t) == (should_invest ? state : 0)
                end
            end
        end
    end
end

function _test_benders_rolling_representative_periods()
    @testset "benders_rolling_representative_periods" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        res = 1
        dem = ucap = 10
        rf = 6
        look_ahead = 3
        wd = rf + look_ahead
        vom_cost_ = 2
        vom_cost_alt = vom_cost_ / 2
        op_cost_no_inv = ucap * vom_cost_ * (24 + look_ahead)  # 540
        op_cost_inv = ucap * vom_cost_alt * (24 + look_ahead)  # 270
        do_not_inv_cost = op_cost_no_inv - op_cost_inv + 1  # 271, maximum cost at which investment is profitable
        do_inv_cost = do_not_inv_cost - 2  # 269, minimum cost at which investment is not profitable
        @testset for should_invest in (true, false)
            u_inv_cost = should_invest ? do_inv_cost : do_not_inv_cost
            url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
            objects = [
                ["unit", "unit_ab_alt"],
                ["output", "total_costs"],
                ["output", "units_invested"],
                ["output", "units_on"],
                ["output", "units_available"],
                ["output", "units_mothballed"],
                ["output", "units_invested_available"],
                ["temporal_block", "investments_hourly"],
            ]
            relationships = [
                ["unit__to_node", ["unit_ab_alt", "node_b"]],
                ["units_on__temporal_block", ["unit_ab_alt", "hourly"]],
                ["units_on__stochastic_structure", ["unit_ab_alt", "deterministic"]],
                ["model__temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
                ["report__output", ["report_x", "units_invested_available"]],
                ["report__output", ["report_x", "units_mothballed"]],
                ["report__output", ["report_x", "units_invested"]],
                ["report__output", ["report_x", "total_costs"]],
            ]
            object_parameter_values = [
                ["model", "instance", "window_duration", unparse_db_value(Hour(wd))],  # 9
                ["model", "instance", "roll_forward", unparse_db_value([Hour(2 * rf)])],  # 12
                ["model", "instance", "window_weight", unparse_db_value([wd / rf, wd / rf])],  # 1.5, 1.5
                ["model", "instance", "model_type", "spineopt_benders"],
                ["model", "instance", "max_iterations", 10],
                ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
                ["node", "node_b", "demand", dem],
                ["unit", "unit_ab_alt", "number_of_units", 0],
                ["unit", "unit_ab_alt", "candidate_units", 1],
                ["unit", "unit_ab_alt", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "unit_ab_alt", "online_variable_type", "unit_online_variable_type_integer"],
                ["unit", "unit_ab_alt", "unit_investment_cost", u_inv_cost],
                ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(rf + look_ahead))],
                ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(rf))],
                ["temporal_block", "investments_hourly", "resolution", unparse_db_value(Hour(rf))],
            ]
            relationship_parameter_values = [
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost_],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "vom_cost", vom_cost_alt],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values
            )
            m = run_spineopt(url_in, url_out; log_level=0)
            m_mp = master_model(m)
            using_spinedb(url_out, Y)
            @testset "total_cost" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 12)
                    exp_total_costs = if should_invest
                        t in (DateTime(2000, 1, 1), DateTime(2000, 1, 1, 6)) ? u_inv_cost + 90 : 90
                    else
                        180
                    end
                    @test Y.total_costs(model=Y.model(:instance), t=t) == exp_total_costs
                end
            end
            @testset "invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 18)
                    @test Y.units_invested(unit=Y.unit(:unit_ab_alt), t=t) == (
                        should_invest && t == DateTime(2000, 1, 1) ? 1 : 0
                    )
                end
            end
            @testset "mothballed" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 18)
                    @test Y.units_mothballed(unit=Y.unit(:unit_ab_alt), t=t) == 0
                end
            end
            @testset "available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 18)
                    @test Y.units_invested_available(unit=Y.unit(:unit_ab_alt), t=t) == (should_invest ? 1 : 0)
                end
            end
        end
    end
end

function _test_benders_rolling_representative_periods_yearly_investments_multiple_units()
    @testset "benders_rolling_representative_periods_yearly_investments_multiple_units" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        candidates = [string("investments_candidate_", k) for k in 1:10]
        dem = 7
        url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
        objects = [
            ["output", "total_costs"],
            ["output", "units_invested"],
            ["output", "units_on"],
            ["output", "units_available"],
            ["output", "units_mothballed"],
            ["output", "units_invested_available"],
            ["temporal_block", "investments_yearly"],
        ]
        append!(objects, [["unit", c] for c in candidates])
        relationships = [
            ["model__default_investment_temporal_block", ["instance", "investments_yearly"]],
            ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
            ["report__output", ["report_x", "units_invested_available"]],
            ["report__output", ["report_x", "units_mothballed"]],
            ["report__output", ["report_x", "units_invested"]],
            ["report__output", ["report_x", "total_costs"]],
        ]
        append!(relationships, [["unit__to_node", [c, "node_b"]] for c in candidates])
        append!(relationships, [["units_on__temporal_block", [c, "hourly"]] for c in candidates])
        append!(relationships, [["units_on__stochastic_structure", [c, "deterministic"]] for c in candidates])
        object_parameter_values = [
            ["model", "instance", "model_start", unparse_db_value(DateTime(2000))],
            ["model", "instance", "model_end", unparse_db_value(DateTime(2001))],
            ["model", "instance", "window_duration", unparse_db_value(Day(1))],
            ["model", "instance", "roll_forward", unparse_db_value([Day(14) for k in 1:23])],
            ["model", "instance", "window_weight", unparse_db_value([14.0 for k in 1:24])],
            ["model", "instance", "model_type", "spineopt_benders"],
            ["model", "instance", "max_iterations", 10],
            ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
            ["node", "node_b", "demand", dem],
            ["node", "node_b", "node_slack_penalty", 10000],
            ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(36))],
            ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(6))],
            ["temporal_block", "investments_yearly", "resolution", unparse_db_value(Year(1))],
        ]
        append!(object_parameter_values, [["unit", c, "number_of_units", 0] for c in candidates])
        append!(object_parameter_values, [["unit", c, "candidate_units", 1] for c in candidates])
        append!(
            object_parameter_values,
            [["unit", c, "unit_investment_variable_type", "unit_investment_variable_type_integer"] for c in candidates]
        )
        append!(
            object_parameter_values,
            [["unit", c, "online_variable_type", "unit_online_variable_type_integer"] for c in candidates]
        )
        append!(
            object_parameter_values,
            [["unit", c, "unit_investment_cost", 20 * k] for (k, c) in enumerate(candidates)]
        )
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", 0]]
        append!(
            relationship_parameter_values, [["unit__to_node", [c, "node_b"], "unit_capacity", 1] for c in candidates]
        )
        append!(
            relationship_parameter_values,
            [["unit__to_node", [c, "node_b"], "vom_cost", 10] for c in candidates]
        )
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        m_mp = master_model(m)
        using_spinedb(url_out, Y)
        @testset for (k, c) in enumerate(candidates)
            @test first(values(Y.units_invested(unit=Y.unit(c)))) == (k <= dem ? 1 : 0)
        end
    end
end

function _test_benders_mp_min_res_gen_to_demand_ratio_cuts()
    @testset "benders_mp_min_res_gen_to_demand_ratio_cuts" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        res = 6
        dem = ucap = 10
        rf = 6
        look_ahead = 3
        vom_cost_ = 2
        vom_cost_alt = vom_cost_ / 2
        op_cost_no_inv = ucap * vom_cost_ * (24 + look_ahead)
        op_cost_inv = ucap * vom_cost_alt * (24 + look_ahead)
        do_not_inv_cost = op_cost_no_inv - op_cost_inv + 1 # minimum cost at which investment is not profitable
        do_inv_cost = do_not_inv_cost - 2  # maximum cost at which investment is profitable
        u_inv_cost = do_not_inv_cost
        @testset for should_invest in (true, false)
            mrg2d_ratio = should_invest ? 0.8 : 0.0
            url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
            objects = [
                ["commodity", "electricity"],
                ["unit", "unit_ab_alt"],
                ["output", "total_costs"],
                ["output", "units_invested"],
                ["output", "units_mothballed"],
                ["output", "units_invested_available"],
                ["output", "mp_min_res_gen_to_demand_ratio_slack"],
                ["output", "value_constraint_mp_min_res_gen_to_demand_ratio_cuts"],
                ["temporal_block", "investments_hourly"],
            ]
            relationships = [
                ["node__commodity", ["node_b", "electricity"]],
                ["unit__to_node", ["unit_ab_alt", "node_b"]],
                ["units_on__temporal_block", ["unit_ab_alt", "hourly"]],
                ["units_on__stochastic_structure", ["unit_ab_alt", "deterministic"]],
                ["model__temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
                ["report__output", ["report_x", "total_costs"]],
                ["report__output", ["report_x", "units_invested"]],
                ["report__output", ["report_x", "units_mothballed"]],
                ["report__output", ["report_x", "units_invested_available"]],
                ["report__output", ["report_x", "mp_min_res_gen_to_demand_ratio_slack"]],
                ["report__output", ["report_x", "value_constraint_mp_min_res_gen_to_demand_ratio_cuts"]],
            ]
            object_parameter_values = [
                ["commodity", "electricity", "mp_min_res_gen_to_demand_ratio", mrg2d_ratio],
                ["commodity", "electricity", "mp_min_res_gen_to_demand_ratio_slack_penalty", 10000],
                ["model", "instance", "roll_forward", unparse_db_value(Hour(rf))],
                ["model", "instance", "model_type", "spineopt_benders"],
                ["model", "instance", "max_iterations", 10],
                ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
                ["node", "node_b", "demand", dem],
                ["unit", "unit_ab_alt", "is_renewable", true],
                ["unit", "unit_ab_alt", "number_of_units", 0],
                ["unit", "unit_ab_alt", "candidate_units", 1],
                ["unit", "unit_ab_alt", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "unit_ab_alt", "online_variable_type", "unit_online_variable_type_integer"],
                ["unit", "unit_ab_alt", "unit_investment_cost", u_inv_cost],
                ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(rf + look_ahead))],
                ["temporal_block", "investments_hourly", "block_end", unparse_db_value(Hour(24 + look_ahead))],
                ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(res))],
                ["temporal_block", "investments_hourly", "resolution", unparse_db_value(Hour(res))],
            ]
            relationship_parameter_values = [
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost_],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "vom_cost", vom_cost_alt],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values
            )
            m = run_spineopt(url_in, url_out; log_level=0)
            m_mp = master_model(m)
            cons = m_mp.ext[:spineopt].constraints[:mp_min_res_gen_to_demand_ratio_cuts]
            invest_vars = m_mp.ext[:spineopt].variables[:units_invested_available]
            slack_vars = m_mp.ext[:spineopt].variables[:mp_min_res_gen_to_demand_ratio_slack]
            @test length(cons) == 1
            observed_con = constraint_object(only(values(cons)))
            expected_con = @build_constraint(
                + ucap * sum(
                    duration(k.t) * v for (k, v) in invest_vars if DateTime(2000) <= start(k.t) < DateTime(2000, 1, 2)
                )
                + only(values(slack_vars))
                >=
                + 24 * dem * mrg2d_ratio
            )
            @test _is_constraint_equal(observed_con, expected_con)
            using_spinedb(url_out, Y)
            @testset "total_cost" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 23)
                    exp_total_costs = if should_invest
                        t == DateTime(2000, 1, 1) ? u_inv_cost + 60 : 60
                    else
                        120
                    end
                    @test Y.total_costs(model=Y.model(:instance), t=t) == exp_total_costs
                end
            end
            @testset "invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested(unit=Y.unit(:unit_ab_alt), t=t) == (
                        should_invest && t == DateTime(2000, 1, 1) ? 1 : 0
                    )
                end
            end
            @testset "mothballed" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_mothballed(unit=Y.unit(:unit_ab_alt), t=t) == 0
                end
            end
            @testset "available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested_available(unit=Y.unit(:unit_ab_alt), t=t) == (should_invest ? 1 : 0)
                end
            end
            t0 = DateTime(2000, 1, 1)
            @test Y.mp_min_res_gen_to_demand_ratio_slack(commodity=Y.commodity(:electricity), t=t0) == 0
            val_con = Y.value_constraint_mp_min_res_gen_to_demand_ratio_cuts(commodity=Y.commodity(:electricity), t=t0)
            @test val_con == (should_invest ? 240 : 0)
        end
    end
end

function _test_benders_starting_units_invested()
    @testset "benders_starting_units_invested" begin
        benders_gap = 1e-6  # needed so that we get the exact master problem solution
        mip_solver_options_benders = unparse_db_value(Map(["HiGHS.jl"], [Map(["mip_rel_gap"], [benders_gap])]))
        res = 6
        dem = ucap = 10
        rf = 6
        look_ahead = 3
        vom_cost_ = 2
        vom_cost_alt = vom_cost_ / 2
        op_cost_no_inv = ucap * vom_cost_ * (24 + look_ahead)
        op_cost_inv = ucap * vom_cost_alt * (24 + look_ahead)
        do_not_inv_cost = op_cost_no_inv - op_cost_inv + 1 # minimum cost at which investment is not profitable
        do_inv_cost = do_not_inv_cost - 2  # maximum cost at which investment is profitable
        u_inv_cost = do_not_inv_cost
        @testset for (max_iters, should_invest) in ((10, false), (1, true))
            url_in, url_out, file_path_out = _test_run_spineopt_benders_setup()
            objects = [
                ["unit", "unit_ab_alt"],
                ["output", "total_costs"],
                ["output", "units_invested"],
                ["output", "units_mothballed"],
                ["output", "units_invested_available"],
                ["output", "unit_investment_costs"],
                ["temporal_block", "investments_hourly"],
            ]
            relationships = [
                ["unit__to_node", ["unit_ab_alt", "node_b"]],
                ["units_on__temporal_block", ["unit_ab_alt", "hourly"]],
                ["units_on__stochastic_structure", ["unit_ab_alt", "deterministic"]],
                ["model__temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_temporal_block", ["instance", "investments_hourly"]],
                ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
                ["report__output", ["report_x", "total_costs"]],
                ["report__output", ["report_x", "units_invested"]],
                ["report__output", ["report_x", "units_mothballed"]],
                ["report__output", ["report_x", "units_invested_available"]],
                ["report__output", ["report_x", "unit_investment_costs"]],
            ]
            object_parameter_values = [
                ["model", "instance", "roll_forward", unparse_db_value(Hour(rf))],
                ["model", "instance", "model_type", "spineopt_benders"],
                ["model", "instance", "max_iterations", max_iters],
                ["model", "instance", "db_mip_solver_options", mip_solver_options_benders],
                ["node", "node_b", "demand", dem],
                ["unit", "unit_ab_alt", "number_of_units", 0],
                ["unit", "unit_ab_alt", "candidate_units", 1],
                ["unit", "unit_ab_alt", "benders_starting_units_invested", 1],
                ["unit", "unit_ab_alt", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "unit_ab_alt", "online_variable_type", "unit_online_variable_type_integer"],
                ["unit", "unit_ab_alt", "unit_investment_cost", u_inv_cost],
                ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(rf + look_ahead))],
                ["temporal_block", "investments_hourly", "block_end", unparse_db_value(Hour(24 + look_ahead))],
                ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(res))],
                ["temporal_block", "investments_hourly", "resolution", unparse_db_value(Hour(res))],
            ]
            relationship_parameter_values = [
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost_],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "unit_capacity", ucap],
                ["unit__to_node", ["unit_ab_alt", "node_b"], "vom_cost", vom_cost_alt],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values
            )
            run_spineopt(url_in, url_out; log_level=0)
            using_spinedb(url_out, Y)
            @testset "total_cost" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 23)
                    exp_total_costs = if should_invest
                        t == DateTime(2000, 1, 1) ? u_inv_cost + 60 : 60
                    else
                        120
                    end
                end
            end
            @testset "unit_investment_costs" begin
                @test Y.objective_unit_investment_costs(model=Y.model(:instance), t=DateTime(2000, 1, 1)) == (
                    should_invest ? u_inv_cost : 0
                )
            end
            @testset "invested" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested(unit=Y.unit(:unit_ab_alt), t=t) == (
                        should_invest && t == DateTime(2000, 1, 1) ? 1 : 0
                    )
                end
            end
            @testset "mothballed" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_mothballed(unit=Y.unit(:unit_ab_alt), t=t) == 0
                end
            end
            @testset "available" begin
                @testset for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2)
                    @test Y.units_invested_available(unit=Y.unit(:unit_ab_alt), t=t) == (should_invest ? 1 : 0)
                end
            end
        end
    end
end

@testset "run_spineopt_benders" begin
    _test_benders_unit()
    _test_benders_storage()
    _test_benders_rolling_representative_periods()
    _test_benders_rolling_representative_periods_yearly_investments_multiple_units()
    _test_benders_mp_min_res_gen_to_demand_ratio_cuts()
    _test_benders_starting_units_invested()
    #FIXME: _test_benders_unit_storage()
end