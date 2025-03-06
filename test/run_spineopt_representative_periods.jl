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

function _vals_from_data(data)
    Dict{Any,Any}(
        (cls, ent, param) => val isa Tuple ? parse_db_value(val...) : val
        for key in (:object_parameter_values, :relationship_parameter_values)
        for (cls, ent, param, val) in get(data, key, ())
    )
end

function _test_representative_periods_setup()
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    repr_periods_mapping = Map(
        collect(DateTime(2000, 1, 1):Day(1):DateTime(2000, 1, 10)), [[0.1k, 1.0 - 0.1k] for k in 1:10]
    )
    rp1_start = DateTime(2000, 1, 3)
    rp2_start = DateTime(2000, 1, 7)
    repr_periods_mapping[rp1_start] = [1, 0]
    repr_periods_mapping[rp2_start] = [0, 1]
    base_res = Day(1)
    test_data = Dict(
        :objects => [
            ["model", "instance"],
            ["temporal_block", "operations"],
            ["temporal_block", "investments"],
            ["temporal_block", "rp1"],
            ["temporal_block", "rp2"],
            ["temporal_block", "all_rps"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_scenario", "realisation"],
            ["report", "report_x"],
            ["node", "elec_node"],
        ],
        :object_groups => [
            ["temporal_block", "all_rps", "rp1"],
            ["temporal_block", "all_rps", "rp2"],
        ],
        :relationships => [
            ["model__default_temporal_block", ["instance", "operations"]],
            ["model__default_temporal_block", ["instance", "all_rps"]],
            ["model__default_stochastic_structure", ["instance", "deterministic"]],
            ["model__default_investment_temporal_block", ["instance", "investments"]],
            ["model__default_investment_stochastic_structure", ["instance", "deterministic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "realisation"]],
            ["model__report", ["instance", "report_x"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", unparse_db_value(DateTime(2000, 1, 1))],
            ["model", "instance", "model_end", unparse_db_value(DateTime(2000, 1, 11))],
            ["temporal_block", "operations", "resolution", unparse_db_value(base_res)],
            ["temporal_block", "investments", "resolution", unparse_db_value(Year(1))],
            ["temporal_block", "rp1", "resolution", unparse_db_value(base_res)],
            ["temporal_block", "rp1", "block_start", unparse_db_value(rp1_start)],
            ["temporal_block", "rp1", "block_end", unparse_db_value(rp1_start + Day(1))],
            ["temporal_block", "rp1", "weight", 5],
            ["temporal_block", "rp1", "representative_period_index", 1],
            ["temporal_block", "rp2", "resolution", unparse_db_value(base_res)],
            ["temporal_block", "rp2", "block_start", unparse_db_value(rp2_start)],
            ["temporal_block", "rp2", "block_end", unparse_db_value(rp2_start + Day(1))],
            ["temporal_block", "rp2", "weight", 5],
            ["temporal_block", "rp2", "representative_period_index", 2],
            ["temporal_block", "operations", "representative_periods_mapping", unparse_db_value(repr_periods_mapping)],
        ],
    )
    _load_test_data(url_in, test_data)
    vals = _vals_from_data(test_data)
    url_in, url_out, file_path_out, vals
end

function _test_representative_periods()
    @testset "representative_periods" begin
        url_in, url_out, file_path_out, vals = _test_representative_periods_setup()
        elec_demand_inds = collect(DateTime(2000, 1, 1):Hour(6):DateTime(2000, 1, 11))
        elec_demand_length = length(elec_demand_inds)
        elec_demand_ts = TimeSeries(
            elec_demand_inds, [100 + 20 * sin(pi * k / elec_demand_length) for k in 1:elec_demand_length]
        )
        pv_af_ts = TimeSeries(
            elec_demand_inds, [100 + 20 * sin(pi * k / elec_demand_length) for k in 1:elec_demand_length]
        )
        wind_af_ts = TimeSeries(
            elec_demand_inds, [100 + 20 * sin(pi * k / elec_demand_length) for k in 1:elec_demand_length]
        )
        test_data = Dict(
            :objects => [
                ["node", "elec_node"],
                ["node", "batt_node"],
                ["node", "h2_node"],
                ["unit", "batt_unit"],
                ["unit", "electrolizer"],
                ["unit", "h2_gen"],
                ["unit", "pv"],
                ["unit", "wind"],
                ["unit", "conventional"],
            ],
            :relationships => [
                ["unit__from_node", ["batt_unit", "batt_node"]],
                ["unit__from_node", ["batt_unit", "elec_node"]],
                ["unit__to_node", ["batt_unit", "batt_node"]],
                ["unit__to_node", ["batt_unit", "elec_node"]],
                ["unit__node__node", ["batt_unit", "batt_node", "elec_node"]],
                ["unit__node__node", ["batt_unit", "elec_node", "batt_node"]],
                ["unit__from_node", ["electrolizer", "elec_node"]],
                ["unit__to_node", ["electrolizer", "h2_node"]],
                ["unit__node__node", ["electrolizer", "elec_node", "h2_node"]],
                ["unit__from_node", ["h2_gen", "h2_node"]],
                ["unit__to_node", ["h2_gen", "elec_node"]],
                ["unit__node__node", ["h2_gen", "h2_node", "elec_node"]],
                ["unit__to_node", ["pv", "elec_node"]],
                ["unit__to_node", ["wind", "elec_node"]],
                ["unit__to_node", ["conventional", "elec_node"]],
                ["node__temporal_block", ["h2_node", "operations"]],
                ["node__temporal_block", ["h2_node", "all_rps"]],
            ],
            :object_parameter_values => [
                ["node", "elec_node", "demand", unparse_db_value(elec_demand_ts)],
                ["node", "batt_node", "candidate_storages", 100],
                ["node", "batt_node", "has_state", true],
                ["node", "batt_node", "initial_node_state", 0],
                ["node", "batt_node", "node_slack_penalty", 10000],
                ["node", "batt_node", "node_state_cap", 200],
                ["node", "batt_node", "number_of_storages", 0],
                ["node", "batt_node", "storage_investment_cost", 2000000],
                ["node", "batt_node", "storage_investment_variable_type", "storage_investment_variable_type_integer"],
                ["node", "h2_node", "has_state", true],
                ["node", "h2_node", "is_longterm_storage", true],
                ["node", "h2_node", "node_slack_penalty", 10000],
                ["node", "h2_node", "node_state_cap", 20000],
                ["node", "h2_node", "number_of_storages", 100],
                ["unit", "batt_unit", "candidate_units", 100],
                ["unit", "batt_unit", "number_of_units", 0],
                ["unit", "batt_unit", "unit_investment_cost", 750000],
                ["unit", "batt_unit", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "electrolizer", "candidate_units", 100],
                ["unit", "electrolizer", "number_of_units", 0],
                ["unit", "electrolizer", "unit_investment_cost", 40000000],
                ["unit", "electrolizer", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "h2_gen", "candidate_units", 100],
                ["unit", "h2_gen", "number_of_units", 0],
                ["unit", "h2_gen", "online_variable_type", "unit_online_variable_type_integer"],
                ["unit", "h2_gen", "start_up_cost", 1000],
                ["unit", "h2_gen", "min_up_time", Dict("type" => "duration", "data" => string(60, "m"))],
                ["unit", "h2_gen", "min_down_time", Dict("type" => "duration", "data" => string(60, "m"))],
                ["unit", "h2_gen", "unit_investment_cost", 3000000],
                ["unit", "h2_gen", "unit_investment_variable_type", "unit_investment_variable_type_integer"],
                ["unit", "pv", "candidate_units", 100],
                ["unit", "pv", "number_of_units", 0],
                ["unit", "pv", "unit_availability_factor", unparse_db_value(pv_af_ts)],
                ["unit", "pv", "unit_investment_cost", 9000000],
                ["unit", "pv", "unit_investment_variable_type", "unit_investment_variable_type_continuous"],
                ["unit", "wind", "candidate_units", 100],
                ["unit", "wind", "number_of_units", 0],
                ["unit", "wind", "unit_availability_factor", unparse_db_value(wind_af_ts)],
                ["unit", "wind", "unit_investment_cost", 18000000],
                ["unit", "wind", "unit_investment_variable_type", "unit_investment_variable_type_continuous"],
            ],
            :relationship_parameter_values => [
                ["unit__from_node", ["batt_unit", "elec_node"], "unit_capacity", 50],
                ["unit__to_node", ["batt_unit", "elec_node"], "unit_capacity", 55],
                ["unit__node__node", ["batt_unit", "batt_node", "elec_node"], "fix_ratio_out_in_unit_flow", 0.9],
                ["unit__node__node", ["batt_unit", "elec_node", "batt_node"], "fix_ratio_out_in_unit_flow", 0.8],
                ["unit__from_node", ["electrolizer", "elec_node"], "unit_capacity", 1000],
                ["unit__node__node", ["electrolizer", "elec_node", "h2_node"], "fix_ratio_in_out_unit_flow", 1.5],
                ["unit__to_node", ["h2_gen", "elec_node"], "unit_capacity", 100],
                ["unit__node__node", ["h2_gen", "h2_node", "elec_node"], "fix_ratio_in_out_unit_flow", 1.6],
                ["unit__to_node", ["pv", "elec_node"], "unit_capacity", 300],
                ["unit__to_node", ["wind", "elec_node"], "unit_capacity", 300],
                ["unit__to_node", ["conventional", "elec_node"], "unit_capacity", 100],
                ["unit__to_node", ["conventional", "elec_node"], "vom_cost", 500],
                ["node__temporal_block", ["h2_node", "operations"], "cyclic_condition", true],
                ["node__temporal_block", ["h2_node", "operations"], "cyclic_condition_sense", "=="],
            ],
        )
        count, errors = import_data(url_in, "Add test data"; test_data...)
        @test isempty(errors)
        merge!(vals, _vals_from_data(test_data))
        rm(file_path_out; force=true)
        m = run_spineopt(url_in, url_out; optimize=true, log_level=3)
        rt1 = TimeSlice(DateTime(2000, 1, 3), DateTime(2000, 1, 4), temporal_block(:operations), temporal_block(:rp1))
        rt2 = TimeSlice(DateTime(2000, 1, 7), DateTime(2000, 1, 8), temporal_block(:operations), temporal_block(:rp2))
        all_rt = [rt1, rt2]
        t_invest = only(time_slice(m; temporal_block=temporal_block(:investments)))
        @testset for con_name in keys(m.ext[:spineopt].constraints)
            cons = m.ext[:spineopt].constraints[con_name]
            @testset for ind in keys(cons)
                con = cons[ind]
                _test_representative_periods_constraint(m, con_name, ind, con, vals, rt1, rt2, all_rt, t_invest)
            end
        end
        @testset for var_name in keys(m.ext[:spineopt].variables)
            vars = m.ext[:spineopt].variables[var_name]
            @testset for ind in keys(vars)
                var = vars[ind]
                _test_representative_periods_variable(m, var_name, ind, var, vars, vals, rt1, rt2, all_rt, t_invest)
            end
        end
    end
end

function _test_representative_periods_variable(m, var_name, ind, var, vars, vals, rt1, rt2, all_rt, t_invest)
    rpm = vals["temporal_block", "operations", "representative_periods_mapping"]
    (ind.t in all_rt || ind.t == t_invest || var_name == :node_state) && return
    coefs = get(rpm, start(ind.t), nothing)
    if coefs !== nothing
        @test var == sum(c * vars[(; SpineOpt._drop_key(ind, :t)..., t=rt)] for (c, rt) in zip(coefs, all_rt))
    end
end


function _test_representative_periods_constraint(m, con_name, ind, con, vals, rt1, rt2, all_rt, t_invest)
    con === nothing && return
    observed_con = constraint_object(con)
    d_from = direction(:from_node)
    d_to = direction(:to_node)
    expected_con = _expected_representative_periods_constraint(
        m, Val(con_name), ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
    )
    if expected_con !== nothing
        @test _is_constraint_equal(observed_con, expected_con)
    end
end

function _expected_representative_periods_constraint(
    m, ::Val{:cyclic_node_state}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    n, s_path, t_start, t_end, tb = ind
    @test n == node(:h2_node)
    @test s_path == [stochastic_scenario(:realisation)]
    @test t_start == TimeSlice(DateTime(1999, 12, 31), DateTime(2000, 1, 1), temporal_block(:operations))
    @test t_end == TimeSlice(DateTime(2000, 1, 10), DateTime(2000, 1, 11), temporal_block(:operations))
    @test tb == temporal_block(:operations)
    @fetch node_state = m.ext[:spineopt].variables
    @build_constraint(node_state[n, only(s_path), t_end] == node_state[n, only(s_path), t_start])
end
function _expected_representative_periods_constraint(
    m, ::Val{:nodal_balance}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    n, s, t = ind
    @test n in node()
    @test s == stochastic_scenario(:realisation)
    @test t in all_rt
    @fetch node_injection = m.ext[:spineopt].variables
    @build_constraint(node_injection[n, s, t] == 0)
end
function _expected_representative_periods_constraint(
    m, ::Val{:node_injection}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    n, s_path, t_before, t_after = ind
    @test n in node()
    @test s_path == [stochastic_scenario(:realisation)]
    s = only(s_path)
    @fetch node_injection, node_slack_pos, node_slack_neg, node_state, unit_flow = m.ext[:spineopt].variables
    if n in (node(:batt_node), node(:elec_node))
        @test t_after in all_rt
    else
        @test t_after in time_slice(m)
    end
    if n == node(:batt_node)
        fr_e2b = vals["unit__node__node", ["batt_unit", "batt_node", "elec_node"], "fix_ratio_out_in_unit_flow"]
        @build_constraint(
            + node_injection[n, s, t_after]
            ==
            - node_slack_neg[n, s, t_after]
            + node_slack_pos[n, s, t_after]
            - (1 / 24) * node_state[n, s, t_after]
            - unit_flow[unit(:batt_unit), node(:batt_node), d_from, s, t_after]
            + fr_e2b * unit_flow[unit(:batt_unit), node(:elec_node), d_from, s, t_after]
        )
    elseif n == node(:elec_node)
        elec_demand = parameter_value(vals["node", "elec_node", "demand"])
        fr_b2e = vals["unit__node__node", ["batt_unit", "elec_node", "batt_node"], "fix_ratio_out_in_unit_flow"]
        fr_e2h = vals["unit__node__node", ["electrolizer", "elec_node", "h2_node"], "fix_ratio_in_out_unit_flow"]
        @build_constraint(
            + node_injection[n, s, t_after]
            ==
            + fr_b2e * unit_flow[unit(:batt_unit), node(:batt_node), d_from, s, t_after]
            - unit_flow[unit(:batt_unit), node(:elec_node), d_from, s, t_after]
            - fr_e2h * unit_flow[unit(:electrolizer), node(:h2_node), d_to, s, t_after]
            + unit_flow[unit(:h2_gen), node(:elec_node), d_to, s, t_after]
            + unit_flow[unit(:pv), node(:elec_node), d_to, s, t_after]
            + unit_flow[unit(:wind), node(:elec_node), d_to, s, t_after]
            + unit_flow[unit(:conventional), node(:elec_node), d_to, s, t_after]
            - elec_demand(t=t_after)
        )
    else#if n == node(:h2_node)
        fr_h2e = vals["unit__node__node", ["h2_gen", "h2_node", "elec_node"], "fix_ratio_in_out_unit_flow"]
        @build_constraint(
            + node_injection[n, s, t_after]
            ==
            - node_slack_neg[n, s, t_after]
            + node_slack_pos[n, s, t_after]
            - (1 / 24) * node_state[n, s, t_after]
            + (1 / 24) * node_state[n, s, t_before]
            + unit_flow[unit(:electrolizer), node(:h2_node), d_to, s, t_after]
            - fr_h2e * unit_flow[unit(:h2_gen), node(:elec_node), d_to, s, t_after]
        )
    end
end
function _expected_representative_periods_constraint(
    m, ::Val{:node_state_capacity}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    n, s_path, t = ind
    @test n == node(:batt_node)
    @test s_path == [stochastic_scenario(:realisation)]
    @test t in all_rt
    @fetch node_state, storages_invested_available = m.ext[:spineopt].variables
    s = only(s_path)
    nsc = vals["node", string(n), "node_state_cap"]
    @build_constraint(node_state[n, s, t] <= nsc * storages_invested_available[n, s, t_invest])
end
function _expected_representative_periods_constraint(
    m, ::Val{:storages_invested_transition}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    n, s_path, t_before, t_after = ind
    @test n == node(:batt_node)
    @test s_path == [stochastic_scenario(:realisation)]
    @test t_after == t_invest
    @fetch storages_invested_available, storages_invested, storages_decommissioned = m.ext[:spineopt].variables
    s = only(s_path)
    @build_constraint(
        + storages_invested_available[n, s, t_after]
        - storages_invested_available[n, s, t_before]
        ==
        + storages_invested[n, s, t_after]
        - storages_decommissioned[n, s, t_after]
    )
end
function _expected_representative_periods_constraint(
    m, ::Val{:storages_invested_available}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    n, s, t = ind
    @test n == node(:batt_node)
    @test s == stochastic_scenario(:realisation)
    @test t == t_invest
    @fetch storages_invested_available = m.ext[:spineopt].variables
    cs = vals["node", string(n), "candidate_storages"]
    @build_constraint(storages_invested_available[n, s, t] <= cs)
end
function _expected_representative_periods_constraint(
    m, ::Val{:unit_flow_lb}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    u, n, d, s, t = ind
    @test u in (unit(:batt_unit), unit(:electrolizer), unit(:h2_gen))
    @test s == stochastic_scenario(:realisation)
    @test t in all_rt
    @fetch unit_flow = m.ext[:spineopt].variables
    if u == unit(:batt_unit)
        @test d in d_to
        nodes = (node(:batt_node), node(:elec_node))
        @test n in nodes
        other_n = only(setdiff(nodes, n))
        fr = vals["unit__node__node", [string(u), string(n), string(other_n)], "fix_ratio_out_in_unit_flow"]
        @build_constraint(fr * unit_flow[u, other_n, d_from, s, t] >= 0)
    elseif u == unit(:electrolizer)
        @test d in d_from
        @test n == node(:elec_node)
        fr = vals["unit__node__node", [string(u), string(n), "h2_node"], "fix_ratio_in_out_unit_flow"]
        @build_constraint(fr * unit_flow[u, node(:h2_node), d_to, s, t] >= 0)
    else# u == unit(:h2_gen)
        @test d in d_from
        @test n == node(:h2_node)
        fr = vals["unit__node__node", [string(u), string(n), "elec_node"], "fix_ratio_in_out_unit_flow"]
        @build_constraint(fr * unit_flow[u, node(:elec_node), d_to, s, t] >= 0)
    end
end
function _expected_representative_periods_constraint(
    m, ::Val{:unit_flow_capacity}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    u, n, d, s_path, t = ind
    @test u in unit()
    @test s_path == [stochastic_scenario(:realisation)]
    @test t in all_rt
    s = only(s_path)
    @fetch unit_flow, units_on = m.ext[:spineopt].variables
    rhs = if u == unit(:batt_unit)
        @test d in direction()
        cls = Dict(d_from => "unit__from_node", d_to => "unit__to_node")[d]
        vals[cls, ["batt_unit", "elec_node"], "unit_capacity"]
    elseif u == unit(:electrolizer)
        @test d in d_from
        vals["unit__from_node", [string(u), string(n)], "unit_capacity"]
    else
        @test d in d_to
        vals["unit__to_node", [string(u), string(n)], "unit_capacity"]
    end
    if u in (unit(:batt_unit), unit(:h2_gen), unit(:electrolizer), unit(:pv), unit(:wind))
        rhs *= units_on[u, s, t]
    end
    if u in (unit(:pv), unit(:wind))
        uaf = parameter_value(vals["unit", string(u), "unit_availability_factor"])
        rhs *= uaf(t=t)
    end
    @build_constraint(24 * unit_flow[u, n, d, s, t] <= 24 * rhs)
end
function _expected_representative_periods_constraint(
    m, ::Val{:unit_state_transition}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    u, s_path, t_before, t_after = ind
    @test u == unit(:h2_gen)
    @test s_path == [stochastic_scenario(:realisation)]
    @test t_after in all_rt
    @fetch units_on, units_started_up, units_shut_down = m.ext[:spineopt].variables
    s = only(s_path)
    @build_constraint(
        + units_on[u, s, t_after]
        - units_on[u, s, t_before]
        ==
        + units_started_up[u, s, t_after]
        - units_shut_down[u, s, t_after]
    )
end
function _expected_representative_periods_constraint(
    m, ::Val{:units_available}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    u, s, t = ind
    @test u in unit()
    @test s == stochastic_scenario(:realisation)
    @test t in all_rt
    @fetch units_on, units_invested_available = m.ext[:spineopt].variables
    @build_constraint(units_on[u, s, t] <= units_invested_available[u, s, t_invest])
end
function _expected_representative_periods_constraint(
    m, ::Val{:units_invested_transition}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    u, s_path, t_before, t_after = ind
    @test u in unit()
    @test s_path == [stochastic_scenario(:realisation)]
    @test t_after == t_invest
    @fetch units_invested_available, units_invested, units_mothballed = m.ext[:spineopt].variables
    s = only(s_path)
    @build_constraint(
        + units_invested_available[u, s, t_after]
        - units_invested_available[u, s, t_before]
        == 
        + units_invested[u, s, t_after]
        - units_mothballed[u, s, t_after]
    )
end
function _expected_representative_periods_constraint(
    m, ::Val{:units_invested_available}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    u, s, t = ind
    @test u in unit()
    @test s == stochastic_scenario(:realisation)
    @test t == t_invest
    @fetch units_invested_available = m.ext[:spineopt].variables
    cu = vals["unit", string(u), "candidate_units"]
    @build_constraint(units_invested_available[u, s, t] <= cu)
end
function _expected_representative_periods_constraint(
    m, ::Val{:min_up_time}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    # min_up_time of unit "h2_gen" is implicitly set to be the default model duration unit in preprocess_data_structure.jl, 
    # triggered by setting "online_variable_type" to be "unit_online_variable_type_integer" in the test dataset.
    u, s_path, t_con = ind
    
    @test u == unit(:h2_gen)
    @test s_path == [stochastic_scenario(:realisation)]
    @test t_con in all_rt

    look_behind = maximum(
        maximum_parameter_value(min_up_time(unit=u, stochastic_scenario=s, t=t_con) for s in s_path)
    )
    @test look_behind == min_up_time(unit=u)
    
    # The min_up_time of unit "h2_gen" is implicitly set to be the default model duration unit.
    @test min_up_time(unit=u) == Hour(1)
    @test duration_unit(model=model(:instance)) == :hour
    
    past_units_on_indices = units_on_indices(
        m;
        unit=u,
        stochastic_scenario=s_path,
        t=to_time_slice(m; t=TimeSlice(end_(t_con) - look_behind, end_(t_con))),
        temporal_block=anything,
    )

    past_scenarios = [ind.stochastic_scenario for ind in past_units_on_indices]
    @test past_scenarios == [stochastic_scenario(:realisation)]
    past_time_slices = [ind.t for ind in past_units_on_indices]
    @test past_time_slices == [t_con]

    s = only(s_path)
    weight = 1

    @fetch units_on, units_started_up = m.ext[:spineopt].variables
    @build_constraint(
        units_on[u, s, t_con]
        >=
        sum(
            units_started_up[u, s_past, t_past] * weight
            for (u, s_past, t_past) in past_units_on_indices
        )
    )
end
function _expected_representative_periods_constraint(
    m, ::Val{:min_down_time}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
)
    # min_down_time of unit "h2_gen" is implicitly set to be the default model duration unit in preprocess_data_structure.jl, 
    # triggered by setting "online_variable_type" to be "unit_online_variable_type_integer" in the test dataset.
    u, s_path, t_con = ind
    
    @test u == unit(:h2_gen)
    @test s_path == [stochastic_scenario(:realisation)]
    @test t_con in all_rt

    look_behind = maximum(
        maximum_parameter_value(min_down_time(unit=u, stochastic_scenario=s, t=t_con) for s in s_path)
    )
    @test look_behind == min_down_time(unit=u)
    
    # The min_down_time of unit "h2_gen" is implicitly set to be the default model duration unit.
    @test min_down_time(unit=u) == Hour(1)
    @test duration_unit(model=model(:instance)) == :hour
    
    past_units_on_indices = units_on_indices(
        m;
        unit=u,
        stochastic_scenario=s_path,
        t=to_time_slice(m; t=TimeSlice(end_(t_con) - look_behind, end_(t_con))),
        temporal_block=anything,
    )

    past_scenarios = [ind.stochastic_scenario for ind in past_units_on_indices]
    @test past_scenarios == [stochastic_scenario(:realisation)]
    past_time_slices = [ind.t for ind in past_units_on_indices]
    @test past_time_slices == [t_con]

    s = only(s_path)
    nou = vals["unit", string(u), "number_of_units"]
    weight = 1

    @fetch units_invested_available, units_on, units_shut_down = m.ext[:spineopt].variables
    @build_constraint(
        nou + units_invested_available[u, s, t_invest] - units_on[u, s, t_con] 
        >= 
        sum(
            units_shut_down[u, s_past, t_past] * weight
            for (u, s_past, t_past) in past_units_on_indices
        )
    )
end
function _expected_representative_periods_constraint(
    m, ::Val{X}, ind, observed_con, vals, rt1, rt2, all_rt, t_invest, d_from, d_to
) where X
    @info "unexpected constraint $X"
    @test false
    nothing
end

@testset "run_spineopt_representative_periods" begin
   _test_representative_periods()
end
