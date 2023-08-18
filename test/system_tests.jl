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

import Logging: Warn

module Y
using SpineInterface
end

using JSON

EPSILON = 0.000001

function _test_run_spineopt_setup()
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    data_from_json = JSON.parsefile("$(@__DIR__)/specialFeaturesDisabled.json")
    test_data = Dict(Symbol(key) => data_from_json[key] for key in keys(data_from_json))
    _load_test_data(url_in, test_data)
    url_in, url_out, file_path_out
end

"""
Some tests are defined below. They do not use the generic function, and are not actually executed: their execution is commented out afterwards. 
They have been kept as examples because they are probably easier to understand than the generic function. 
The version coded with the generic function can be found at the end. 
"""

function _test_min_down_time()
    @testset "min_down_time" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["min_down_time test"])

        min_down_time = Dict("type" => "duration", "data" => "3h")
        object_parameter_values = [
            ["unit", "U_wind", "min_down_time", min_down_time, "min_down_time test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values        
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="min_down_time test")
        using_spinedb(url_out, Y)

        flow_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_wind),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_shut_down = Y.units_shut_down(; flow_key...).values

        shutdowns = []
        i_0 = 0
        in_shutdown = false
        
        for (i, value) in enumerate(unit_shut_down)
            if value == 1
                if !in_shutdown
                    i_0 = i
                    in_shutdown = true
                end
            else
                if in_shutdown
                    push!(shutdowns, (i_0, i-1))
                    in_shutdown = false
                end
            end
        end
        if in_shutdown
            push!(shutdowns, (i_0, length(unit_shut_down)))
        end

        @testset for shutdown_indexes in shutdowns
            @test shutdown_indexes[2]-shutdown_indexes[1] > 3
        end
    end
end

function _test_min_up_time()
    @testset "min_up_time" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["min_up_time test"])

        min_up_time = Dict("type" => "duration", "data" => "3h")
        object_parameter_values = [
            ["unit", "U_ccgt", "min_up_time", min_up_time, "min_up_time test"]
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values        
        )
        
        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="min_up_time test")
        using_spinedb(url_out, Y)

        flow_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_ccgt),
            node=Y.node(:B),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_on = Y.units_on(; flow_key...).values

        on_periods = []
        i_0 = 0
        in_on_period = false
        
        for (i, value) in enumerate(unit_on)
            if value == 1.0
                if !in_on_period
                    i_0 = i
                    in_on_period = true
                end
            else
                if in_on_period
                    push!(on_periods, (i_0, i-1))
                    in_on_period = false
                end
            end
        end
        if in_on_period
            push!(on_periods, (i_0, length(unit_on)))
        end

        @testset for on_periods_indexes in on_periods
            @test on_periods_indexes[2]-on_periods_indexes[1] > 3
        end
    end
end

###node
    ##max-min

