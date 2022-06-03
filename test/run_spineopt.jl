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

module Y
using SpineInterface
end

@testset "run_spineopt" begin
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["stochastic_structure", "deterministic"],
            ["unit", "unit_ab"],
            ["node", "node_b"],
            ["stochastic_scenario", "parent"],
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
            ["model", "instance", "db_mip_solver", "Cbc.jl"],
            ["model", "instance", "db_lp_solver", "Clp.jl"]
        ],
    )
    @testset "rolling" begin
        _load_test_data(url_in, test_data)
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "1 hour")
        vom_cost_data = [100 * k for k in 0:23]
        vom_cost = Dict("type" => "time_series", "data" => PyVector(vom_cost_data), "index" => index)
        demand_data = [2 * k for k in 0:23]
        demand = Dict("type" => "time_series", "data" => PyVector(demand_data), "index" => index)
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
        con = m.ext[:constraints][:unit_flow_capacity]
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
    @testset "rolling without varying terms" begin
        _load_test_data(url_in, test_data)
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
        con = m.ext[:constraints][:unit_flow_capacity]
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
    @testset "units_on_non_anticipativity_time" begin
        _load_test_data(url_in, test_data)
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
            var = m.ext[:variables][:units_on][ind]
            # Only first three time slices should be fixed
            @test is_fixed(var) == (k in 1:3)
        end
    end
    @testset "unit_flow_non_anticipativity_time" begin
        _load_test_data(url_in, test_data)
        vom_cost = 20
        demand_vals = rand(48)
        demand_inds = collect(DateTime(2000, 1, 1):Hour(1):DateTime(2000, 1, 3))
        demand = TimeSeries(demand_inds, demand_vals, false, false)
        demand_pv = parameter_value(demand)
        unit_capacity = 200
        @testset for nat in 1:6
            non_anticip_time = Dict("type" => "duration", "data" => string(nat, "h"))
            objects = [["output", "units_on"]]
            object_parameter_values = [
                ["node", "node_b", "demand", unparse_db_value(demand)],
                ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
                ["temporal_block", "hourly", "block_end", Dict("type" => "duration", "data" => "16h")],
            ]
            relationships = [["report__output", ["report_x", "units_on"]]]
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
            @testset for (k, t) in enumerate(time_slice(m))
                ind = first(SpineOpt.unit_flow_indices(m; t=t))
                var = m.ext[:variables][:unit_flow][ind]
                # Only first nat time slices should be fixed
                @test is_fixed(var) == (k in 1:nat)
                if k in 1:nat
                    @test fix_value(var) == demand_pv(t=t)
                end
            end
        end
    end
    @testset "don't overwrite results on rolling" begin
        _load_test_data(url_in, test_data)
        vom_cost = 1200
        demand = Dict(
            "type" => "time_series",
            "data" => Dict("2000-01-01T00:00:00" => 50.0, "2000-01-01T12:00:00" => 90.0, "2000-01-03T00:00:00" => 90.0)
        )
        unit_capacity = demand
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
        m = run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        flow_key = (
            report=Y.report(:report_x),
            unit=Y.unit(:unit_ab),
            node=Y.node(:node_b),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:parent),
        )
        analysis_times = DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 2) - Hour(1)
        # For each analysis time we cover a window of ± 12 hours with `t`,
        # and check that only `t`s within the optimisation window have a `unit_flow` value
        @testset for at in analysis_times, t in at - Hour(12):Hour(1):at + Hour(12)
            window_start = max(DateTime(2000, 1, 1), at)
            window_end = min(DateTime(2000, 1, 2), at + Hour(9))
            expected_unit_flow = if window_start <= t < window_end
                (t < DateTime(2000, 1, 1, 12)) ? 50 : 90
            else
                nothing
            end
            @test Y.unit_flow(; flow_key..., analysis_time=at, t=t) == expected_unit_flow
        end
    end
    @testset "unfeasible" begin
        _load_test_data(url_in, test_data)
        demand = 100
        object_parameter_values = [["node", "node_b", "demand", demand]]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand - 1]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        
        m = run_spineopt(url_in, url_out; log_level=0)
        @test termination_status(m) != JuMP.MathOptInterface.OPTIMAL
    end
    @testset "unknown output" begin
        _load_test_data(url_in, test_data)
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
        @test_logs (:warn, "can't find any values for 'unknown_output'") run_spineopt(url_in, url_out; log_level=0)
    end
    @testset "write inputs" begin
        _load_test_data(url_in, test_data)
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
    @testset "write inputs overlapping temporal blocks" begin
        _load_test_data(url_in, test_data)
        demand = Dict("type" => "time_pattern", "data" => Dict("h1-6,h19-24" => 100, "h7-18" => 50))
        objects = [["output", "demand"], ["temporal_block", "8hourly"]]
        relationships = [
            ["model__temporal_block", ["instance", "8hourly"]],
            ["node__temporal_block", ["node_a", "8hourly"]],  # NOTE: 8hourly is associated to the *non*-demand node
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
    @testset "output_resolution for an input" begin
        _load_test_data(url_in, test_data)
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
                upper = out_res * k
                upper > 24 && (upper = 24)
                range = lower:upper
                expected = sum(((7 <= j <= 18) ? 50 : 100) for j in range) / length(range)
                @test Y.demand(; key..., t=t) == expected
            end
        end
    end
    @testset "db_solvers" begin
        _load_test_data(url_in, test_data)
        logLevel = 1.0
        ratioGap = 0.015
        demand = 100
    
        mip_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "Cbc.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "ratioGap" => ratioGap,
                        "logLevel" => logLevel,                        
                    ),
                ),
            ),
        )

        lp_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "Clp.jl" => Dict(
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
        @test get_optimizer_attribute(m, "logLevel") == "1"
        @test get_optimizer_attribute(m, "ratioGap") == "0.015"
    end
    @testset "db_solvers_multi_model" begin
        _load_test_data(url_in, test_data)
        logLevel = 1.0
        ratioGap = 0.015
        logLevel_master = 0.0
        ratioGap_master = 0.016
        demand = 100
    
        mip_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "Cbc.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "ratioGap" => ratioGap,
                        "logLevel" => logLevel,                        
                    ),
                ),
            ),
        )

        lp_solver_options = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "Clp.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "LogLevel" => 1.0,
                    ),
                ),
            ),
        )         

        mip_solver_options_master = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "Cbc.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "ratioGap" => ratioGap_master,
                        "logLevel" => logLevel_master,                        
                    ),
                ),
            ),
        )

        lp_solver_options_master = Dict(
            "type" => "map",
            "index_type" => "str",
            "data" => Dict(
                "Clp.jl" => Dict(
                    "type" => "map",
                    "index_type" => "str",
                    "data" => Dict(
                        "LogLevel" => 0.0,
                    ),
                ),
            ),
        )

        objects = [
            ["model", "master_instance"],
            ["temporal_block", "master_hourly"],
            ["stochastic_structure", "master_deterministic"]            
        ]

        object_parameter_values = [ 
            ["node", "node_b", "demand", demand],                                    
            ["model", "instance", "model_type", "spineopt_standard"],
            ["model", "instance", "db_mip_solver_options", mip_solver_options],
            ["model", "instance", "db_lp_solver_options", lp_solver_options],            
            ["model", "master_instance", "model_type", "spineopt_benders_master"],
            ["model", "master_instance", "db_mip_solver_options", mip_solver_options_master],
            ["model", "master_instance", "db_lp_solver_options", lp_solver_options_master],
            ["model", "master_instance", "db_mip_solver", "Cbc.jl"],
            ["model", "master_instance", "db_lp_solver", "Clp.jl"],
            ["model", "master_instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "master_instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T00:00:00")],
            ["model", "master_instance", "duration_unit", "hour"],
            ["model", "master_instance", "max_gap", 0.05],
            ["model", "master_instance", "max_iterations", 1],
            ["temporal_block", "master_hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["unit", "unit_ab", "candidate_units", 1],
        ]

        relationships = [
            ["model__temporal_block", ["master_instance", "master_hourly"]],
            ["model__stochastic_structure", ["master_instance", "master_deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["master_deterministic", "parent"]],
            ["unit__investment_temporal_block", ["unit_ab", "hourly"]],
            ["unit__investment_temporal_block", ["unit_ab", "master_hourly"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "stochastic"]],
            ["unit__investment_stochastic_structure", ["unit_ab", "master_deterministic"]],            
        ]

        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand]]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        
        (m, mp) = run_spineopt(url_in, url_out; log_level=0, optimize=false)
        @test get_optimizer_attribute(m, "logLevel") == "1"
        @test get_optimizer_attribute(m, "ratioGap") == "0.015"
        @test get_optimizer_attribute(mp, "logLevel") == "0"
        @test get_optimizer_attribute(mp, "ratioGap") == "0.016"
    end
    @testset "fixing variables when rolling" begin
        _load_test_data(url_in, test_data)
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "12 hours")
        demand_data = [10, 20, 30]
        demand = Dict("type" => "time_series", "data" => PyVector(demand_data), "index" => index)
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
        history_end = model_end(model=m.ext[:instance]) - roll_forward(model=m.ext[:instance])
        history_start = history_end - Hour(6)
        var_t_iterator = sort(
            [(var, inds.t) for (var_key, vars) in m.ext[:variables] for (inds, var) in vars],
            by=x -> (name(x[1]), x[2])
        )
        @testset for (var, t) in var_t_iterator
            @test is_fixed(var) == (history_start <= start(t) < history_end)
        end
    end
    @testset "dual values" begin
        _load_test_data(url_in, test_data)
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "12 hours")
        demand_data = [10, 20, 30]
        demand = Dict("type" => "time_series", "data" => PyVector(demand_data), "index" => index)
        unit_capacity = 31
        vom_cost_data = [100, 200, 300]
        vom_cost = Dict("type" => "time_series", "data" => PyVector(vom_cost_data), "index" => index)
        objects = [["output", "constraint_nodal_balance"]]
        relationships = [["report__output", ["report_x", "constraint_nodal_balance"]]]
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
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
    @testset "dual values with two time indices" begin
        _load_test_data(url_in, test_data)
        index = Dict("start" => "2000-01-01T00:00:00", "resolution" => "12 hours")
        demand_data = [10, 20, 30]
        demand = Dict("type" => "time_series", "data" => PyVector(demand_data), "index" => index)
        unit_capacity = 31
        vom_cost_data = [100, 200, 300]
        vom_cost = Dict("type" => "time_series", "data" => PyVector(vom_cost_data), "index" => index)
        objects = [["output", "constraint_node_injection"]]
        relationships = [["report__output", ["report_x", "constraint_node_injection"]]]
        object_parameter_values = [
            ["node", "node_b", "demand", demand],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "12h")],
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
        rm(file_path_out; force=true)
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
