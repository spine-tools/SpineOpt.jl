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

@testset "postprocess_results" begin
    @testset "save_connection_avg_throughflow" begin
        url_in = "sqlite://"
        test_data = Dict(
            :objects => [
                ["model", "instance"],
                ["temporal_block", "hourly"],
                ["stochastic_structure", "stochastic"],
                ["connection", "connection_ab"],
                ["node", "node_a"],
                ["node", "node_b"],
                ["stochastic_scenario", "parent"],
                ["stochastic_scenario", "child"],
                ["commodity", "electricity"],
                ["report", "report_x"],
                ["output", "connection_avg_intact_throughflow"],
            ],
            :relationships => [
                ["connection__from_node", ["connection_ab", "node_a"]],
                ["connection__to_node", ["connection_ab", "node_b"]],
                ["model__temporal_block", ["instance", "hourly"]],
                ["model__stochastic_structure", ["instance", "stochastic"]],
                ["node__temporal_block", ["node_a", "hourly"]],
                ["node__temporal_block", ["node_b", "hourly"]],
                ["node__stochastic_structure", ["node_a", "stochastic"]],
                ["node__stochastic_structure", ["node_b", "stochastic"]],
                ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
                ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
                ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
                ["node__commodity", ["node_a", "electricity"]],
                ["node__commodity", ["node_b", "electricity"]],
                ["report__output", ["report_x", "connection_avg_intact_throughflow"]],
            ],
            :object_parameter_values => [
                ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
                ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
                ["model", "instance", "duration_unit", "hour"],
                ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
                ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"],
                ["connection", "connection_ab", "connection_monitored", true],
                ["connection", "connection_ab", "connection_reactance", 0.1],
                ["connection", "connection_ab", "connection_resistance", 0.9],
                ["commodity", "electricity", "commodity_physics", "commodity_physics_ptdf"],
                ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
                ["node", "node_a", "demand", -100],
                ["node", "node_b", "demand", 100],
                ["output","connection_avg_intact_throughflow", "output_resolution", Dict("type" => "duration", "data" => "2h")],
                ["model", "instance", "db_mip_solver", "Cbc.jl"],
                ["model", "instance", "db_lp_solver", "Clp.jl"],
            ],
            :relationship_parameter_values => [[
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ]],
        )
        _load_test_data(url_in, test_data)
        m = run_spineopt(url_in, "sqlite://"; log_level=0)
        connection_avg_throughflow = m.ext[:spineopt].values[:connection_avg_intact_throughflow]
        @test length(connection_avg_throughflow) == 2
        t1, t2 = time_slice(m; temporal_block=temporal_block(:hourly))
        key = (connection=connection(:connection_ab), node=node(:node_b))
        key1 = (key..., stochastic_scenario=stochastic_scenario(:parent), t=t1)
        key2 = (key..., stochastic_scenario=stochastic_scenario(:child), t=t2)
        @test connection_avg_throughflow[key1] == connection_avg_throughflow[key2] == 100
    end
end
