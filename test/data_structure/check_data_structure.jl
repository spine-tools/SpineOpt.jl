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

const url_in = "sqlite://"

@testset "check data structure" begin
    with_connection_open(url_in) do
        _load_test_data(url_in, Dict())
        # TODO: Once we get our error messages right, we should use:
        # @test_throws ErrorException("...exception message...")
        # to make sure that the test passes for the good reasons.
        @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    end
    with_connection_open(url_in) do
        _load_test_data(url_in, Dict())
        SpineInterface.import_data(url_in; objects=[["model", "instance"]])
        @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    end
    with_connection_open(url_in) do
        _load_test_data(url_in, Dict())
        SpineInterface.import_data(
            url_in;
            objects=[["temporal_block", "test_temporal_block"], ["unit", "test_unit"], ["node", "test_node"]],
            relationships=[["model__temporal_block", ["instance", "test_temporal_block"]]],
        )
        @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    end
    with_connection_open(url_in) do
        _load_test_data(url_in, Dict())
        SpineInterface.import_data(
            url_in;
            objects=[["stochastic_structure", "test_stochastic_structure"]],
            relationships=[
                ["node__stochastic_structure", ["test_node", "test_stochastic_structure"]],
                ["model__stochastic_structure", ["instance", "test_stochastic_structure"]],
            ],
        )
        @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    end
end

@testset "data check errors as warnings" begin
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["stochastic_structure", "deterministic"],
            ["unit", "unit_ab"],
            ["node", "node_b"],
            ["stochastic_scenario", "parent"],
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
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
        ],
        :relationship_parameter_values => [
            # ramp_limits_startup (0.9) > minimum_operating_point (0.3) + ramp_limits_up (0.2)
            ["unit__to_node", ["unit_ab", "node_b"], "capacity_per_unit", 100],
            ["unit__to_node", ["unit_ab", "node_b"], "minimum_operating_point", 0.3],
            ["unit__to_node", ["unit_ab", "node_b"], "ramp_limits_up", 0.2],
            ["unit__to_node", ["unit_ab", "node_b"], "ramp_limits_startup", 0.9],
        ],
    )
    with_connection_open(url_in) do
        _load_test_data(url_in, test_data)
        # By default the failed check is an error
        @test_throws ErrorException run_spineopt(url_in; log_level=0, optimize=false)
        # With the switch, it's only a warning, so the model gets built
        m = run_spineopt(url_in; log_level=0, optimize=false, data_check_errors_as_warnings=true)
        @test m isa SpineOpt.JuMP.Model
        # The switch must not leak into later runs
        @test_throws ErrorException run_spineopt(url_in; log_level=0, optimize=false)
    end
end
