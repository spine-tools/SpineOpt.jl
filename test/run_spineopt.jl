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

import Logging: Warn

module Y
using SpineInterface
end

function _test_run_spineopt_setup()
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
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
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

function _test_report_relative_optimality_gap()
    @testset "report_relative_optimality_gap" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "1 hour")
        vom_cost_data = [100 * k for k in 1:24]
        vom_cost = Dict("type" => "time_series", "data" => vom_cost_data, "index" => index)
        demand_data = [2 * k for k in 1:24]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => index)
        unit_capacity = demand
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1h")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        objects = [["output", "relative_optimality_gap"]]
        relationships = [["report__output", ["report_x", "relative_optimality_gap"]]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
            relationships=relationships,
            objects=objects
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        @testset for k in 1:24
            t1 = DateTime(2000, 1, 1, k - 1)
            t = TimeSlice(t1, t1 + Hour(1))
            @test Y.relative_optimality_gap(model=first(Y.model()), report=Y.report(:report_x), t=t) !== nothing
        end
    end
end

function _test_rolling()
    @testset "rolling" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "1 hour")
        vom_cost_data = [100 * k for k in 0:23]
        vom_cost = Dict("type" => "time_series", "data" => vom_cost_data, "index" => index)
        demand_data = [2 * k for k in 0:23]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => index)
        unit_capacity = demand
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1h")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        @testset for write_as_roll in (0, 1, 2, 3, 5, 8, 13, 21, 24)
            m = run_spineopt(url_in, url_out; log_level=0, write_as_roll=write_as_roll)
            con = m.ext[:spineopt].constraints[:unit_flow_capacity]
            using_spinedb(url_out, Y)
            cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
            flow_key = (
                report=Y.report(:report_x),
                unit=Y.unit(:unit_ab),
                node=Y.node(:node_b),
                direction=Y.direction(:to_node),
                stochastic_scenario=Y.stochastic_scenario(:parent),
            )
            @testset for (k, (c, d)) in enumerate(zip(vom_cost_data, demand_data))
                t1 = DateTime(2000, 1, 1, k - 1)
                t = TimeSlice(t1, t1 + Hour(1))
                @test Y.objective_variable_om_costs(; cost_key..., t=t) == c * d
                @test Y.unit_flow(; flow_key..., t=t) == d
            end
        end
    end
end

function _test_rolling_with_updating_data()
    @testset "rolling with updating data" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        inds = Dict("start" => "2000-01-01T00:00:00", "resolution" => "1 hour")
        vom_cost_data = [100 * k for k in 0:23]
        ts = Dict(
            "type" => "time_series",
            "data" => vom_cost_data,
            "index" => inds,
        )
        vom_cost = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "parent" => Dict(
                    "type" => "map",
                    "index_type" => "date_time",
                    "data" => Dict(
                        "2000-01-01T00:00:00" => ts,
                        "2000-01-01T12:00:00" => vom_cost_data[12],
                    )
                )
            )
        )
        demand_data = [2 * k for k in 0:23]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => inds)
        unit_capacity = demand
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1h")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        con = m.ext[:spineopt].constraints[:unit_flow_capacity]
        using_spinedb(url_out, Y)
        cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
        flow_key = (
            report=Y.report(:report_x),
            unit=Y.unit(:unit_ab),
            node=Y.node(:node_b),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:parent),
        )
        realized_vom_cost_data = min.(vom_cost_data, vom_cost_data[12])
        @testset for (k, (c, d)) in enumerate(zip(realized_vom_cost_data, demand_data))
            t1 = DateTime(2000, 1, 1, k - 1)
            t = TimeSlice(t1, t1 + Hour(1))
            @test Y.objective_variable_om_costs(; cost_key..., t=t) == c * d
            @test Y.unit_flow(; flow_key..., t=t) == d
        end
    end
end

