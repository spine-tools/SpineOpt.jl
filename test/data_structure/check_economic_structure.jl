#############################################################################
# Copyright (C) 2017 - 2026  Spine and Mopo Project
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


@testset "algorithm structure" begin
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
            ["output","units_invested"],
            ["output","connections_invested"],
            ["output","storages_invested"],
            ["output","total_costs"],
            ["report", "report_a"]
        ],
        :object_groups => [
                ["node", "node_group_bc", "node_b"],
                ["node", "node_group_bc", "node_c"],
                ["connection", "connection_group_abbc", "connection_ab"],
                ["connection", "connection_group_abbc", "connection_bc"],
                ["unit", "unit_group_abbc", "unit_ab"],
                ["unit", "unit_group_abbc", "unit_bc"]
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
            ["report__output",["report_a", "units_invested"]],
            ["report__output",["report_a","connections_invested"]],
            ["report__output",["report_a","storages_invested"]],
            ["report__output",["report_a","total_costs"]],
            ["model__report",["instance","report_a"]],
            ["unit__node__node", ["unit_ab", "node_a", "node_b"]],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"]],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"]],
            ["connection__node__node", ["connection_ab", "node_b", "node_a"]],
            ["unit__node__node", ["unit_bc", "node_b", "node_c"]],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"]],
            ["unit__node__node", ["unit_bc", "node_c", "node_b"]],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"]]
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
                Dict("type" => "duration", "data" => "1h")
            ],
            ["connection__node__node", ["connection_ab", "node_b", "node_a"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_ab", "node_a", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_c", "node_b"], "fix_ratio_out_in_connection_flow", 1.0],
            ["connection__node__node", ["connection_bc", "node_b", "node_c"], "fix_ratio_out_in_connection_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_b", "node_a"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_ab", "node_a", "node_b"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_bc", "node_c", "node_b"], "fix_ratio_out_in_unit_flow", 1.0],
            ["unit__node__node", ["unit_bc", "node_b", "node_c"], "fix_ratio_out_in_unit_flow", 1.0]
        ]
    )
    @testset "test discounted duration - using milestone years, w/o inv. blocks" begin
        _load_test_data(url_in, test_data)
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        use_mlstne_year = true
        candidate_units = 1
        cost = 1
        object_parameter_values = [
            ["model", "instance", "discount_rate",	discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "use_milestone_years", use_mlstne_year],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", cost]
            ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values, relationship_parameter_values=relationship_parameter_values)
        m=run_spineopt(url_in; optimize=false, log_level=1)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow] 
        t0 = SpineOpt._analysis_time(m)
        @testset "test discounted duration" begin
            u_ts = [ind.t for ind in unit_flow_indices(m;unit=unit(:unit_ab))]
            express = SpineOpt.fuel_costs(m,u_ts[1])
            express = SpineOpt.realize(express)
            @test 1.1985925426271964 ≈ coefficient(express,var_unit_flow[unit(:unit_ab), node(:node_b), direction(:to_node), stochastic_scenario(:parent), u_ts[1]]) rtol = 1e-6
         end
    end
    @testset "test discounted duration - w/o using milestone years" begin
        _load_test_data(url_in, test_data)
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        use_mlstne_year = false
        candidate_units = 1
        cost = 1
        object_parameter_values = [
            ["model", "instance", "discount_rate",	discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "use_milestone_years", use_mlstne_year],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", cost]
            ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values, relationship_parameter_values=relationship_parameter_values)
        m=run_spineopt(url_in; optimize=false, log_level=1)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow] 
        t0 = SpineOpt._analysis_time(m)
        @testset "test discounted duration" begin
            u_ts = [ind.t for ind in unit_flow_indices(m;unit=unit(:unit_ab))]
            express = SpineOpt.fuel_costs(m, u_ts[1])
            express = SpineOpt.realize(express)
            @test 0.5846792890864373 ≈ coefficient(express,var_unit_flow[unit(:unit_ab), node(:node_b), direction(:to_node), stochastic_scenario(:parent), u_ts[1]]) rtol = 1e-6
         end
    end
    @testset "test investment costs, salvage fraction, decommissioning" begin
        _load_test_data(url_in, test_data)
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        use_mlstne_year = false
        candidate_unts = 1
        unt_capacity = 1
        cost = 1
        bool_scaling = false
        inv_cost = 1
        object_parameter_values = [
            ["model", "instance", "discount_rate", discnt_rate],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "use_milestone_years", use_mlstne_year],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost",inv_cost],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime" , Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime" , Dict("type" => "duration", "data" => "5Y")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", cost],
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unt_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "use_unit_capacity_for_investment_cost_scaling", bool_scaling],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values, relationship_parameter_values=relationship_parameter_values)
        m=run_spineopt(url_in; optimize=false, log_level=1)
        var_units_inv = m.ext[:spineopt].variables[:units_invested]
        t0 = SpineOpt._analysis_time(m)
        @testset "test investment costs, salvage fraction" begin
            u_ts = [ind.t for ind in units_invested_available_indices(m;unit=unit(:unit_ab))]
            key_param = Dict(unit.name=>unit(:unit_ab), stochastic_scenario.name=>stochastic_scenario(:parent))
            express = SpineOpt.unit_investment_costs(m, u_ts[1])
            express = SpineOpt.realize(express)
            salvage_frac = 0.370998336
            conv_to_disc_annuities = 0.613913254
            @test conv_to_disc_annuities ≈ SpineOpt.unit_conversion_to_discounted_annuities(;key_param...,t=u_ts[1]) rtol = 1e-6  
            @test salvage_frac ≈ SpineOpt.unit_salvage_fraction(;key_param...,t=u_ts[1]) rtol = 1e-6 
            @test conv_to_disc_annuities*(1-salvage_frac) ≈ coefficient(express,var_units_inv[unit(:unit_ab), stochastic_scenario(:parent), u_ts[1]]) rtol = 1e-6 
         end
    end
    @testset "test investment cost scaling" begin
        _load_test_data(url_in, test_data)
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.0
        use_mlstne_year = true
        candidate_unts = 1
        unt_capacity = 100
        bool_scaling = true
        inv_cost = 45
        object_parameter_values = [
            ["model", "instance", "discount_rate",	discnt_rate ],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "use_milestone_years", use_mlstne_year],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost",inv_cost],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime" , Dict("type" => "duration", "data" => "2Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime" , Dict("type" => "duration", "data" => "2Y")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unt_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "use_unit_capacity_for_investment_cost_scaling", bool_scaling],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values, relationship_parameter_values=relationship_parameter_values)
        m=run_spineopt(url_in; optimize=false, log_level=1)
        var_units_inv = m.ext[:spineopt].variables[:units_invested]
        t0 = SpineOpt._analysis_time(m)
        @testset "test investment costs, salvage fraction" begin
            u_ts = [ind.t for ind in units_invested_available_indices(m;unit=unit(:unit_ab))]
            key_param = Dict(unit.name=>unit(:unit_ab), stochastic_scenario.name=>stochastic_scenario(:parent))
            express = SpineOpt.unit_investment_costs(m, u_ts[1])
            express = SpineOpt.realize(express)
            @test unt_capacity*inv_cost == coefficient(express,var_units_inv[unit(:unit_ab), stochastic_scenario(:parent), u_ts[1]])
         end
    end
    
    @testset "test technological discount factor" begin
        _load_test_data(url_in, test_data)
        discnt_year = Dict("type" => "date_time", "data" => "2020-01-01T00:00:00")
        discnt_rate = 0.05
        tech_discnt_rate = 0.85
        use_mlstne_year = false
        candidate_unts = 1
        unt_capacity = 1
        cost = 1
        bool_scaling = false
        inv_cost = 1
        object_parameter_values = [
            ["model", "instance", "discount_rate",	discnt_rate ],
            ["model", "instance", "discount_year", discnt_year],
            ["model", "instance", "use_milestone_years", use_mlstne_year],
            ["unit", "unit_ab", "candidate_units", candidate_unts],
            ["unit", "unit_ab", "unit_investment_cost",inv_cost],
            ["unit", "unit_ab", "unit_discount_rate_technology_specific",tech_discnt_rate],
            ["unit", "unit_ab", "unit_lead_time", Dict("type" => "duration", "data" => "1Y")],
            ["unit", "unit_ab", "unit_investment_tech_lifetime" , Dict("type" => "duration", "data" => "5Y")],
            ["unit", "unit_ab", "unit_investment_econ_lifetime" , Dict("type" => "duration", "data" => "5Y")],
        ]
        relationship_parameter_values = [
            ["unit__to_node", ["unit_ab", "node_b"], "fuel_cost", cost],
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", unt_capacity],
            ["unit__to_node", ["unit_ab", "node_b"], "use_unit_capacity_for_investment_cost_scaling", bool_scaling],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values, relationship_parameter_values=relationship_parameter_values)
        m=run_spineopt(url_in; optimize=false, log_level=1)
        var_units_inv = m.ext[:spineopt].variables[:units_invested]
        t0 = SpineOpt._analysis_time(m)
        @testset "test investment costs, salvage fraction" begin
            u_ts = [ind.t for ind in units_invested_available_indices(m;unit=unit(:unit_ab))]
            key_param = Dict(unit.name=>unit(:unit_ab), stochastic_scenario.name=>stochastic_scenario(:parent))
            express = SpineOpt.unit_investment_costs(m, u_ts[1])
            express = SpineOpt.realize(express)
            @show express
            tech_fac = 2.189728888
            salvage_frac = 0.370998336
            conv_to_disc_annuities = 0.613913254
            @test salvage_frac ≈ SpineOpt.unit_salvage_fraction(;key_param...,t=u_ts[1]) rtol = 1e-6 
            @test tech_fac ≈ SpineOpt.unit_tech_discount_factor(;key_param...,t=u_ts[1]) rtol = 1e-6 
            @test conv_to_disc_annuities ≈ SpineOpt.unit_conversion_to_discounted_annuities(;key_param...,t=u_ts[1]) rtol = 1e-6 
            @test conv_to_disc_annuities*tech_fac*(1-salvage_frac) ≈ coefficient(express,var_units_inv[unit(:unit_ab), stochastic_scenario(:parent), u_ts[1]]) rtol = 1e-6 
         end
    end
end
