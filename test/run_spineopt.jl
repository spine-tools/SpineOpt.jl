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

@testset "run_spineopt simple rolling" begin
    url_in = "sqlite:///$(@__DIR__)/test.sqlite"
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
            ["output", "unit_flow"]
        ],
        :relationships => [
            ["units_on_resolution", ["unit_ab", "node_b"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["report__output", ["report_x", "unit_flow"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T00:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["node", "node_b", "demand", 100],
        ],
    )
    @testset "fixed_om_costs" begin
        _load_template(url_in)
        db_api.import_data_to_url(url_in; test_data...)
        db_api.create_new_spine_database(url_out)
        unit_capacity = 100
        fom_cost = 125
        object_parameter_values = [["unit", "unit_ab", "fom_cost", fom_cost]]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unit_capacity]]
        db_api.import_data_to_url(
            url_in; 
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )
        m = run_spineopt(url_in, url_out; log_level=0)
        using_spinedb(url_out, Y)
        key = (
            report=Y.report(:report_x), 
            unit=Y.unit(:unit_ab), 
            node=Y.node(:node_b), 
            direction=Y.direction(:to_node), 
            stochastic_scenario=Y.stochastic_scenario(:parent)
        )
        @testset for h in 0:23
            t1 = DateTime(2000, 1, 1, h)
            t = TimeSlice(t1, t1 + Hour(1))
            @test Y.unit_flow(; key..., t=t) == unit_capacity
        end
    end
end