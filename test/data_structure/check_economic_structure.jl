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

function test_data_example_multiyear_economic_discounting()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "two_year"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "investments_deterministic"],
            ["stochastic_structure", "stochastic"],
            ["unit", "unit_ab"],
            ["unit", "unit_bc"],
            ["unit", "unit_group_abbc"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["node", "node_group_bc"],
            ["connection", "connection_ab"],
            ["connection", "connection_bc"],
            ["connection", "connection_group_abbc"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
            ["output", "units_invested"],
            ["output", "connections_invested"],
            ["output", "storages_invested"],
            ["output", "total_costs"],
            ["output", "unit_salvage_fraction"],
            ["output", "unit_tech_discount_factor"],
            ["output", "unit_conversion_to_discounted_annuities"],
            ["report", "report_a"],
        ],
        :object_groups => [
            ["node", "node_group_bc", "node_b"],
            ["node", "node_group_bc", "node_c"],
            ["connection", "connection_group_abbc", "connection_ab"],
            ["connection", "connection_group_abbc", "connection_bc"],
            ["unit", "unit_group_abbc", "unit_ab"],
            ["unit", "unit_group_abbc", "unit_bc"],
        ],
        :relationships => [
            ["model__default_investment_temporal_block", ["instance", "two_year"]],
            ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["node__temporal_block", ["node_a", "hourly"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__temporal_block", ["node_c", "hourly"]],
            ["node__stochastic_structure", ["node_a", "stochastic"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["node__stochastic_structure", ["node_c", "stochastic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
            ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
            ["units_on__temporal_block", ["unit_ab", "hourly"]],
            ["units_on__temporal_block", ["unit_bc", "hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "stochastic"]],
            ["units_on__stochastic_structure", ["unit_bc", "stochastic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__from_node", ["unit_bc", "node_b"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["unit__to_node", ["unit_bc", "node_c"]],
            ["report__output", ["report_a", "units_invested"]],
            ["report__output", ["report_a", "connections_invested"]],
            ["report__output", ["report_a", "storages_invested"]],
            ["report__output", ["report_a", "total_costs"]],
            ["report__output", ["report_a", "unit_salvage_fraction"]],
            ["report__output", ["report_a", "unit_tech_discount_factor"]],
            ["report__output", ["report_a", "unit_conversion_to_discounted_annuities"]],
            ["report__output", ["report_a", "unit_discounted_duration"]],
            ["report__output", ["report_a", "connection_salvage_fraction"]],
            ["report__output", ["report_a", "connection_tech_discount_factor"]],
            ["report__output", ["report_a", "connection_conversion_to_discounted_annuities"]],
            ["report__output", ["report_a", "connection_discounted_duration"]],            
            ["report__output", ["report_a", "storage_salvage_fraction"]],
            ["report__output", ["report_a", "storage_tech_discount_factor"]],
            ["report__output", ["report_a", "storage_conversion_to_discounted_annuities"]],
            ["report__output", ["report_a", "storage_discounted_duration"]],            
            ["model__report", ["instance", "report_a"]],
            ["unit__node__node", ["unit_ab", "node_a", "node_b"]],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"]],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"]],
            ["connection__node__node", ["connection_ab", "node_b", "node_a"]],
            ["unit__node__node", ["unit_bc", "node_b", "node_c"]],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"]],
            ["unit__node__node", ["unit_bc", "node_c", "node_b"]],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2030-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2032-01-01T00:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_year", "resolution", Dict("type" => "duration", "data" => "2Y")],
            ["temporal_block", "hourly", "block_start", Dict("type" => "date_time", "data" => "2031-01-01T00:00:00")],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ],
            ["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_a", "node_b"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_bc", "node_c", "node_b"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_bc", "node_b", "node_c"], "fix_ratio_out_in_unit_flow", 1.0],
        ],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function test_data_minimal_feasible_example_multiyear_economic_discounting()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "two_year"],
            ["stochastic_structure", "deterministic"],
            ["unit", "unit_ab"],
            ["unit", "unit_ab_only_operation"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["stochastic_scenario", "parent"],
        ],
        :relationships => [
            ["model__default_temporal_block", ["instance", "hourly"]],
            ["model__default_investment_temporal_block", ["instance", "two_year"]],
            ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
            ["node__temporal_block", ["node_a", "hourly"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__stochastic_structure", ["node_a", "deterministic"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2030-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2032-01-01T00:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_year", "resolution", Dict("type" => "duration", "data" => "2Y")],
        ],
        :relationship_parameter_values => [
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
            
        ],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function test_data_no_investment_temporal_block_error_exception()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["stochastic_structure", "realisation"],
            ["unit", "unit_ab"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["stochastic_scenario", "deterministic"],
        ],
        :relationships => [
            ["model__default_investment_stochastic_structure", ["instance", "realisation"]],
            ["model__default_stochastic_structure", ["instance", "deterministic"]],
            ["model__default_temporal_block", ["instance", "hourly"]],
            ["stochastic_structure__stochastic_scenario", ["realisation", "deterministic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2030-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2032-01-01T00:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "hourly", "block_start", Dict("type" => "date_time", "data" => "2031-01-01T00:00:00")],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ],
        ],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function _test_discounted_duration_milestone_years()
    @testset "test discounted duration - using milestone years" begin
        url_in = test_data_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        multiyear_economic_discounting = "milestone_years"
        cost = 1
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
        ]
        relationship_parameter_values = [["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", cost]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; optimize=false, log_level=1)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        u_ts = [ind.t for ind in unit_flow_indices(m; unit=unit(:unit_ab))]
        express = SpineOpt.fuel_costs(m, u_ts[1])
        express = SpineOpt.realize(express)
        @test 1 == coefficient(
            express,
            var_unit_flow[unit(:unit_ab), node(:node_b), direction(:to_node), stochastic_scenario(:parent), u_ts[1]],
        )
        object_parameter_values = [["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting]]
        SpineInterface.import_data(
            url_in;
            object_parameter_values=object_parameter_values,
            relationship_parameter_values=relationship_parameter_values,
        )
        m = run_spineopt(url_in; optimize=false, log_level=1)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        u_ts = [ind.t for ind in unit_flow_indices(m; unit=unit(:unit_ab))]
        key_param = Dict(unit.name => unit(:unit_ab), stochastic_scenario.name => stochastic_scenario(:parent))
        express = SpineOpt.fuel_costs(m, u_ts[1])
        express = SpineOpt.realize(express)
        @test 1.1985925426271964 ≈ SpineOpt.unit_discounted_duration(; key_param..., t=u_ts[1]) rtol = 1e-6
        @test 1.1985925426271964 ≈ coefficient(
            express,
            var_unit_flow[unit(:unit_ab), node(:node_b), direction(:to_node), stochastic_scenario(:parent), u_ts[1]],
        ) rtol = 1e-6
    end
end

function _test_discounted_duration_consecutive_years()
    @testset "test discounted duration - using consecutive years" begin
        url_in = test_data_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        multiyear_economic_discounting = "consecutive_years"
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; optimize=false, log_level=1)
        u_ts = [ind.t for ind in unit_flow_indices(m; unit=unit(:unit_ab))]
        key_param = Dict(unit.name => unit(:unit_ab), stochastic_scenario.name => stochastic_scenario(:parent))
        @test 0.5846792890864373 ≈ SpineOpt.unit_discounted_duration(; key_param..., t=u_ts[1]) rtol = 1e-6
    end
end

function _test_discounted_duration_base()
    @testset "test discounted duration base - intra-year (leap)" begin
        t_start = Dates.DateTime(2020,1,1)
        t_end = t_start + Dates.Month(2)
        ts = SpineInterface.TimeSlice(t_start, t_end)
        active_duration = SpineInterface.duration(ts)
        @test SpineOpt.discounted_duration_base(ts) == active_duration == 1440 
        # 1440: the number of hours in Jan and Feb of a leap year
    end
    @testset "test discounted duration base - intra-year (normal)" begin
        t_start = Dates.DateTime(2021,1,1)
        t_end = t_start + Dates.Month(2)
        ts = SpineInterface.TimeSlice(t_start, t_end)
        active_duration = SpineInterface.duration(ts)
        @test SpineOpt.discounted_duration_base(ts) == active_duration == 1416
        # 1416: the number of hours in Jan and Feb of a normal year
    end
    number_of_years = 5
    @testset "test discounted duration base - multi-year (leap)" begin
        t_start = Dates.DateTime(2020,1,1)
        t_end = t_start + Dates.Year(number_of_years)
        ts = SpineInterface.TimeSlice(t_start, t_end)
        active_duration = SpineInterface.duration(ts)
        average_year_length = active_duration / number_of_years
        @test SpineOpt.discounted_duration_base(ts) == 8784 != active_duration
        @test SpineOpt.discounted_duration_base(ts; _exact=true) == average_year_length != active_duration
    end
    @testset "test discounted duration base - multi-year (normal)" begin
        t_start = Dates.DateTime(2021,1,1)
        t_end = t_start + Dates.Year(number_of_years)
        ts = SpineInterface.TimeSlice(t_start, t_end)
        active_duration = SpineInterface.duration(ts)
        @test SpineOpt.discounted_duration_base(ts) == 8760 != active_duration 
    end
end

function _test_investment_costs__salvage_fraction__capacity_transfer_factor__decommissioning()
    @testset "test investment costs, salvage fraction, capacity transfer factor, decommissioning" begin
        url_in = test_data_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        multiyear_economic_discounting = "consecutive_years"
        candidate_unts = 1
        inv_cost = 2
        decom_cost = 1
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost", inv_cost],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_decommissioning_cost", decom_cost],
            ["unit", "unit_ab", "unit_decommissioning_time", Dict("type" => "duration", "data" => "2Y")],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; optimize=false, log_level=3)
        u_ts = [ind.t for ind in units_invested_available_indices(m; unit=unit(:unit_ab))]
        units_invested = m.ext[:spineopt].variables[:units_invested]
        observed_coe_obj = coefficient(objective_function(m), units_invested[unit(:unit_ab), stochastic_scenario(:parent), u_ts[1]])
        expected_coe_obj = inv_cost
        @test expected_coe_obj == observed_coe_obj
        object_parameter_values = [
            ["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; optimize=false, log_level=3)
        u_ts = [ind.t for ind in units_invested_available_indices(m; unit=unit(:unit_ab))]
        key_param = Dict(unit.name => unit(:unit_ab), stochastic_scenario.name => stochastic_scenario(:parent))
        salvage_frac = 0.370998336
        conv_to_disc_annuities = 0.613913254
        cpt = 0.5
        decom_conv_to_disc_annuities = 0.899122663
        @test conv_to_disc_annuities ≈ SpineOpt.unit_conversion_to_discounted_annuities(; key_param..., t=u_ts[1]) rtol = 1e-6
        @test salvage_frac ≈ SpineOpt.unit_salvage_fraction(; key_param..., t=u_ts[1]) rtol = 1e-6
        @test cpt == SpineOpt.unit_capacity_transfer_factor(; key_param..., vintage_t=start(u_ts[1]), t=start(u_ts[1]))
        @test decom_conv_to_disc_annuities ≈
              SpineOpt.unit_decommissioning_conversion_to_discounted_annuities(; key_param..., t=u_ts[1]) rtol = 1e-6
        units_invested = m.ext[:spineopt].variables[:units_invested]
        observed_coe_obj = coefficient(objective_function(m), units_invested[unit(:unit_ab), stochastic_scenario(:parent), u_ts[1]])
        expected_coe_obj = (1 - salvage_frac) * conv_to_disc_annuities * inv_cost
        @test expected_coe_obj ≈ observed_coe_obj rtol = 1e-6
    end
end

function _test_technological_discount_factor__investment_costs__salvage_fraction()
    @testset "test technological discount factor, investment costs, salvage fraction" begin
        url_in = test_data_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        tech_discnt_rate = 0.85
        multiyear_economic_discounting = "consecutive_years"
        candidate_unts = 1
        inv_cost = 2
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost", inv_cost],
            ["unit", "unit_ab", "unit_discount_rate_technology_specific", tech_discnt_rate],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime", Dict("type" => "duration", "data" => "5Y")],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; optimize=false, log_level=1)
        u_ts = [ind.t for ind in units_invested_available_indices(m; unit=unit(:unit_ab))]
        key_param = Dict(unit.name => unit(:unit_ab), stochastic_scenario.name => stochastic_scenario(:parent))
        tech_fac = 2.189728888
        salvage_frac = 0.370998336
        conv_to_disc_annuities = 0.613913254
        @test salvage_frac ≈ SpineOpt.unit_salvage_fraction(; key_param..., t=u_ts[1]) rtol = 1e-6
        @test tech_fac ≈ SpineOpt.unit_tech_discount_factor(; key_param..., t=u_ts[1]) rtol = 1e-6
        @test conv_to_disc_annuities ≈ SpineOpt.unit_conversion_to_discounted_annuities(; key_param..., t=u_ts[1]) rtol = 1e-6
        units_invested = m.ext[:spineopt].variables[:units_invested]
        observed_coe_obj = coefficient(objective_function(m), units_invested[unit(:unit_ab), stochastic_scenario(:parent), u_ts[1]])
        expected_coe_obj = (1 - salvage_frac) * conv_to_disc_annuities * tech_fac * inv_cost
        @test expected_coe_obj ≈ observed_coe_obj rtol = 1e-6
    end
end

function _test_rolling_error_exception()
    @testset "test rolling error exception" begin
        url_in = test_data_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        tech_discnt_rate = 0.85
        multiyear_economic_discounting = "consecutive_years"
        candidate_unts = 1
        inv_cost = 2
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting],
            ["model", "instance", "roll_forward", Dict("type" =>"duration","data"=>"1D")],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost", inv_cost],
            ["unit", "unit_ab", "unit_discount_rate_technology_specific", tech_discnt_rate],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime", Dict("type" => "duration", "data" => "5Y")],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        @test_throws ErrorException run_spineopt(url_in; optimize=false, log_level=1)
    end
end

function _test_Benders_error_exception()
    @testset "test Benders error exception" begin
        url_in = test_data_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        tech_discnt_rate = 0.85
        multiyear_economic_discounting = "consecutive_years"
        candidate_unts = 1
        inv_cost = 2
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting],
            ["model", "instance", "model_type", "spineopt_benders"],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost", inv_cost],
            ["unit", "unit_ab", "unit_discount_rate_technology_specific", tech_discnt_rate],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime", Dict("type" => "duration", "data" => "5Y")],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        @test_throws ErrorException run_spineopt(url_in; optimize=false, log_level=1)
    end
end

function _test_no_investment_temporal_block_error_exception()
    @testset "test no investment temporal block error exception" begin
        url_in = test_data_no_investment_temporal_block_error_exception()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        tech_discnt_rate = 0.85
        candidate_unts = 1
        inv_cost = 2

        for value in ["consecutive_years", "milestone_years"]
            object_parameter_values = [
                ["model", "instance", "discount_rate", discnt_rate],
                ["model", "instance", "discount_year", discnt_year],
                ["model", "instance", "multiyear_economic_discounting", value],
                ["unit", "unit_ab", "candidate_units", candidate_unts],
                ["unit", "unit_ab", "unit_investment_cost", inv_cost],
                ["unit", "unit_ab", "unit_discount_rate_technology_specific", tech_discnt_rate],
                ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
                ["unit", "unit_ab", "unit_investment_tech_lifetime", Dict("type" => "duration", "data" => "5Y")],
                ["unit", "unit_ab", "unit_investment_econ_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ]
            SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
            @test_throws ErrorException run_spineopt(url_in; optimize=false, log_level=1)
        end
    end
end

function _test_saving_outputs()
    @testset "test saving outputs" begin
        url_in = test_data_minimal_feasible_example_multiyear_economic_discounting()
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        tech_discnt_rate = 0.85
        multiyear_economic_discounting = "consecutive_years"
        candidate_unts = 1
        num_of_units = 0
        inv_cost = 2
        objects = [
            ["unit", "unit_ab_only_operation"],
        ]
        relationships = [
            ["unit__from_node", ["unit_ab_only_operation", "node_a"]],
            ["unit__to_node", ["unit_ab_only_operation", "node_b"]],
        ]
        relationship_parameter_values = [
            ["unit__from_node", ["unit_ab", "node_a"], "vom_cost", 25],
            ["unit__from_node", ["unit_ab_only_operation", "node_a"], "vom_cost", 25],
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", 200],
            ["unit__to_node", ["unit_ab_only_operation", "node_b"], "unit_capacity", 100],
            ["unit__node__node", ["unit_ab_only_operation", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
        ]
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "multiyear_economic_discounting", multiyear_economic_discounting],
            ["node", "node_b", "demand", 100],
            ["node", "node_a", "balance_type_list", "balance_type_none"],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "number_of_units", num_of_units],
            ["unit", "unit_ab", "unit_investment_cost", inv_cost],
            ["unit", "unit_ab", "unit_discount_rate_technology_specific", tech_discnt_rate],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime", Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime", Dict("type" => "duration", "data" => "5Y")],
        ]
        SpineInterface.import_data(url_in; 
            relationships=relationships, 
            relationship_parameter_values=relationship_parameter_values, 
            object_parameter_values=object_parameter_values)
        # Here we need to run the optimization to be able to save the economic parameters
        m = run_spineopt(url_in; optimize=true, log_level=0)
        unit_salvage_fraction = []
        unit_discounted_duration = []
        unit_conversion_to_discounted_annuities = []
        unit_tech_discount_factor = []
        for id in unit()
            u_ts = [ind.t for ind in unit_flow_indices(m; unit=id)]
            key_param = Dict(unit.name => id, stochastic_scenario.name => stochastic_scenario(:parent))
            push!(unit_salvage_fraction, SpineOpt.unit_salvage_fraction(; key_param..., t=u_ts[1]))
            push!(unit_discounted_duration, SpineOpt.unit_discounted_duration(; key_param..., t=u_ts[1]))
            push!(unit_conversion_to_discounted_annuities, SpineOpt.unit_conversion_to_discounted_annuities(; key_param..., t=u_ts[1]))
            push!(unit_tech_discount_factor, SpineOpt.unit_tech_discount_factor(; key_param..., t=u_ts[1]))
        end
        # Ideally we would like to check if saving the results throws an error when the economic parameters do not have default values
        # Without default values, the error happens in _save_outputs!() in run_spineopt_basic.jl
        # But it is not possible to check this directly, so we use an alternative here
        # The following tests check if every unit has a value for each of the economic parameters, i.e., if there are default values
        @test length(unit()) == length(unit_salvage_fraction) 
        @test length(unit()) == length(unit_discounted_duration) 
        @test length(unit()) == length(unit_conversion_to_discounted_annuities) 
        @test length(unit()) == length(unit_tech_discount_factor)       
    end
end

@testset "economic structure" begin
    _test_discounted_duration_milestone_years()
    _test_discounted_duration_consecutive_years()
    _test_discounted_duration_base()
    _test_investment_costs__salvage_fraction__capacity_transfer_factor__decommissioning()
    _test_technological_discount_factor__investment_costs__salvage_fraction()
    _test_rolling_error_exception()
    _test_Benders_error_exception()
    _test_no_investment_temporal_block_error_exception()
    _test_saving_outputs()
end