function _test_max_node_pressure()
    @testset "max_node_pressure" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["max_node_pressure test"])

        max_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true, "max_node_pressure test"],
            ["node", "natural_gas", "max_node_pressure", max_node_pressure, "max_node_pressure test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="max_node_pressure test")
        using_spinedb(url_out, Y)

        node_key = (
            report=Y.report(:report),
            node=Y.node(:natural_gas),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_pressure = Y.node_pressure(; node_key...).values
        max_pressure = maximum(node_pressure)

        @test max_pressure <= max_node_pressure
    end
end

function _test_min_node_pressure()
    @testset "min_node_pressure" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["min_node_pressure test"])

        min_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true],
            ["node", "natural_gas", "min_node_pressure", min_node_pressure, "min_node_pressure test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="min_node_pressure test")
        using_spinedb(url_out, Y)

        node_key = (
            report=Y.report(:report),
            node=Y.node(:natural_gas),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_pressure = Y.node_pressure(; node_key...).values
        min_pressure = minimum(node_pressure)

        @test min_pressure >= min_node_pressure
    end
end

function _test_node_state_cap()
    @testset "node_state_cap" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["node_state_cap test"])

        node_state_cap = 400
        object_parameter_values = [
            ["node", "battery", "node_state_cap", node_state_cap, "node_state_cap test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="node_state_cap test")
        using_spinedb(url_out, Y)

        node_key = (
            report=Y.report(:report),
            node=Y.node(:battery),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_state = Y.node_state(; node_key...).values
        max_node_state = maximum(node_state)

        @test max_node_state <= node_state_cap
    end
end

function _test_node_state_min()
    @testset "node_state_min" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["node_state_min test"])

        node_state_min_battery = 60
        node_state_min_biomass = 496000

        object_parameter_values = [
            ["node", "battery", "node_state_min", node_state_min_battery, "node_state_min test"],
            ["node", "biomass", "node_state_min", node_state_min_biomass, "node_state_min test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="node_state_min test")
        using_spinedb(url_out, Y)

        node_key_battery = (
            report=Y.report(:report),
            node=Y.node(:battery),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_biomass = (
            report=Y.report(:report),
            node=Y.node(:biomass),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_state_battery = Y.node_state(; node_key_battery...).values
        min_node_state_battery = minimum(node_state_battery)

        node_state_biomass = Y.node_state(; node_key_biomass...).values
        min_node_state_biomass = minimum(node_state_biomass)

        @test min_node_state_battery >= node_state_min_battery
        @test min_node_state_biomass >= node_state_min_biomass
    end
end

function _test_max_voltage_angle()
    @testset "max_voltage_angle" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["max_voltage_angle test"])

        imposed_max_voltage_angle_A = 1
        imposed_max_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true, "max_voltage_angle test"],
            ["node", "A", "max_voltage_angle", imposed_max_voltage_angle_A, "max_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "max_voltage_angle test"],
            ["node", "B", "max_voltage_angle", imposed_max_voltage_angle_B, "max_voltage_angle test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="max_voltage_angle test")
        using_spinedb(url_out, Y)

        node_key_A = (
            report=Y.report(:report),
            node=Y.node(:A),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_B = (
            report=Y.report(:report),
            node=Y.node(:B),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        voltage_angle_A = Y.node_voltage_angle(; node_key_A...).values
        observed_max_voltage_angle_A = maximum(voltage_angle_A)

        voltage_angle_B = Y.node_voltage_angle(; node_key_B...).values
        observed_max_voltage_angle_B = maximum(voltage_angle_B)

        @test observed_max_voltage_angle_A <= imposed_max_voltage_angle_A
        @test observed_max_voltage_angle_B <= imposed_max_voltage_angle_B
    end
end

function _test_min_voltage_angle()
    @testset "min_voltage_angle" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["min_voltage_angle test"])

        imposed_min_voltage_angle_A = 1
        imposed_min_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true, "min_voltage_angle test"],
            ["node", "A", "min_voltage_angle", imposed_min_voltage_angle_A, "min_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "min_voltage_angle test"],
            ["node", "B", "min_voltage_angle", imposed_min_voltage_angle_B, "min_voltage_angle test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="min_voltage_angle test")
        using_spinedb(url_out, Y)

        node_key_A = (
            report=Y.report(:report),
            node=Y.node(:A),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_B = (
            report=Y.report(:report),
            node=Y.node(:B),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        voltage_angle_A = Y.node_voltage_angle(; node_key_A...).values
        observed_min_voltage_angle_A = minimum(voltage_angle_A)

        voltage_angle_B = Y.node_voltage_angle(; node_key_B...).values
        observed_min_voltage_angle_B = minimum(voltage_angle_B)

        @test observed_min_voltage_angle_A >= imposed_min_voltage_angle_A
        @test observed_min_voltage_angle_B >= imposed_min_voltage_angle_B
    end
end

    ##fix

function _test_fix_node_pressure()
    @testset "fix_node_pressure" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["fix_node_pressure test"])

        fix_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true, "fix_node_pressure test"],
            ["node", "natural_gas", "fix_node_pressure", fix_node_pressure, "fix_node_pressure test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="fix_node_pressure test")
        using_spinedb(url_out, Y)

        node_key = (
            report=Y.report(:report),
            node=Y.node(:natural_gas),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_pressure = Y.node_pressure(; node_key...).values
        max_pressure = maximum(node_pressure)
        min_pressure = minimum(node_pressure)

        @test max_pressure <= fix_node_pressure && min_pressure >= fix_node_pressure
    end
end

function _test_fix_node_state()
    @testset "fix_node_state" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["fix_node_state test"])

        fix_node_state_battery = 50
        fix_node_state_biomass = 400000

        object_parameter_values = [
            ["node", "battery", "fix_node_state", fix_node_state_battery, "fix_node_state test"],
            ["node", "biomass", "fix_node_state", fix_node_state_biomass, "fix_node_state test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="fix_node_state test")
        using_spinedb(url_out, Y)

        node_key_battery = (
            report=Y.report(:report),
            node=Y.node(:battery),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_biomass = (
            report=Y.report(:report),
            node=Y.node(:biomass),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_state_battery = Y.node_state(; node_key_battery...).values
        min_node_state_battery = minimum(node_state_battery)
        max_node_state_battery = maximum(node_state_battery)

        node_state_biomass = Y.node_state(; node_key_biomass...).values
        min_node_state_biomass = minimum(node_state_biomass)
        max_node_state_biomass = maximum(node_state_biomass)

        flow_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            node=Y.node(:biomass),
            direction=Y.direction(:from_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_values = Y.unit_flow(; flow_key...).values
        min_flow = minimum(flow_values)
        max_flow = maximum(flow_values)

        @test min_node_state_battery >= fix_node_state_battery && max_node_state_battery <= fix_node_state_battery
        @test min_node_state_biomass >= fix_node_state_biomass && max_node_state_biomass <= fix_node_state_biomass
        @test min_flow >= 0.0 && max_flow <= 0.0
    end
end

using Base

function _test_fix_node_voltage_angle()
    @testset "fix_node_voltage_angle" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["fix_node_voltage_angle test"])

        fix_node_voltage_angle_A = 1
        fix_node_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true,"fix_node_voltage_angle test"],
            ["node", "A", "fix_node_voltage_angle", fix_node_voltage_angle_A, "fix_node_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "fix_node_voltage_angle test"],
            ["node", "B", "fix_node_voltage_angle", fix_node_voltage_angle_B, "fix_node_voltage_angle test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="fix_node_voltage_angle test")
        using_spinedb(url_out, Y)

        node_key_A = (
            report=Y.report(:report),
            node=Y.node(:A),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_B = (
            report=Y.report(:report),
            node=Y.node(:B),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        voltage_angle_A = Y.node_voltage_angle(; node_key_A...).values
        observed_min_voltage_angle_A = minimum(voltage_angle_A)
        observed_max_voltage_angle_A = maximum(voltage_angle_A)

        voltage_angle_B = Y.node_voltage_angle(; node_key_B...).values
        observed_min_voltage_angle_B = minimum(voltage_angle_B)
        observed_max_voltage_angle_B = maximum(voltage_angle_B)

        @test observed_min_voltage_angle_A >= fix_node_voltage_angle_A && observed_max_voltage_angle_A <= fix_node_voltage_angle_A
        @test observed_min_voltage_angle_B >= fix_node_voltage_angle_B && observed_max_voltage_angle_B <= fix_node_voltage_angle_B
    end
end
    
function _test_initial_node_state()
    @testset "initial_node_state" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["initial_node_state test"])

        #imposed_initial_node_state_battery = 50.
        imposed_initial_node_state_biomass = 400000.

        object_parameter_values = [
            #["node", "battery", "initial_node_state", imposed_initial_node_state_battery, "initial_node_state test"],
            ["node", "biomass", "initial_node_state", imposed_initial_node_state_biomass, "initial_node_state test"],
        ]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="initial_node_state test")
        using_spinedb(url_out, Y)

        node_key_battery = (
            report=Y.report(:report),
            node=Y.node(:battery),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_biomass = (
            report=Y.report(:report),
            node=Y.node(:biomass),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        observed_initial_node_state_battery = Y.node_state(; node_key_battery...).values[1]
        observed_initial_node_state_biomass = Y.node_state(; node_key_biomass...).values[1]

        #@test observed_initial_node_state_battery == imposed_initial_node_state_battery
        @test observed_initial_node_state_biomass == imposed_initial_node_state_biomass
    end
end

function _test_initial_node_pressure()
    @testset "initial_node_pressure" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["initial_node_pressure test"])

        imposed_initial_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true, "initial_node_pressure test"],
            ["node", "natural_gas", "initial_node_pressure", imposed_initial_node_pressure, "initial_node_pressure test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="initial_node_pressure test")
        using_spinedb(url_out, Y)

        node_key = (
            report=Y.report(:report),
            node=Y.node(:natural_gas),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        observed_initial_node_pressure = Y.node_pressure(; node_key...).values[1]
        @test observed_initial_node_pressure == imposed_initial_node_pressure
    end
end

function _test_initial_node_voltage_angle()
    @testset "initial_node_voltage_angle" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["initial_node_voltage_angle test"])

        imposed_initial_node_voltage_angle_A = 1
        imposed_initial_node_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true, "initial_node_voltage_angle test"],
            ["node", "A", "initial_node_voltage_angle", imposed_initial_node_voltage_angle_A, "initial_node_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "initial_node_voltage_angle test"],
            ["node", "B", "initial_node_voltage_angle", imposed_initial_node_voltage_angle_B, "initial_node_voltage_angle test"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="initial_node_voltage_angle test")
        using_spinedb(url_out, Y)

        node_key_A = (
            report=Y.report(:report),
            node=Y.node(:A),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        node_key_B = (
            report=Y.report(:report),
            node=Y.node(:B),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        observed_initial_voltage_angle_A = Y.node_voltage_angle(; node_key_A...).values[1]
        observed_initial_voltage_angle_B = Y.node_voltage_angle(; node_key_B...).values[1]

        @test observed_initial_voltage_angle_A == imposed_initial_node_voltage_angle_A
        @test observed_initial_voltage_angle_B == imposed_initial_node_voltage_angle_B
    end
end

function _test_emissions_node_state_cap()
    @testset "emissions using node_state_cap" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["emissions test using node_state_cap"])

        object_parameter_values = [
            ["node", "CO2_emission", "node_state_cap", 0., "emissions test using node_state_cap"],
            ["node", "SO2_emission", "node_state_cap", 0., "emissions test using node_state_cap"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="emissions test using node_state_cap")
        using_spinedb(url_out, Y)

        flow_key_ocgt1 = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt1),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_ocgt2 = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt2),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_ccgt = (
            report=Y.report(:report),
            unit=Y.unit(:U_ccgt),
            node=Y.node(:B),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )


        unit_flow_ocgt1 = Y.unit_flow(; flow_key_ocgt1...).values
        max_unit_flow_ocgt1 = maximum(unit_flow_ocgt1)
        unit_flow_ocgt2 = Y.unit_flow(; flow_key_ocgt2...).values
        max_unit_flow_ocgt2 = maximum(unit_flow_ocgt2)
        unit_flow_ccgt = Y.unit_flow(; flow_key_ccgt...).values
        max_unit_flow_ccgt = maximum(unit_flow_ccgt)

        @test max_unit_flow_ocgt1 == 0.
        @test max_unit_flow_ocgt2 == 0.
        @test max_unit_flow_ccgt == 0.
    end
end

function _test_emissions_node_slack_penalty()
    @testset "emissions using node_slack_penalty" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["emissions test using node_slack_penalty"])

        object_parameter_values = [
            ["node", "CO2_emission", "node_slack_penalty", 10000000., "emissions test using node_slack_penalty"],
            ["node", "SO2_emission", "node_slack_penalty", 10000000., "emissions test using node_slack_penalty"],
        ]

        relationship_parameter_values = [
            ["unit__to_node", "U_ccgt", "B", "vom_cost", 150., "emissions test using node_slack_penalty"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="emissions test using node_slack_penalty")
        using_spinedb(url_out, Y)

        flow_key_ocgt1 = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt1),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_ocgt2 = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt2),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_ccgt = (
            report=Y.report(:report),
            unit=Y.unit(:U_ccgt),
            node=Y.node(:B),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )


        unit_flow_ocgt1 = Y.unit_flow(; flow_key_ocgt1...).values
        max_unit_flow_ocgt1 = maximum(unit_flow_ocgt1)
        unit_flow_ocgt2 = Y.unit_flow(; flow_key_ocgt2...).values
        max_unit_flow_ocgt2 = maximum(unit_flow_ocgt2)
        unit_flow_ccgt = Y.unit_flow(; flow_key_ccgt...).values
        max_unit_flow_ccgt = maximum(unit_flow_ccgt)

        @test max_unit_flow_ocgt1 == 0.
        @test max_unit_flow_ocgt2 == 0.
        @test max_unit_flow_ccgt == 0.
    end
end

function _test_gas_high_node_slack_penalty()
    @testset "gas using high node_slack_penalty" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["gas test using high node_slack_penalty"])

        object_parameter_values = [
            ["node", "gas", "node_slack_penalty", 10000000., "gas test using high node_slack_penalty"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="gas test using high node_slack_penalty")
        using_spinedb(url_out, Y)

        flow_key_ocgt1 = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt1),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_ocgt2 = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt2),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_ccgt = (
            report=Y.report(:report),
            unit=Y.unit(:U_ccgt),
            node=Y.node(:B),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_ocgt1 = Y.unit_flow(; flow_key_ocgt1...).values
        max_unit_flow_ocgt1 = maximum(unit_flow_ocgt1)
        unit_flow_ocgt2 = Y.unit_flow(; flow_key_ocgt2...).values
        max_unit_flow_ocgt2 = maximum(unit_flow_ocgt2)
        unit_flow_ccgt = Y.unit_flow(; flow_key_ccgt...).values
        max_unit_flow_ccgt = maximum(unit_flow_ccgt)

        @test max_unit_flow_ocgt1 == 0.
        @test max_unit_flow_ocgt2 == 0.
        @test max_unit_flow_ccgt == 0.
    end
end

function _test_gas_null_node_slack_penalty()
    @testset "gas using null node_slack_penalty" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["gas test using null node_slack_penalty"])

        object_parameter_values = [
            ["node", "gas", "node_slack_penalty", 0., "gas test using null node_slack_penalty"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="gas test using null node_slack_penalty")
        using_spinedb(url_out, Y)

        flow_key_wind = (
            report=Y.report(:report),
            unit=Y.unit(:U_wind),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_nuclear = (
            report=Y.report(:report),
            unit=Y.unit(:U_nuclear),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_chp = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_wind = Y.unit_flow(; flow_key_wind...).values
        max_unit_flow_wind = maximum(unit_flow_wind)
        unit_flow_nuclear = Y.unit_flow(; flow_key_nuclear...).values
        max_unit_flow_nuclear = maximum(unit_flow_nuclear)
        unit_flow_chp = Y.unit_flow(; flow_key_chp...).values
        max_unit_flow_chp = maximum(unit_flow_chp)

        @test max_unit_flow_wind == 0.
        @test max_unit_flow_nuclear == 0.
        @test max_unit_flow_chp == 0.
    end
end

function _test_biomass_high_node_slack_penalty_no_heat_demand()
    @testset "biomass using high node_slack_penalty without heat_node demand" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["biomass test using high node_slack_penalty without heat_node demand"])

        object_parameter_values = [
            ["node", "biomass", "node_slack_penalty", 1000000., "biomass test using high node_slack_penalty without heat_node demand"],
            ["node", "heat_node", "demand", 0., "biomass test using high node_slack_penalty without heat_node demand"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="biomass test using high node_slack_penalty without heat_node demand")
        using_spinedb(url_out, Y)

        flow_key_chp_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        flow_key_chp_heat = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            node=Y.node(:heat_node),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_chp_A = Y.unit_flow(; flow_key_chp_A...).values
        max_unit_flow_chp_A = maximum(unit_flow_chp_A)
        unit_flow_chp_heat = Y.unit_flow(; flow_key_chp_heat...).values
        max_unit_flow_chp_heat = maximum(unit_flow_chp_heat)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_chp_A == 0.
        @test max_unit_flow_chp_heat == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_nuclear_high_node_slack_penalty()
    @testset "nuclear using high node_slack_penalty" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["nuclear test using high node_slack_penalty"])

        object_parameter_values = [
            ["node", "nuclear", "node_slack_penalty", 1000000., "nuclear test using high node_slack_penalty"],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="nuclear test using high node_slack_penalty")
        using_spinedb(url_out, Y)

        flow_key_nuclear_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_nuclear),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_nuclear),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_nuclear_A = Y.unit_flow(; flow_key_nuclear_A...).values
        max_unit_flow_nuclear_A = maximum(unit_flow_nuclear_A)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_nuclear_A == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_nuclear_unit_high_vom_cost()
    @testset "nuclear unit using high vom_cost" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["nuclear unit using high vom_cost"])

        relationship_parameter_values = [
            ["unit__to_node", "U_nuclear", "A", "vom_cost", 1000000., "nuclear unit using high vom_cost"],
        ]

        SpineInterface.import_data(
            url_in;
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="nuclear unit using high vom_cost")
        using_spinedb(url_out, Y)

        flow_key_nuclear_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_nuclear),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_nuclear),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_nuclear_A = Y.unit_flow(; flow_key_nuclear_A...).values
        max_unit_flow_nuclear_A = maximum(unit_flow_nuclear_A)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_nuclear_A == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_wind_unit_high_vom_cost()
    @testset "wind unit using high vom_cost" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["wind unit using high vom_cost"])

        relationship_parameter_values = [
            ["unit__to_node", "U_wind", "A", "vom_cost", 1000000., "wind unit using high vom_cost"],
        ]

        SpineInterface.import_data(
            url_in;
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="wind unit using high vom_cost")
        using_spinedb(url_out, Y)

        flow_key_wind_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_wind),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_wind),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_wind_A = Y.unit_flow(; flow_key_wind_A...).values
        max_unit_flow_wind_A = maximum(unit_flow_wind_A)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_wind_A == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_chp_unit_high_vom_cost()
    @testset "chp unit using high vom_cost" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["chp unit using high vom_cost"])

        relationship_parameter_values = [
            ["unit__to_node", "U_chp", "A", "vom_cost", 1000000., "chp unit using high vom_cost"],
        ]

        SpineInterface.import_data(
            url_in;
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="chp unit using high vom_cost")
        using_spinedb(url_out, Y)

        flow_key_chp_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_chp_A = Y.unit_flow(; flow_key_chp_A...).values
        max_unit_flow_chp_A = maximum(unit_flow_chp_A)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_chp_A == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_ccgt_unit_high_vom_cost()
    @testset "ccgt unit using high vom_cost" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["ccgt unit using high vom_cost"])

        relationship_parameter_values = [
            ["unit__to_node", "U_ccgt", "B", "vom_cost", 1000000., "ccgt unit using high vom_cost"],
        ]

        SpineInterface.import_data(
            url_in;
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="ccgt unit using high vom_cost")
        using_spinedb(url_out, Y)

        flow_key_ccgt_B = (
            report=Y.report(:report),
            unit=Y.unit(:U_ccgt),
            node=Y.node(:B),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_chp),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_ccgt_B = Y.unit_flow(; flow_key_ccgt_B...).values
        max_unit_flow_ccgt_B = maximum(unit_flow_ccgt_B)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_ccgt_B == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_ocgt1_unit_high_vom_cost()
    @testset "ocgt1 unit using high vom_cost" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["ocgt1 unit using high vom_cost"])

        relationship_parameter_values = [
            ["unit__to_node", "U_ocgt1", "A", "vom_cost", 1000000., "ocgt1 unit using high vom_cost"],
        ]

        SpineInterface.import_data(
            url_in;
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="ocgt1 unit using high vom_cost")
        using_spinedb(url_out, Y)

        flow_key_ocgt1_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt1),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt1),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_ocgt1_A = Y.unit_flow(; flow_key_ocgt1_A...).values
        max_unit_flow_ocgt1_A = maximum(unit_flow_ocgt1_A)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_ocgt1_A == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _test_ocgt2_unit_high_vom_cost()
    @testset "ocgt2 unit using high vom_cost" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()
        SpineInterface.import_data(url_in; :alternatives => ["ocgt2 unit using high vom_cost"])

        relationship_parameter_values = [
            ["unit__to_node", "U_ocgt2", "A", "vom_cost", 1000000., "ocgt2 unit using high vom_cost"],
        ]
        print("\n\n\nrelationship_parameter_values = ",relationship_parameter_values,"\n\n\n")

        SpineInterface.import_data(
            url_in;
            relationship_parameter_values=relationship_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out; alternative="ocgt2 unit using high vom_cost")
        using_spinedb(url_out, Y)

        flow_key_ocgt2_A = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt2),
            node=Y.node(:A),
            direction=Y.direction(:to_node),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_ocgt2),
            stochastic_scenario=Y.stochastic_scenario(:scenario),
        )

        unit_flow_ocgt2_A = Y.unit_flow(; flow_key_ocgt2_A...).values
        max_unit_flow_ocgt2_A = maximum(unit_flow_ocgt2_A)
        unit_on = Y.units_on(; unit_key...).values
        max_unit_on = maximum(unit_on)

        @test max_unit_flow_ocgt2_A == 0.
        @test max_unit_on < 0. + EPSILON
    end
