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

function _ref_setup(storage_count)
    m_start = DateTime(2023, 1, 1, 0)
    m_end = DateTime(2023, 1, 8, 0)
    res = Hour(24)
    timestamps = collect(m_start:res:m_end)
    ts_count = length(timestamps)
    demand_vals = collect(0 : ts_count - 1)
    base_cost = 1
    cost_vals = [(1 + sin(k)) * base_cost for k in demand_vals]
    demand_ts = TimeSeries(timestamps, demand_vals)
    cost_ts = TimeSeries(timestamps, cost_vals)
    charge_cap = 50
    discharge_cap = charge_cap
    storage_cap = 1000
    test_data = Dict(
        :objects => Any[
            ("model", "test_model"),
            ("temporal_block", "flat"),
            ("stochastic_structure", "deterministic"),
            ("stochastic_scenario", "realisation"),
            ("node", "demand_node"),
            ("unit", "other_unit"),
            ("report", "report_x"),
            ("report", "report_y"),
        ],
        :relationships => Any[
            ("model__default_temporal_block", ("test_model", "flat")),
            ("model__default_stochastic_structure", ("test_model", "deterministic")),
            ("stochastic_structure__stochastic_scenario", ("deterministic", "realisation")),
            ("unit__to_node", ("other_unit", "demand_node")),
            ("report__output", ("report_x", "node_state")),
            ("report__output", ("report_x", "storages_invested_available")),
            #FIXME: Uncomment either of the following lines will fail the test.
            # ("report__output", ("report_y", "node_state")),
            # ("report__output", ("report_y", "storages_invested_available")),
        ],
        :object_parameter_values => Any[
            ("model", "test_model", "model_start", unparse_db_value(m_start)),
            ("model", "test_model", "model_end", unparse_db_value(m_end)),
            ("model", "test_model", "max_iterations", 20),
            ("temporal_block", "flat", "resolution", unparse_db_value(res)),
            ("node", "demand_node", "demand", unparse_db_value(demand_ts)),
            ("node", "demand_node", "node_slack_penalty", 10000),
        ],
        :relationship_parameter_values => Any[
            ("unit__to_node", ("other_unit", "demand_node"), "vom_cost", unparse_db_value(cost_ts)),
        ],
    )
    for k in 1:storage_count
        u, n = "storage_unit$k", "storage_node$k"
        append!(test_data[:objects], (("node", n), ("unit", u)))
        append!(
            test_data[:relationships],
            (
                ("unit__from_node", (u, "demand_node")),
                ("unit__from_node", (u, n)),
                ("unit__to_node", (u, "demand_node")),
                ("unit__to_node", (u, n)),
                ("unit__node__node", (u, n, "demand_node")),
                ("unit__node__node", (u, "demand_node", n)),
            )
        )
        append!(
            test_data[:object_parameter_values],
            (
                ("node", n, "has_state", true),
                ("node", n, "state_coeff", 1.0),
                ("node", n, "initial_node_state", storage_cap / 2),
                ("node", n, "node_state_cap", storage_cap),
                ("node", n, "node_slack_penalty", 10000),
            )
        )
        append!(
            test_data[:relationship_parameter_values],
            (
                ("unit__to_node", (u, "demand_node"), "unit_capacity", discharge_cap),
                ("unit__to_node", (u, n), "unit_capacity", charge_cap),
                ("unit__to_node", (u, "demand_node"), "vom_cost", base_cost),
                ("unit__node__node", (u, n, "demand_node"), "fix_ratio_out_in_unit_flow", 0.8),
                ("unit__node__node", (u, "demand_node", n), "fix_ratio_out_in_unit_flow", 1),
            )
        )
    end
    url_in = "sqlite://"
    _load_test_data(url_in, test_data)
    out_file = "deleteme.sqlite"
    rm(out_file; force=true)
    url_out = "sqlite:///$out_file"
    url_in, url_out
