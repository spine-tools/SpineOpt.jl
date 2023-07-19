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

function _test_run_spineopt_setup()
    url_in = ARGS[1]
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    url_in, url_out, file_path_out
end

function _test_min_down_time()
    @testset "min_down_time" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()

        min_down_time = Dict("type" => "duration", "data" => "3h")
        object_parameter_values = [
            ["unit", "U_ccgt", "min_down_time", min_down_time],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values        
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
        using_spinedb(url_out, Y)

        flow_key = (
            report=Y.report(:report),
            unit=Y.unit(:U_ccgt),
            node=Y.node(:B),
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

        min_up_time = Dict("type" => "duration", "data" => "3h")
        object_parameter_values = [
            ["unit", "U_ccgt", "min_up_time", min_up_time],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values        
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        max_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true],
            ["node", "natural_gas", "max_node_pressure", max_node_pressure],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        min_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true],
            ["node", "natural_gas", "min_node_pressure", min_node_pressure],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        node_state_cap = 400
        object_parameter_values = [
            ["node", "battery", "node_state_cap", node_state_cap],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        node_state_min_battery = 50
        node_state_min_biomass = 496000

        object_parameter_values = [
            ["node", "battery", "node_state_min", node_state_min_battery],
            ["node", "biomass", "node_state_min", node_state_min_biomass],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        imposed_max_voltage_angle_A = 1
        imposed_max_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true],
            ["node", "A", "max_voltage_angle", imposed_max_voltage_angle_A],
            ["node", "B", "has_voltage_angle", true],
            ["node", "B", "max_voltage_angle", imposed_max_voltage_angle_B],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        imposed_min_voltage_angle_A = 1
        imposed_min_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true],
            ["node", "A", "min_voltage_angle", imposed_min_voltage_angle_A],
            ["node", "B", "has_voltage_angle", true],
            ["node", "B", "min_voltage_angle", imposed_min_voltage_angle_B],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        fix_node_pressure = 10.0
        object_parameter_values = [
            ["node", "natural_gas", "has_pressure", true],
            ["node", "natural_gas", "fix_node_pressure", fix_node_pressure],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        fix_node_state_battery = 50
        fix_node_state_biomass = 500000

        object_parameter_values = [
            ["node", "battery", "fix_node_state", fix_node_state_battery],
            ["node", "biomass", "fix_node_state", fix_node_state_biomass],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

function _test_fix_node_voltage_angle()
    @testset "fix_node_voltage_angle" begin
        url_in, url_out, file_path_out = _test_run_spineopt_setup()

        fix_node_voltage_angle_A = 1
        fix_node_voltage_angle_B = 2

        object_parameter_values = [
            ["node", "A", "has_voltage_angle", true],
            ["node", "A", "fix_node_voltage_angle", fix_node_voltage_angle_A],
            ["node", "B", "has_voltage_angle", true],
            ["node", "B", "fix_node_voltage_angle", fix_node_voltage_angle_B],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

        imposed_initial_node_state_battery = 50
        imposed_initial_node_state_biomass = 400000.0

        object_parameter_values = [
            #["node", "battery", "initial_node_state", imposed_initial_node_state_battery],
            ["node", "biomass", "initial_node_state", imposed_initial_node_state_biomass],
        ]

        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values
        )

        rm(file_path_out; force=true)
        run_spineopt(url_in, url_out)
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

@testset "run_spineopt" begin

    #units
    #_test_min_down_time()
    #_test_min_up_time()


    ###nodes
        ##max-min
    #_test_max_node_pressure()
    #_test_min_node_pressure()

    #_test_node_state_cap()
    #_test_node_state_min()

    #_test_min_voltage_angle()
    #_test_max_voltage_angle()

        ##fix
    _test_fix_node_pressure()
    _test_fix_node_state()
    _test_fix_node_state()
    _test_fix_node_voltage_angle()

        ##initial
    #_test_initial_node_state()
end