end

function _format_object_inputs(object_inputs,alternative_name)
    entity_class = "object_class"
    entity_name = "object_name"
    entity_inputs_formatted = []
    for (param_name, param_dict) in object_inputs
        push!(entity_inputs_formatted, [param_dict[entity_class], param_dict[entity_name], param_dict["parameter_name"], param_dict["parameter_value"],alternative_name])
    end
    return entity_inputs_formatted
end

function _format_relationship_inputs(relationship_inputs,alternative_name)
    entity_class = "relationship_class"
    entity_name = "relationship_objects"
    entity_inputs_formatted = []
    for (param_name, param_dict) in relationship_inputs
        push!(entity_inputs_formatted, [param_dict[entity_class], param_dict[entity_name], param_dict["parameter_name"], param_dict["parameter_value"],alternative_name])
    end
    print("\n\n\n entity_inputs_formatted = ",entity_inputs_formatted, "\n\n\n")
    return entity_inputs_formatted
end

function generic_test_function(test_name, outputs, tests, object_inputs::Vector, relationship_inputs::Vector)
    url_in, url_out, file_path_out = _test_run_spineopt_setup()
    SpineInterface.import_data(url_in; :alternatives => [test_name])
    
    SpineInterface.import_data(url_in; object_parameter_values=object_inputs)
    SpineInterface.import_data(url_in; relationship_parameter_values=relationship_inputs)

    rm(file_path_out; force=true)
    run_spineopt(url_in, url_out; alternative=test_name)
    using_spinedb(url_out, Y)

    global output_system_test = Dict()
    for (key,value) in outputs;
        report_key_dict = Dict()
        for (param_name,param_value) in value
            if param_name!="parameter_name"
                global param_name_g = param_name
                global param_value_g = param_value
                left_part = eval(Meta.parse(":$param_name_g"))
                right_part = Meta.parse("Y.$param_name_g(:$param_value_g)")
                report_key_dict[left_part] = eval(right_part)
            end
        end
        global report_key_system_test = (; report_key_dict...)
        global used_param_g = value["parameter_name"]
        output_system_test[key] = eval(Meta.parse("Y.$used_param_g(; report_key_system_test...).values"))
    end
    for test in tests
        eval(Meta.parse("@test "*replace(test, "output" => "output_system_test")))
    end