function _test_rolling_with_unused_dummy_stochastic_data()
    @testset "rolling with unused dummy stochastic data" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        inds = Dict("start" => "2000-01-01T00:00:00", "resolution" => "1 hour")
        vom_cost_data = [100 * k for k in 0:23]
        ts = Dict(
            "type" => "time_series",
            "data" => vom_cost_data,
            "index" => inds,
        )
        vom_cost = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "parent" => ts,
                "unused_forecast" => nothing,
            )
        )
        demand_data = [2 * k for k in 0:23]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => inds)
        unit_capacity = demand
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1h")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        con = m.ext[:spineopt].constraints[:unit_flow_capacity]
        using_spinedb(url_out, Y)
        cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
        flow_key = (
            report=Y.report(:report_x),
            unit=Y.unit(:unit_ab),
            node=Y.node(:node_b),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:parent),
        )
        @testset for (k, (c, d)) in enumerate(zip(vom_cost_data, demand_data))
            t1 = DateTime(2000, 1, 1, k - 1)
            t = TimeSlice(t1, t1 + Hour(1))
            @test Y.objective_variable_om_costs(; cost_key..., t=t) == c * d
            @test Y.unit_flow(; flow_key..., t=t) == d
        end
    end
end

function _test_rolling_without_varying_terms()
    @testset "rolling without varying terms" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "1 hour")
        vom_cost = 1200
        demand = 24
        unit_capacity = demand
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1h")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        con = m.ext[:spineopt].constraints[:unit_flow_capacity]
        using_spinedb(url_out, Y)
        cost_key = (model=Y.model(:instance), report=Y.report(:report_x))
        flow_key = (
            report=Y.report(:report_x),
            unit=Y.unit(:unit_ab),
            node=Y.node(:node_b),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:parent),
        )
        timestamps = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 2))
        @testset for (t0, t1) in zip(timestamps[1:(end - 1)], timestamps[2:end])
            t = TimeSlice(t0, t1)
            @test Y.objective_variable_om_costs(; cost_key..., t=t) == vom_cost * demand
            @test Y.unit_flow(; flow_key..., t=t) == demand
        end
    end
end

function _test_units_on_non_anticipativity_time()
    @testset "units_on_non_anticipativity_time" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        vom_cost = 20
        demand = 200
        unit_capacity = demand
        objects = [["output", "units_on"]]
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
            ["unit", "unit_ab", "units_on_non_anticipativity_time", Dict("type" => "duration", "data" => "3h")],
            ["temporal_block", "hourly", "block_end", Dict("type" => "duration", "data" => "16h")],
        ]
        relationships = [["report__output", ["report_x", "units_on"]]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        @testset for (k, t) in enumerate(time_slice(m))
            ind = first(SpineOpt.units_on_indices(m; t=t))
            var = m.ext[:spineopt].variables[:units_on][ind]
            # Only first three time slices should be fixed
            @test is_fixed(var) == (k in 1:3)
        end
    end
end

function _test_unit_flow_non_anticipativity_time()
    @testset "unit_flow_non_anticipativity_time" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        vom_cost = 20
        demand_vals = rand(48)
        demand_inds = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 3))
        demand = TimeSeries(demand_inds, demand_vals, false, false)
        demand_pv = parameter_value(demand)
        unit_capacity = 200
        @testset for nat in 1:6
            non_anticip_time = Dict("type" => "duration", "data" => string(nat, "h"))
            objects = [["output", "units_on"], ["temporal_block", "quarterly"]]
            object_parameter_values = [
                ["node", "node_b", "demand", unparse_db_value(demand)],
                ["node", "node_b", "node_slack_penalty", 1000],
                ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
                ["temporal_block", "quarterly", "resolution", Dict("type" => "duration", "data" => "15m")],
                ["temporal_block", "quarterly", "block_end", Dict("type" => "duration", "data" => "6h")],
                ["temporal_block", "hourly", "block_start", Dict("type" => "duration", "data" => "6h")],
                ["temporal_block", "hourly", "block_end", Dict("type" => "duration", "data" => "18h")],
            ]
            relationships = [
                ["report__output", ["report_x", "units_on"]],
                ["model__temporal_block", ["instance", "quarterly"]],
                ["node__temporal_block", ["node_b", "quarterly"]],
                ["units_on__temporal_block", ["unit_ab", "quarterly"]]
            ]
            relationship_parameter_values = [
                ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
                ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
                ["unit__to_node", ["unit_ab", "node_b"], "unit_flow_non_anticipativity_time", non_anticip_time],
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
                relationship_parameter_values=relationship_parameter_values,
            )
            m = run_spineopt(url_in, url_out; log_level=0)
            nat = unit_flow_non_anticipativity_time(
                unit=unit(:unit_ab), node=node(:node_b), direction=direction(:to_node)
            )
            window_start = model_start(model=first(model())) + roll_forward(model=first(model()))
            @testset for t in time_slice(m)
                ind = first(SpineOpt.unit_flow_indices(m; t=t))
                var = m.ext[:spineopt].variables[:unit_flow][ind]
                should_be_fixed = start(t) - window_start < nat
                @test is_fixed(var) == should_be_fixed
                if should_be_fixed
                    @test fix_value(var) == demand_pv(t=t)
                end
            end
        end
    end