end

function _ref_investments_setup(storage_count)
    url_in, url_out = _ref_setup(storage_count)
    investment_data = Dict(
        :objects => Any[("temporal_block", "investments_flat")],
        :relationships => Any[
            ("model__default_investment_temporal_block", ("test_model", "investments_flat")),
            ("model__default_investment_stochastic_structure", ("test_model", "deterministic")),
        ],
        :object_parameter_values => Any[
            ("temporal_block", "investments_flat", "resolution", unparse_db_value(Year(1))),
        ],
    )
    for k in 1:storage_count
        n = "storage_node$k"
        append!(
            investment_data[:object_parameter_values],
            (
                ("node", n, "candidate_storages", 4),
                ("node", n, "benders_starting_storages_invested", 0.01),
                ("node", n, "storage_investment_cost", 100),
                ("node", n, "storage_investment_variable_type", "storage_investment_variable_type_continuous"),
            )
        )
    end
    import_data(url_in, "Add investment data"; investment_data...)
    url_in, url_out
end

function _lt_storage_data(storage_count)
    rf = Day(1)
    lt_stor_res = Day(1)
    Dict(
        :alternatives => [("lt_storage_alt",)],
        :scenarios => [("base",), ("lt_storage_scen",)],
        :scenario_alternatives => [
            ("base", "Base"), ("lt_storage_scen", "Base"), ("lt_storage_scen", "lt_storage_alt")
        ],
        :objects => Any[
            ("stage", "lt_storage"),
        ],
        :relationships => Any[
            ("stage__output__node", ("lt_storage", "node_state", "storage_node$k")) for k in 1:storage_count
        ],
        :object_parameter_values => Any[
            ("stage", "lt_storage", "stage_scenario", "lt_storage_scen"),
            ("model", "test_model", "roll_forward", unparse_db_value(rf)),
            ("model", "test_model", "roll_forward", nothing, "lt_storage_alt"),
            ("temporal_block", "flat", "resolution", unparse_db_value(lt_stor_res), "lt_storage_alt"),
        ],
    )
end   

function _lt_storage_setup(storage_count)
    url_in, url_out = _ref_setup(storage_count)
    lt_storage_data = _lt_storage_data(storage_count)
    import_data(url_in, "Add lt storage data"; lt_storage_data...)
    url_in, url_out
end

function _lt_storage_investments_setup(storage_count)
    url_in, url_out = _ref_investments_setup(storage_count)
    lt_storage_data = _lt_storage_data(storage_count)
    lt_storage_investments_data = Dict(
        :relationships => Any[
            ("stage__output", ("lt_storage", "storages_invested_available"))
        ],
        :relationship_parameter_values => Any[
            (
                "stage__output",
                ("lt_storage", "storages_invested_available"),
                "output_resolution",
                unparse_db_value(Hour(1)),
            )
        ],
    )
    merge!(append!, lt_storage_data, lt_storage_investments_data)
    import_data(url_in, "Add lt storage investments data"; lt_storage_data...)
    url_in, url_out
end

function _test_run_spineopt_lt_storage_benders_storage_investment()
    storage_count = 1
    url_in, url_out = _ref_investments_setup(storage_count)
    m = run_spineopt(url_in, url_out; log_level=0)
    R = Module()
    using_spinedb(url_out, R)
    last_t = maximum(end_.(time_slice(m)))
    extend_ts!(ts) = (ts[last_t] = NaN; ts)
    out_pv_by_node_by_name = Dict(
        out_name => Dict(n => parameter_value(extend_ts!(getproperty(R, out_name)(node=n))) for n in R.node())
        for out_name in (:node_state, :storages_invested_available) 
    )
    url_in, url_out = _lt_storage_investments_setup(storage_count)
    m = run_spineopt(url_in, url_out; log_level=0, filters=Dict("scenario" => "base")) do m
        add_event_handler!(m, :window_about_to_solve) do m, k
            @testset for out_name in keys(out_pv_by_node_by_name)
                out_pv_by_node = out_pv_by_node_by_name[out_name]
                inds = m.ext[:spineopt].variables_definition[out_name][:indices](m)
                last_ind = last(sort(collect(inds)))
                @test !any(is_fixed(m.ext[:spineopt].variables[out_name][ind]) for ind in inds if ind != last_ind)
                var = m.ext[:spineopt].variables[out_name][last_ind]
                fix_val = is_fixed(var) ? fix_value(var) : nothing
                ref_val = out_pv_by_node[last_ind.node](t=last_ind.t)
                @test fix_val == ref_val
            end
        end
    end
    @test termination_status(m) == MOI.OPTIMAL