end

function generic_test_function(test_name, outputs, tests, object_inputs::Dict, relationship_inputs)
    object_inputs_formatted = _format_object_inputs(object_inputs, test_name)
    generic_test_function(test_name, outputs, tests, object_inputs_formatted, relationship_inputs)
end

function generic_test_function(test_name, outputs, tests, object_inputs, relationship_inputs::Dict)
    relationship_inputs_formatted = _format_relationship_inputs(relationship_inputs, test_name)
    generic_test_function(test_name, outputs, tests, object_inputs, relationship_inputs_formatted)
end

function generic_test_function(test_name, outputs, tests, object_inputs::Dict, relationship_inputs::Dict)
    object_inputs_formatted = _format_object_inputs(object_inputs, test_name)
    generic_test_function(test_name, outputs, tests, object_inputs_formatted, relationship_inputs)
end

function generic_test_function(test_name, outputs, tests, object_inputs::Nothing, relationship_inputs)
    generic_test_function(test_name, outputs, tests, [], relationship_inputs)
end

function generic_test_function(test_name, outputs, tests, object_inputs::Nothing, relationship_inputs::Dict)
    generic_test_function(test_name, outputs, tests, [], relationship_inputs)
end

function generic_test_function(test_name, outputs, tests, object_inputs, relationship_inputs::Nothing)
    generic_test_function(test_name, outputs, tests, object_inputs, [])