end

function _test_dont_overwrite_results_on_rolling()
    @testset "don't overwrite results on rolling" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        vom_cost = 1200
        demand = Dict(
            "type" => "time_series",
            "data" => Dict("2000-01-01T00:00:00" => 50.0, "2000-01-01T12:00:00" => 90.0, "2000-01-03T00:00:00" => 90.0)
        )
        unit_capacity = 90
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "6h")],
            ["temporal_block", "hourly", "block_end", Dict("type" => "duration", "data" => "9h")]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
            ["report__output", ["report_x", "unit_flow"], "overwrite_results_on_rolling", false],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
            on_conflict=:replace
        )
        m = run_spineopt(url_in, url_out; log_level=0, update_names=true)
        using_spinedb(url_out, Y)
        flow_key = (
            report=Y.report(:report_x),
            unit=Y.unit(:unit_ab),
            node=Y.node(:node_b),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:parent),
        )
        analysis_times = DateTime(2000, 1, 1):Hour(6):(DateTime(2000, 1, 2) - Hour(1))
        # For each analysis time we cover a window of ± 12 hours with `t`,
        # and check that only `t`s within the optimisation window have a `unit_flow` value
        @testset for at in analysis_times, t in (at - Hour(12)):Hour(1):(at + Hour(12))
            window_start = max(DateTime(2000, 1, 1), at)
            window_end = at + Hour(9)
            obs_unit_flow = Y.unit_flow(; flow_key..., analysis_time=at, t=t)
            if window_start <= t < window_end
                exp_unit_flow = (t < DateTime(2000, 1, 1, 12)) ? 50 : 90
                @test obs_unit_flow == exp_unit_flow
            else
                @test isnan(obs_unit_flow)
            end
        end
    end
end

function _test_unfeasible()
    @testset "unfeasible" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        demand = 100
        object_parameter_values = [["node", "node_b", "demand", demand]]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand - 1]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        @test termination_status(m) != MOI.OPTIMAL
    end
end

function _test_unknown_output()
    @testset "unknown output" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        demand = 100
        vom_cost = 50
        objects = [["output", "unknown_output"]]
        relationships = [["report__output", ["report_x", "unknown_output"]]]
        object_parameter_values = [
            ["node", "node_b", "demand", demand]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        msg = "can't find any values for 'unknown_output'"
        @test_logs min_level=Warn (:warn, msg) run_spineopt(url_in, url_out; log_level=0)
    end
end

function _test_write_inputs()
    @testset "write inputs" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        demand = Dict("type" => "time_pattern", "data" => Dict("h1-6,h19-24" => 100, "h7-18" => 50))
        objects = [["output", "demand"]]
        relationships = [["report__output", ["report_x", "demand"]]]
        object_parameter_values = [["node", "node_b", "demand", demand]]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        key = (report=Y.report(:report_x), node=Y.node(:node_b), stochastic_scenario=Y.stochastic_scenario(:parent))
        @testset for (k, t) in enumerate(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 2) - Hour(1))
            @test Y.demand(; key..., t=t) == ((7 <= k <= 18) ? 50 : 100)
        end
    end
end

