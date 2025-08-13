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

function _test_monte_carlo_setup(mc_scens)
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "flat"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_scenario", "realisation"],
            ["report", "report_x"],
        ],
        :relationships => [
            ["model__default_temporal_block", ["instance", "flat"]],
            ["model__default_stochastic_structure", ["instance", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "realisation"]],
            ["model__report", ["instance", "report_x"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", unparse_db_value(DateTime(2000, 1))],
            ["model", "instance", "model_end", unparse_db_value(DateTime(2000, 2))],
            ["model", "instance", "model_algorithm", "monte_carlo_algorithm"],
            ["temporal_block", "flat", "resolution", unparse_db_value(Hour(1))],
            ["model", "instance", "monte_carlo_scenarios", unparse_db_value(mc_scens)],
        ],
    )
    _load_test_data(url_in, test_data)
    url_in, url_out, file_path_out
end

function _test_monte_carlo()
    @testset "monte_carlo" begin
        pv_availability_factor_ts_2009 = TimeSeries(
            [DateTime(2009, 1, 1), DateTime(2009, 1, 15)], [0.7, 0.8]; ignore_year=true
        )
        wind_availability_factor_ts_2009 = TimeSeries(
            [DateTime(2009, 1, 1), DateTime(2009, 1, 15)], [0.0, 0.0]; ignore_year=true
        )
        pv_availability_factor_ts_2010 = TimeSeries(
            [DateTime(2010, 1, 1), DateTime(2010, 1, 15)], [0.0, 0.0]; ignore_year=true
        )
        wind_availability_factor_ts_2010 = TimeSeries(
            [DateTime(2010, 1, 1), DateTime(2010, 1, 15)], [0.8, 0.9]; ignore_year=true
        )
        ocgt_scheduled_outage_duration_1 = Day(15)
        ccgt_scheduled_outage_duration_1 = Day(8)
        ocgt_scheduled_outage_duration_2 = Day(7)
        ccgt_scheduled_outage_duration_2 = Day(16)
        # mc_scens = Map([:weather_year, :outage_schedule], [["2009", "2010"], ["1", "2"]])
        mc_scens = Map([:weather_year], [["2009", "2010"]])
        pv_af_map = Map(["2009", "2010"], [pv_availability_factor_ts_2009, pv_availability_factor_ts_2010])
        wind_af_map = Map(["2009", "2010"], [wind_availability_factor_ts_2009, wind_availability_factor_ts_2010])
        ocgt_sod_map = Map(["1", "2"], [ocgt_scheduled_outage_duration_1, ocgt_scheduled_outage_duration_2])
        ccgt_sod_map = Map(["1", "2"], [ccgt_scheduled_outage_duration_1, ccgt_scheduled_outage_duration_2])
        url_in, url_out, file_path_out = _test_monte_carlo_setup(mc_scens)
        test_data = Dict(
            :objects => [
                ["unit", "pv"],
                ["unit", "wind"],
                ["unit", "ocgt"],
                ["unit", "ccgt"],
                ["node", "elec"],
                ["node", "fuel"],
                ["output", "unit_flow"],
            ],
            :relationships => [
                ["report__output", ["report_x", "unit_flow"]],
                ["unit__to_node", ["pv", "elec"]],
                ["unit__to_node", ["wind", "elec"]],
                ["unit__to_node", ["ocgt", "elec"]],
                ["unit__to_node", ["ccgt", "elec"]],
                ["unit__from_node", ["ocgt", "fuel"]],
                ["unit__from_node", ["ccgt", "fuel"]],
            ],
            :object_parameter_values => [
                ["node", "elec", "demand", 200],
                ["unit", "pv", "unit_availability_factor", unparse_db_value(pv_af_map)],
                ["unit", "wind", "unit_availability_factor", unparse_db_value(wind_af_map)],
                # ["unit", "ocgt", "scheduled_outage_duration", unparse_db_value(ocgt_sod_map)],
                # ["unit", "ccgt", "scheduled_outage_duration", unparse_db_value(ccgt_sod_map)],
            ],
            :relationship_parameter_values => [
                ["unit__to_node", ["pv", "elec"], "unit_capacity", 200],
                ["unit__to_node", ["wind", "elec"], "unit_capacity", 300],
                ["unit__to_node", ["ocgt", "elec"], "unit_capacity", 150],
                ["unit__to_node", ["ccgt", "elec"], "unit_capacity", 100],
            ],
        )
        import_data(url_in, "Add test data"; test_data...)
        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; log_level=3)
    end
end

function _dict_to_map(dict::Dict)
    Map(collect(keys(dict)), _dict_to_map.(values(dict)))
end
_dict_to_map(x) = x

@testset "run_spineopt_monte_carlo" begin
    _test_monte_carlo()
end