end

function generic_test_function(test_name, outputs, tests, object_inputs::Dict, relationship_inputs::Nothing)
    generic_test_function(test_name, outputs, tests, object_inputs, [])
end

"""@testset "unit_test on 6-unit system" begin
    @testset "unit tests" begin
        @testset "unit parameters" begin
            _test_min_down_time()
            _test_min_up_time()
        end
        
        @testset "node parameters" begin
            _test_max_node_pressure()
            _test_min_node_pressure()

            _test_node_state_cap()
            _test_node_state_min()

            _test_min_voltage_angle()
            _test_max_voltage_angle()

            _test_fix_node_pressure()
            _test_fix_node_state()
            test_fix_node_voltage_angle()

            _test_initial_node_state()
            _test_initial_node_pressure()
            _test_initial_node_voltage_angle()
        end
    end

    @testset "system tests" begin
        @testset "emissions" begin
            _test_emissions_node_state_cap()
            _test_emissions_node_slack_penalty()
        end
        @testset "input nodes" begin
            _test_gas_high_node_slack_penalty()
            _test_gas_null_node_slack_penalty()
            _test_biomass_high_node_slack_penalty_no_heat_demand()
            _test_nuclear_high_node_slack_penalty()
        end
        @testset "units" begin
            
            _test_chp_unit_high_vom_cost()
            _test_ccgt_unit_high_vom_cost()
            _test_ocgt1_unit_high_vom_cost()
            _test_ocgt2_unit_high_vom_cost()
        end
        _test_nuclear_unit_high_vom_cost()
        _test_wind_unit_high_vom_cost()
    end
end"""