function _test_write_inputs_overlapping_temporal_blocks()
    @testset "write inputs overlapping temporal blocks" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        demand = Dict("type" => "time_pattern", "data" => Dict("h1-6,h19-24" => 100, "h7-18" => 50))
        objects = [["output", "demand"], ["temporal_block", "8hourly"], ["node", "node_a"]]
        relationships = [
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["model__temporal_block", ["instance", "8hourly"]],
            ["node__temporal_block", ["node_a", "8hourly"]],  # NOTE: 8hourly is associated to the *non*-demand node
            ["node__stochastic_structure", ["node_a", "deterministic"]],
            ["report__output", ["report_x", "demand"]]
        ]
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["temporal_block", "8hourly", "resolution", Dict("type" => "duration", "data" => "8h")],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        key = (report=Y.report(:report_x), node=Y.node(:node_b), stochastic_scenario=Y.stochastic_scenario(:parent))
        @testset for (k, t) in enumerate(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 2) - Hour(1))
            @test Y.demand(; key..., t=t) == ((7 <= k <= 18) ? 50 : 100)
        end
    end
end

function _test_output_resolution_for_an_input()
    @testset "output_resolution for an input" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        demand = Dict("type" => "time_pattern", "data" => Dict("h1-6,h19-24" => 100, "h7-18" => 50))
        objects = [["output", "demand"]]
        relationships = [["report__output", ["report_x", "demand"]]]
        @testset for out_res in 1:24
            object_parameter_values = [
                ["node", "node_b", "demand", demand],
                ["output", "demand", "output_resolution", Dict("type" => "duration", "data" => "$(out_res)h")]
            ]
            SpineInterface.import_data(
                url_in;
                objects=objects,
                relationships=relationships,
                object_parameter_values=object_parameter_values,
            )
            run_spineopt(url_in, url_out; log_level=0, filters=Dict())
            using_spinedb(url_out, Y)
            key = (report=Y.report(:report_x), node=Y.node(:node_b), stochastic_scenario=Y.stochastic_scenario(:parent))
            @testset for (k, t) in enumerate(DateTime(2000, 1, 1):Hour(out_res):DateTime(2000, 1, 2) - Hour(1))
                lower = out_res * (k - 1) + 1
                upper = min(24, out_res * k)
                range = lower:upper
                expected = sum(((7 <= j <= 18) ? 50 : 100) for j in range) / length(range)
                @test Y.demand(; key..., t=t) == expected
            end
        end
    end
end

function _test_db_solvers()
    @testset "db_solvers" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        output_flag = true
        mip_rel_gap = 0.015
        demand = 100
        mip_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "HiGHS.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "mip_rel_gap" => mip_rel_gap,
                        "output_flag" => output_flag,
                    ),
                ),
            ),
        )
        lp_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "HiGHS.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "LogLevel" => 1.0,
                    ),
                ),
            ),
        )
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "db_mip_solver_options", mip_solver_options],
            ["model", "instance", "db_lp_solver_options", lp_solver_options]
        ]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0, optimize=false)
        @test get_optimizer_attribute(m, "output_flag") == true
        @test get_optimizer_attribute(m, "mip_rel_gap") == 0.015
    end
end

function _test_fixing_variables_when_rolling()
    @testset "fixing variables when rolling" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "12 hours")
        demand_data = [10, 20, 30]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => index)
        unit_capacity = demand
        objects = [["output", "constraint_nodal_balance"]]
        relationships = [["report__output", ["report_x", "constraint_nodal_balance"]]]
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
            ["unit", "unit_ab", "min_up_time", Dict("type" => "duration", "data" => "6h")],
        ]  # NOTE: min_up_time is only so we have a history
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity]
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        SpineOpt.update_model!(m)  # So that history is fixed
        history_end = model_end(model=m.ext[:spineopt].instance) - roll_forward(model=m.ext[:spineopt].instance)
        history_start = history_end - Hour(6)
        var_t_iterator = sort(
            [(var, inds.t) for (var_key, vars) in m.ext[:spineopt].variables for (inds, var) in vars if var isa VariableRef],
            by=x -> (name(x[1]), x[2])
        )         

        @testset for (var, t) in var_t_iterator
            @test is_fixed(var) == (history_start <= start(t) < history_end)
        end
    end
