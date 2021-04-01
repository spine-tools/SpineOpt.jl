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
    url_out = "sqlite:///$(@__DIR__)/test_out.sqlite"
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
        ],
    )
    @testset "rolling" begin
        db_map = _load_test_data(url_in, test_data)
        db_api.create_new_spine_database(url_out)
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
        db_api.import_data(
            db_map;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        db_map.commit_session("Add test data")
        m = run_spineopt(db_map, url_out; log_level=0)
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
        db_map = _load_test_data(url_in, test_data)
        db_api.create_new_spine_database(url_out)
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
        db_api.import_data(
            db_map;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        db_map.commit_session("Add test data")
        m = run_spineopt(db_map, url_out; log_level=0)
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
    @testset "unfeasible" begin
        db_map = _load_test_data(url_in, test_data)
        demand = 100
        object_parameter_values = [["node", "node_b", "demand", demand]]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand - 1]]
        db_api.import_data(
            db_map;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        db_map.commit_session("Add test data")
        m = run_spineopt(db_map, url_out; log_level=0)
        @test termination_status(m) != JuMP.MathOptInterface.OPTIMAL
    end
    @testset "unknown output" begin
        db_map = _load_test_data(url_in, test_data)
        demand = 100
        vom_cost = 50
        objects = [["output", "unknown_output"]]
        relationships = [["report__output", ["report_x", "unknown_output"]]]
        object_parameter_values = [["node", "node_b", "demand", demand]]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", demand],
            ["unit__to_node", ["unit_ab", "node_b"], "vom_cost", vom_cost],
        ]
        db_api.import_data(
            db_map;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        @test_logs (:warn, "can't find a value for 'unknown_output'") run_spineopt(db_map, url_out; log_level=0)
    end
end