tests_data = [
    Dict(
        "test_name" => "min_node_pressure test",
        "object_inputs" => [
            ["node", "natural_gas", "has_pressure", true, "min_node_pressure test"],
            ["node", "natural_gas", "min_node_pressure", 10.0, "min_node_pressure test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "parameter_name" => "node_pressure",
                "report" => "report",
                "node" => "natural_gas",
                "stochastic_scenario" => "scenario"
            )
        ),
        "tests" => [
            "maximum(output[1]) <= 10. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "node_state_cap test",
        "object_inputs" => [
            ["node", "battery", "node_state_cap", 400, "node_state_cap test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "battery",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_state"
            ),
        ),
        "tests" => [
            "maximum(output[1]) <= 400 + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "node_state_min test",
        "object_inputs" => [
            ["node", "battery", "node_state_min", 60, "node_state_min test"],
            ["node", "biomass", "node_state_min", 496000, "node_state_min test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "battery",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_state",
            ),
            2 => Dict(
                "report" => "report",
                "node" => "biomass",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_state",
            ),
        ),        
        "tests" => [
            "minimum(output[1]) >= 60 - EPSILON",
            "minimum(output[2]) >= 496000 - EPSILON",
        ],
    ),

    Dict(
        "test_name" => "max_voltage_angle test",
        "object_inputs" => [
            ["node", "A", "has_voltage_angle", true, "max_voltage_angle test"],
            ["node", "A", "max_voltage_angle", 1, "max_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "max_voltage_angle test"],
            ["node", "B", "max_voltage_angle", 2, "max_voltage_angle test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "A",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            ),
            2 => Dict(
                "report" => "report",
                "node" => "B",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            )
        ),        
        "tests" => [
            "maximum(output[1]) <= 1 + EPSILON",
            "maximum(output[2]) <= 2 + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "min_voltage_angle test",
        "object_inputs" => [
            ["node", "A", "has_voltage_angle", true, "min_voltage_angle test"],
            ["node", "A", "min_voltage_angle", 1, "min_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "min_voltage_angle test"],
            ["node", "B", "min_voltage_angle", 2, "min_voltage_angle test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "A",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            ),
            2 => Dict(
                "report" => "report",
                "node" => "B",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            )
        ),        
        "tests" => [
            "minimum(output[1]) >= 1 - EPSILON",
            "minimum(output[2]) >= 2 - EPSILON",
        ],
    ),

    Dict(
        "test_name" => "fix_node_pressure test",
        "object_inputs" => [
            ["node", "natural_gas", "has_pressure", true, "fix_node_pressure test"],
            ["node", "natural_gas", "fix_node_pressure", 10., "fix_node_pressure test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "natural_gas",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_pressure"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 10. + EPSILON  && minimum(output[1]) >= 10. - EPSILON",
        ],
    ),

    Dict(
        "test_name" => "fix_node_voltage_angle test",
        "object_inputs" => [
            ["node", "A", "has_voltage_angle", true,"fix_node_voltage_angle test"],
            ["node", "A", "fix_node_voltage_angle", 1, "fix_node_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "fix_node_voltage_angle test"],
            ["node", "B", "fix_node_voltage_angle", 2, "fix_node_voltage_angle test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "A",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            ),
            2 => Dict(
                "report" => "report",
                "node" => "B",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            )
        ),        
        "tests" => [
            "minimum(output[1]) >= 1 - EPSILON && maximum(output[1]) <= 1 + EPSILON",
            "minimum(output[2]) >= 2 - EPSILON && maximum(output[2]) <= 2 + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "initial_node_state test",
        "object_inputs" => [
            ["node", "biomass", "initial_node_state", 400000., "initial_node_state test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "biomass",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_state"
            ),
        ),        
        "tests" => [
            "output[1][1] == 400000.",
        ],
    ),

    Dict(
        "test_name" => "initial_node_pressure test",
        "object_inputs" => [
            ["node", "natural_gas", "has_pressure", true, "initial_node_pressure test"],
            ["node", "natural_gas", "initial_node_pressure", 10.0, "initial_node_pressure test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "natural_gas",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_pressure"
            ),
        ),        
        "tests" => [
            "output[1][1] == 10.",
        ],
    ),

    Dict(
        "test_name" => "initial_node_voltage_angle test",
        "object_inputs" => [
            ["node", "A", "has_voltage_angle", true, "initial_node_voltage_angle test"],
            ["node", "A", "initial_node_voltage_angle", 1, "initial_node_voltage_angle test"],
            ["node", "B", "has_voltage_angle", true, "initial_node_voltage_angle test"],
            ["node", "B", "initial_node_voltage_angle", 2, "initial_node_voltage_angle test"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "node" => "A",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            ),
            2 => Dict(
                "report" => "report",
                "node" => "B",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "node_voltage_angle"
            ),
        ),        
        "tests" => [
            "output[1][1] == 1",
            "output[2][1] == 2",
        ],
    ),

    Dict(
        "test_name" => "emissions test using node_state_cap",
        "object_inputs" => [
            ["node", "CO2_emission", "node_state_cap", 0., "emissions test using node_state_cap"],
            ["node", "SO2_emission", "node_state_cap", 0., "emissions test using node_state_cap"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_ocgt1",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_ocgt2",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            3 => Dict(
                "report" => "report",
                "unit" => "U_ccgt",
                "node" => "B",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
            "maximum(output[3]) <= 0. + EPSILON"
        ],
    ),

    Dict(
        "test_name" => "emissions test using node_slack_penalty",
        "object_inputs" => [
            ["node", "CO2_emission", "node_slack_penalty", 10000000., "emissions test using node_slack_penalty"],
            ["node", "SO2_emission", "node_slack_penalty", 10000000., "emissions test using node_slack_penalty"],
        ],
        "relationship_inputs" => [
            ["unit__to_node", "U_ccgt", "B", "vom_cost", 150., "emissions test using node_slack_penalty"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_ocgt1",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_ocgt2",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            3 => Dict(
                "report" => "report",
                "unit" => "U_ccgt",
                "node" => "B",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
            "maximum(output[3]) <= 0. + EPSILON"
        ],
    ),

    Dict(
        "test_name" => "gas test using high node_slack_penalty",
        "object_inputs" => [
            ["node", "gas", "node_slack_penalty", 10000000., "gas test using high node_slack_penalty"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_ocgt1",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_ocgt2",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            3 => Dict(
                "report" => "report",
                "unit" => "U_ccgt",
                "node" => "B",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
            "maximum(output[3]) <= 0. + EPSILON"
        ],
    ),

    Dict(
        "test_name" => "gas test using null node_slack_penalty",
        "object_inputs" => [
            ["node", "gas", "node_slack_penalty", 0., "gas test using null node_slack_penalty"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_wind",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_nuclear",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            3 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
            "maximum(output[3]) <= 0. + EPSILON"
        ],
    ),

    Dict(
        "test_name" => "biomass test using high node_slack_penalty without heat_node demand",
        "object_inputs" => [
            ["node", "biomass", "node_slack_penalty", 1000000., "biomass test using high node_slack_penalty without heat_node demand"],
            ["node", "heat_node", "demand", 0., "biomass test using high node_slack_penalty without heat_node demand"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "node" => "heat_node",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            3 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
            "maximum(output[3]) <= 0. + EPSILON",
        ],
    ),
    
    Dict(
        "test_name" => "nuclear test using high node_slack_penalty",
        "object_inputs" => [
            ["node", "nuclear", "node_slack_penalty", 1000000., "nuclear test using high node_slack_penalty"],
        ],
        "relationship_inputs" => nothing,
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_nuclear",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_nuclear",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "nuclear unit using high vom_cost",
        "object_inputs" => nothing,
        "relationship_inputs" => [
            ["unit__to_node", "U_nuclear", "A", "vom_cost", 1000000., "nuclear unit using high vom_cost"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_nuclear",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_nuclear",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "wind unit using high vom_cost",
        "object_inputs" => nothing,
        "relationship_inputs" => [
            ["unit__to_node", "U_wind", "A", "vom_cost", 1000000., "wind unit using high vom_cost"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_wind",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_wind",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "chp unit using high vom_cost",
        "object_inputs" => nothing,
        "relationship_inputs" => [
            ["unit__to_node", "U_chp", "A", "vom_cost", 1000000., "chp unit using high vom_cost"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "ccgt unit using high vom_cost",
        "object_inputs" => nothing,
        "relationship_inputs" => [
            ["unit__to_node", "U_ccgt", "B", "vom_cost", 1000000., "ccgt unit using high vom_cost"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_ccgt",
                "node" => "B",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_chp",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "ocgt1 unit using high vom_cost",
        "object_inputs" => nothing,
        "relationship_inputs" => [
            ["unit__to_node", "U_ocgt1", "A", "vom_cost", 1000000., "ocgt1 unit using high vom_cost"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_ocgt1",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_ocgt1",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),

    Dict(
        "test_name" => "ocgt2 unit using high vom_cost",
        "object_inputs" => nothing,
        "relationship_inputs" => [
            ["unit__to_node", "U_ocgt2", "A", "vom_cost", 1000000., "ocgt2 unit using high vom_cost"],
        ],
        "outputs" => Dict(
            1 => Dict(
                "report" => "report",
                "unit" => "U_ocgt2",
                "node" => "A",
                "direction" => "to_node",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "unit_flow"
            ),
            2 => Dict(
                "report" => "report",
                "unit" => "U_ocgt2",
                "stochastic_scenario" => "scenario",
                "parameter_name" => "units_on"
            ),
        ),        
        "tests" => [
            "maximum(output[1]) <= 0. + EPSILON",
            "maximum(output[2]) <= 0. + EPSILON",
        ],
    ),
]

for test in tests_data
    generic_test_function(test["test_name"], test["outputs"], test["tests"], test["object_inputs"], test["relationship_inputs"])
    print(test["test_name"]," passed!")
end