end

function _test_run_spineopt_lt_storage_benders_storage_investment_with_slack_penalty()
    storage_count = 1
    url_in, url_out = _ref_investments_setup(storage_count)
    m = run_spineopt(url_in, url_out; log_level=0)
    R = Module()
    using_spinedb(url_out, R)
    last_t = maximum(end_.(time_slice(m)))
    extend_ts!(ts) = (ts[last_t] = NaN; ts)
    out_pv_by_node_by_name = Dict(
        out_name => Dict(n => parameter_value(extend_ts!(getproperty(R, out_name)(node=n))) for n in R.node())
        for out_name in (:node_state, :storages_invested_available) 
    )
    url_in, url_out = _lt_storage_investments_setup(storage_count)
    penalty = 100
    slack_penalty_data = Dict(
        :relationship_parameter_values => Any[
            ("stage__output__node", ("lt_storage", "node_state", "storage_node$k"), "slack_penalty", penalty)
            for k in 1:storage_count
        ]
    )
    import_data(url_in, "Add penalty data"; slack_penalty_data...)
    m = run_spineopt(url_in, url_out; log_level=0, filters=Dict("scenario" => "base")) do m
        add_event_handler!(m, :window_about_to_solve) do m, k
            @testset for out_name in keys(out_pv_by_node_by_name)
                out_pv_by_node = out_pv_by_node_by_name[out_name]
                inds = m.ext[:spineopt].variables_definition[out_name][:indices](m)
                last_ind = last(sort(collect(inds)))
                var = m.ext[:spineopt].variables[out_name][last_ind]
                ref_val = out_pv_by_node[last_ind.node](t=last_ind.t)
                if out_name === :storages_invested_available
                    @test !any(is_fixed(m.ext[:spineopt].variables[out_name][ind]) for ind in inds if ind != last_ind)
                    fix_val = is_fixed(var) ? fix_value(var) : nothing
                    @test fix_val == ref_val
                elseif out_name === :node_state
                    @test !any(is_fixed(m.ext[:spineopt].variables[out_name][ind]) for ind in inds)
                    cons = m.ext[:spineopt].constraints[:lt_storage_node_state_slack]
                    @test !any(haskey(cons, ind) for ind in inds if ind != last_ind)
                    obs_con = constraint_object(m.ext[:spineopt].constraints[:lt_storage_node_state_slack][last_ind])
                    slack_pos = m.ext[:spineopt].variables[:lt_storage_node_state_slack_pos][last_ind]
                    slack_neg = m.ext[:spineopt].variables[:lt_storage_node_state_slack_neg][last_ind]
                    exp_con = @build_constraint(var + slack_pos - slack_neg == ref_val)
                    @test _is_constraint_equal(obs_con, exp_con)
                    @test objective_function(m).terms[slack_pos] == penalty
                    @test objective_function(m).terms[slack_neg] == penalty
                end
            end
        end
    end
end

@testset "run_spineopt_multi_stage" begin
    _test_run_spineopt_lt_storage_benders_storage_investment()
    _test_run_spineopt_lt_storage_benders_storage_investment_with_slack_penalty()
end
