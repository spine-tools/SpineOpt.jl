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

function _test_expressions_setup()
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "two_hourly"],
            ["temporal_block", "investments_hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "stochastic"],
            ["stochastic_structure", "investments_deterministic"],
            ["unit", "unit_ab"],
            ["unit", "unit_b"],
            ["unit", "unit_cb"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
        ],
        :relationships => [
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__temporal_block", ["instance", "investments_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["model__stochastic_structure", ["instance", "investments_deterministic"]],
            ["unit__from_node", ["unit_ab", "node_a"]],
            ["unit__from_node", ["unit_cb", "node_c"]],
            ["unit__from_node", ["unit_cb", "node_b"]],
            ["unit__to_node", ["unit_ab", "node_b"]],
            ["unit__to_node", ["unit_b", "node_b"]],
            ["unit__to_node", ["unit_cb", "node_b"]],
            ["unit__to_node", ["unit_cb", "node_c"]],
            ["units_on__temporal_block", ["unit_ab", "two_hourly"]],
            ["units_on__temporal_block", ["unit_b", "hourly"]],
            ["units_on__temporal_block", ["unit_cb", "hourly"]],
            ["units_on__stochastic_structure", ["unit_ab", "deterministic"]],
            ["units_on__stochastic_structure", ["unit_b", "deterministic"]],
            ["units_on__stochastic_structure", ["unit_cb", "deterministic"]],
            ["node__temporal_block", ["node_a", "two_hourly"]],
            ["node__temporal_block", ["node_b", "hourly"]],
            ["node__temporal_block", ["node_c", "hourly"]],            
            ["node__stochastic_structure", ["node_a", "deterministic"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["node__stochastic_structure", ["node_c", "stochastic"]],
            ["node__stochastic_structure", ["node_group_ab", "stochastic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
        ],
        :object_groups => [["node", "node_group_ab", "node_a"], ["node", "node_group_ab", "node_b"]],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["model", "instance", "max_gap", "0.05"],
            ["model", "instance", "max_iterations", "2"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["temporal_block", "investments_hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["node", "node_c", "has_state", true],
            ["node", "node_c", "node_state_cap", 50],
            ["node", "node_b", "demand", 105],
            ["unit", "unit_b", "online_variable_type", "unit_online_variable_type_linear"],
            ["unit", "unit_b", "unit_availability_factor", 0.4],            
            ["model", "instance", "db_mip_solver", "HiGHS.jl"],
            ["model", "instance", "db_lp_solver", "HiGHS.jl"],
        ],
        :relationship_parameter_values => [
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ],
            ["unit__to_node", ["unit_ab", "node_b"], "unit_capacity", 75],
            ["unit__to_node", ["unit_b", "node_b"], "unit_capacity", 30],
            ["unit__to_node", ["unit_cb", "node_b"], "unit_capacity", 10],
        ]
    )
    _load_test_data(url_in, test_data)
    url_in
end

function test_expression_capacity_margin()
    @testset "expression_capacity_margin" begin        
        url_in = _test_expressions_setup()
        number_of_units_b = 3
        margin_b = 1
        demand_b = 105
        group_demand_a = 10
        fractional_demand_b = 0.5
        object_parameter_values = [
            ["node", "node_b", "min_capacity_margin", margin_b],
            ["unit", "unit_b", "number_of_units", number_of_units_b],
            ["node", "node_b", "demand", demand_b],
            ["node", "node_b", "fractional_demand", fractional_demand_b],
            ["node", "node_a", "demand", group_demand_a],
        ]        
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        m = run_spineopt(url_in; log_level=0, optimize=false)
        var_unit_flow = m.ext[:spineopt].variables[:unit_flow]
        var_units_on = m.ext[:spineopt].variables[:units_on]
        
        expression = m.ext[:spineopt].expressions[:capacity_margin]
        @test length(expression) == 2

        # node_b
        n = node(:node_b)
        s_p = stochastic_scenario(:parent)
        s_c = stochastic_scenario(:child)
        scenarios = (s_p, s_c)
        
        time_slices_1h = time_slice(m; temporal_block=temporal_block(:hourly))
        t2 = first(time_slice(m; temporal_block=temporal_block(:two_hourly)))
        @testset for (s, t) in zip(s_p, time_slices_1h)
            unit_b = unit(:unit_b)
            unit_cb = unit(:unit_cb)
            unit_ab = unit(:unit_ab)
            d_f = direction(:from_node)
            d_t = direction(:to_node)
            var_uon_b = get(var_units_on, (unit_b, s, t), 1)
            var_uon_ab = get(var_units_on, (unit_ab, s, t2), 1)
            var_uff_cb = var_unit_flow[unit_cb, n, d_f, s, t]
            var_uft_cb = var_unit_flow[unit_cb, n, d_t, s, t]
     
            expected_expr = @expression(m,
                + var_uft_cb
                - var_uff_cb
                + 0.4 * 30 * var_uon_b
                + 75 * var_uon_ab
                - demand_b
                - fractional_demand_b * group_demand_a
            )            

            observed_expr = expression[n, [s], t]
            
            @test _is_expression_equal(observed_expr, expected_expr)
        end                
    end
end

@testset "expressions" begin    
    test_expression_capacity_margin()
end