end

function _test_dual_values()
    @testset "dual values" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "12 hours")
        demand_data = [10, 20, 30]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => index)
        unit_capacity = 31
        vom_cost_data = [100, 200, 300]
        vom_cost = Dict("type" => "time_series", "data" => vom_cost_data, "index" => index)
        objects = [["output", "constraint_nodal_balance"]]
        relationships = [["report__output", ["report_x", "constraint_nodal_balance"]]]
        object_parameter_values = [
            # Uncomment to test for a particular solver, e.g., CPLEX
            # ["model", "instance", "db_mip_solver", "CPLEX.jl"],
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
            ["unit", "unit_ab", "online_variable_type", "unit_online_variable_type_binary"]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost]
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        key = (report=Y.report(:report_x), node=Y.node(:node_b), stochastic_scenario=Y.stochastic_scenario(:parent))
        @testset for (k, t) in enumerate(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 2) - Hour(1))
            expected = SpineOpt.vom_cost(node=node(:node_b), unit=unit(:unit_ab), direction=direction(:to_node), t=t)
            @test Y.constraint_nodal_balance(; key..., t=t) == expected
        end
    end
end

function _test_dual_values_with_two_time_indices()
    @testset "dual values with two time indices" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "12 hours")
        demand_data = [10, 20, 30]
        demand = Dict("type" => "time_series", "data" => demand_data, "index" => index)
        unit_capacity = 31
        vom_cost_data = [100, 200, 300]
        vom_cost = Dict("type" => "time_series", "data" => vom_cost_data, "index" => index)
        objects = [["output", "constraint_node_injection"]]
        relationships = [["report__output", ["report_x", "constraint_node_injection"]]]
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
            ["unit", "unit_ab", "online_variable_type", "unit_online_variable_type_binary"]
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost]
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        key = (report=Y.report(:report_x), node=Y.node(:node_b), stochastic_scenario=Y.stochastic_scenario(:parent))
        @testset for (k, t) in enumerate(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 2) - Hour(1))
            expected = if t < DateTime(2000, 1, 2)
                -SpineOpt.vom_cost(node=node(:node_b), unit=unit(:unit_ab), direction=direction(:to_node), t=t)
            else
                nothing
            end
            @test Y.constraint_node_injection(; key..., t=t) == expected
        end
    end
end

function _test_fix_unit_flow_with_rolling()
    @testset "fix_unit_flow with rolling" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        indexes = [
            DateTime("2000-01-01T00:00:00"),
            DateTime("2000-01-01T02:00:00"),
            DateTime("2000-01-01T07:00:00"),
            DateTime("2000-01-01T11:00:00"),
            DateTime("2000-01-01T15:00:00"),
            DateTime("2000-01-01T18:00:00")
        ]
        values = [1, NaN, 2, NaN, 3, NaN]
        fix_unit_flow_ = unparse_db_value(TimeSeries(indexes, values, false, false))
        object_parameter_values = [
            ["node", "node_b", "balance_type", "balance_type_none"],
            ["model", "instance", "roll_forward", unparse_db_value(Hour(6))],
        ]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "fix_unit_flow", fix_unit_flow_]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        @testset for ind in indices(Y.unit_flow)
            @testset for (t, v) in Y.unit_flow(; ind...)
                i = findlast(ind -> t >= ind, indexes)
                exp_v = isnan(values[i]) ? 0 : values[i]
                @test exp_v == v
            end
        end
    end
end

function _test_fix_node_state_using_map_with_rolling()
    @testset "fix_node_state_using_map_with_rolling" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        rf = 2
        look_ahead = 4  # Higher than the roll forward so it's more interesting
        # Note that block end needs to set to Hour(look_ahead + 1) for things to work!
        ucap = 10  # Can be anything
        indexes = collect(DateTime("2000-01-01T00:00:00"):Hour(rf):DateTime("2000-01-01T23:00:00"))
        values = []
        for (k, t0) in enumerate(indexes)
            t = t0 + Hour(look_ahead)
            v = Hour(t - indexes[1]).value * ucap
            val = if k == 1
                TimeSeries([indexes[1], indexes[1] + Hour(1), t], [0, NaN, v])
            else
                TimeSeries([t], [v])
            end
            push!(values, val)
        end
        fix_node_state_ = unparse_db_value(Map(indexes, values))
        objects = [["output", "node_state"]]
        relationships = [["report__output", ["report_x", "node_state"]]]
        object_parameter_values = [
            ["node", "node_b", "has_state", true],
            ["node", "node_b", "fix_node_state", fix_node_state_],
            ["model", "instance", "roll_forward", unparse_db_value(Hour(rf))],
            ["temporal_block", "hourly", "block_end", unparse_db_value(Hour(look_ahead + 1))],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", ucap]
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
        n_state = Y.node_state(; node=Y.node(:node_b))
        @test length(n_state) == 27
        @testset for (t, v) in n_state
            exp_v = Hour(t - indexes[1]).value * ucap
            @test exp_v == v
        end
    end
end

function _test_time_limit()
    Sys.iswindows() && return
    @testset "time_limit" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        mip_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "HiGHS.jl" => Dict("type" => "map", "index_type" => "str", "data" => Dict("time_limit" => eps(Float64)))
            ),
        )
        object_parameter_values = [
            ["model", "instance", "db_mip_solver_options", mip_solver_options],
            ["model", "instance", "roll_forward", unparse_db_value(Hour(6))]
        ]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "vom_cost", 1000]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        windows = [TimeSlice(t, t + Hour(6)) for t in DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 1, 18)]
        msgs = ["no solution available for instance - window $w - moving on..." for w in windows]
        @test_logs(min_level=Warn, ((:warn, msg) for msg in msgs)..., run_spineopt(url_in, url_out; log_level=0))
    end
end

function _test_only_linear_model_has_duals()
    objects = [["output", "bound_units_on"]]
    relationships = [["report__output", ["report_x", "bound_units_on"]]]
    @testset "linear_model_has_duals" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; objects=objects, relationships=relationships)
        m = run_spineopt(url_in, url_out; log_level=0)
        @test has_duals(m)
    end
    object_parameter_values = [
        ["unit", "unit_ab", "online_variable_type", "unit_online_variable_type_binary"]
    ]
    @testset "integer_model_doesnt_have_duals" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        objects = [["output", "bound_units_on"]]
        relationships = [["report__output", ["report_x", "bound_units_on"]]]
        object_parameter_values = [
            ["unit", "unit_ab", "online_variable_type", "unit_online_variable_type_binary"],
            ["unit", "unit_ab", "units_on_cost", 1],  # To have units_on variables
        ]
        SpineInterface.import_data(
            url_in; objects=objects, relationships=relationships, object_parameter_values=object_parameter_values
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        @test !has_duals(m)
    end
end

function _test_add_event_handler()
    @testset "add_event_handler" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        called = false
        m = run_spineopt(url_in, url_out; log_level=0) do m
            add_event_handler!(m, :model_built) do m
                called = true
            end
        end
        @test called
    end
end

@testset "run_spineopt" begin
    _test_rolling()
    _test_rolling_with_updating_data()
    _test_rolling_with_unused_dummy_stochastic_data()
    _test_rolling_without_varying_terms()
    _test_units_on_non_anticipativity_time()
    _test_unit_flow_non_anticipativity_time()
    _test_dont_overwrite_results_on_rolling()
    _test_unfeasible()
    _test_unknown_output()
    _test_write_inputs()
    _test_write_inputs_overlapping_temporal_blocks()
    _test_output_resolution_for_an_input()
    _test_db_solvers()
    _test_fixing_variables_when_rolling()
    _test_dual_values()
    _test_dual_values_with_two_time_indices()
    _test_fix_unit_flow_with_rolling()
    _test_fix_node_state_using_map_with_rolling()
    _test_time_limit()
    _test_only_linear_model_has_duals()
    _test_report_relative_optimality_gap()
    _test_add_event_handler()
end