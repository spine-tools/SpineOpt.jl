#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    run_spinemodel(url; <keyword arguments>)

Run the Spine model from `url` and write report to the same `url`.
Keyword arguments have the same purpose as for [`run_spinemodel`](@ref).
"""
function run_spinemodel(
        url::String;
        with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0),
        cleanup=true,
        add_constraints=m -> nothing,
        update_constraints=m -> nothing,
        log_level=3)
    run_spinemodel(
        url,
        url;
        with_optimizer=with_optimizer,
        cleanup=cleanup,
        add_constraints=add_constraints,
        update_constraints=update_constraints,
        log_level=log_level
    )
end


function generate_temporal_structure()
    generate_current_window()
    generate_time_slice()
    generate_time_slice_relationships()
end


function generate_stochastic_structure()
    # TODO: Generate stochastic structure
end


"""
    run_spinemodel(url_in, url_out; <keyword arguments>)

Run the Spine model from `url_in` and write report to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Keyword arguments

**`with_optimizer=with_optimizer(Cbc.Optimizer, logLevel=0)`** is the optimizer factory for building the JuMP model.

**`cleanup=true`** tells [`run_spinemodel`](@ref) whether or not convenience functors should be
set to `nothing` after completion.

**`add_constraints=m -> nothing`** is called with the `Model` object in the first optimization window, and allows adding user contraints.

**`update_constraints=m -> nothing`** is called in windows 2 to the last, and allows updating contraints added by `add_constraints`.

**`log_level=3`** is the log level.
"""
function run_spinemodel(
        url_in::String,
        url_out::String;
        with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
        cleanup=true,
        add_constraints=m -> nothing,
        update_constraints=m -> nothing,
        log_level=3)
    level2 = log_level >= 2
    @log true "Running Spine Model for $(url_in)..."
    @logtime level2 "Initializing data structure from db..." begin
        using_spinedb(url_in, @__MODULE__; upgrade=true)
        generate_missing_items()
    end
    @logtime level2 "Preprocessing data structure..." preprocess_data_structure()
    rerun_spinemodel(
        url_in,
        url_out;
        with_optimizer=with_optimizer,
        cleanup=cleanup,
        add_constraints=add_constraints,
        update_constraints=update_constraints,
        log_level=log_level
    )
end

function rerun_spinemodel(
        url_in::String,
        url_out::String;
        with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
        cleanup=true,
        add_constraints=m -> nothing,
        update_constraints=m -> nothing,
        log_level=3)
    level0 = log_level >= 0
    level1 = log_level >= 1
    level2 = log_level >= 2
    level3 = log_level >= 3
    results = Dict()

    # variables used in the calculation of ptdfs and lodfs using PowerSystems.jl
    con__mon = Tuple{Object,Object}[] # this is a set of monitored and contingent line tuples that must be considered as defined by the connection_monitored and connection_contingency parmaeters
    monitored_lines=[]
    ptdf_conn_n = Dict{Tuple{Object,Object},Float64}() #ptdfs returned by PowerSystems.jl
    lodf_con_mon = Dict{Tuple{Object,Object},Float64}() #lodfs calcuated based on ptdfs returned by PowerSystems.jl
    net_inj_nodes=[] # this is the set of nodes with demand or generation

    @log level0 "Running Spine Model for $(url_in)..."
    @logtime level2 "Initializing data structure from db..." using_spinedb(url_in, @__MODULE__; upgrade=true)
    @logtime level2 "Preprocessing data structure..." preprocess_data_structure()
    @logtime level2 "Creating temporal structure..." generate_temporal_structure()
    @logtime level2 "Creating stochastic structure..." generate_stochastic_structure()
    @log level1 "Window 1: $current_window"
    @logtime level2 "Initializing model..." begin
        m = Model(with_optimizer)
        println()
        println("variables...")
        m.ext[:variables] = Dict{Symbol,Dict}()
        m.ext[:variables_lb] = Dict{Symbol,Any}()
        m.ext[:variables_ub] = Dict{Symbol,Any}()
        m.ext[:values] = Dict{Symbol,Dict}()
        m.ext[:constraints] = Dict{Symbol,Dict}()
        create_variables!(m)
        println("fix variables...")
        fix_variables!(m)
        println("objective...")
        set_objective!(m)
    end

        @logtime level2 "Processing network...\n" process_network()
        @logtime level2 "Adding constraints...\n" begin
        @logtime level3 "- [constraint_nodal_balance]" add_constraint_nodal_balance!(m)
        @logtime level3 "- [constraint_group_balance]" add_constraint_group_balance!(m)
        @logtime level3 "- [constraint_connection_flow_ptdf]" add_constraint_connection_flow_ptdf!(m, ptdf_conn_n, net_inj_nodes)
        @logtime level3 "- [constraint_connection_flow_lodf]" add_constraint_connection_flow_lodf!(m, lodf_con_mon, con__mon)
        @logtime level3 "- [constraint_unit_flow_capacity]" add_constraint_unit_flow_capacity!(m)
        @logtime level3 "- [constraint_fix_ratio_out_in_unit_flow]" add_constraint_fix_ratio_out_in_unit_flow!(m)
        @logtime level3 "- [constraint_max_ratio_out_in_unit_flow]" add_constraint_max_ratio_out_in_unit_flow!(m)
        @logtime level3 "- [constraint_min_ratio_out_in_unit_flow]" add_constraint_min_ratio_out_in_unit_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_out_out_unit_flow]" add_constraint_fix_ratio_out_out_unit_flow!(m)
        @logtime level3 "- [constraint_max_ratio_out_out_unit_flow]" add_constraint_max_ratio_out_out_unit_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_in_in_unit_flow]" add_constraint_fix_ratio_in_in_unit_flow!(m)
        @logtime level3 "- [constraint_max_ratio_in_in_unit_flow]" add_constraint_max_ratio_in_in_unit_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_in_out_unit_flow]" add_constraint_fix_ratio_in_out_unit_flow!(m)
        @logtime level3 "- [constraint_max_ratio_in_out_unit_flow]" add_constraint_max_ratio_in_out_unit_flow!(m)
        @logtime level3 "- [constraint_min_ratio_in_out_unit_flow]" add_constraint_min_ratio_in_out_unit_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_out_in_connection_flow]" add_constraint_fix_ratio_out_in_connection_flow!(m)
        @logtime level3 "- [constraint_max_ratio_out_in_connection_flow]" add_constraint_max_ratio_out_in_connection_flow!(m)
        @logtime level3 "- [constraint_min_ratio_out_in_connection_flow]" add_constraint_min_ratio_out_in_connection_flow!(m)
        @logtime level3 "- [constraint_connection_flow_capacity]" add_constraint_connection_flow_capacity!(m)
        @logtime level3 "- [constraint_node_state_capacity]" add_constraint_node_state_capacity!(m)
        @logtime level3 "- [constraint_max_cum_in_unit_flow_bound]" add_constraint_max_cum_in_unit_flow_bound!(m)
        @logtime level3 "- [constraint_units_on]" add_constraint_units_on!(m)
        @logtime level3 "- [constraint_units_available]" add_constraint_units_available!(m)
        @logtime level3 "- [constraint_minimum_operating_point]" add_constraint_minimum_operating_point!(m)
        @logtime level3 "- [constraint_min_down_time]" add_constraint_min_down_time!(m)
        @logtime level3 "- [constraint_min_up_time]" add_constraint_min_up_time!(m)
        @logtime level3 "- [constraint_unit_state_transition]" add_constraint_unit_state_transition!(m)
        @logtime level3 "- [constraint_user]" add_constraints(m)
    end
    k = 2
    while optimize_model!(m)
        @log level1 "Optimal solution found, objective function value: $(objective_value(m))"
        @logtime level2 "Saving results..." begin
            save_values!(m)
            save_results!(results, m)
        end
        roll_temporal_structure() || break
        @log level1 "Window $k: $current_window"
        @logtime level2 "Updating model..." begin
            update_variables!(m)
            fix_variables!(m)
            update_varying_objective!(m)
        end
        @logtime level2 "Updating varying constraints..." update_varying_constraints!(m)
        @logtime level2 "Updating user constraints..." update_constraints(m)
        k += 1
    end
    @logtime level2 "Writing report..." write_report(results, url_out)
    # TODO: cleanup && notusing_spinedb(url_in, @__MODULE__)
    m
end

function optimize_model!(m::Model)
    optimize!(m)
    if termination_status(m) == MOI.OPTIMAL
        true
    else
        @log true "Unable to find solution (reason: $(termination_status(m)))"
        # TODO: perhaps add the option to write the mps for diagnostics as follows
        #write_to_file(m, "model_diagnostics.mps")
        false
    end
end

"""
    save_results!(results, m)

Update `results` with results from `m`.
"""
function save_results!(results, m)
    for out in output()
        value = get(m.ext[:values], out.name, nothing)
        if value === nothing
            @warn "can't find results for '$(out.name)'"
            continue
        end
        value_ = Dict{NamedTuple,Number}((; k..., t=start(k.t)) => v for (k, v) in value)
        existing = get!(results, out.name, Dict{NamedTuple,Number}())
        merge!(existing, value_)
    end
end

function write_report(results, default_url)
    reports = Dict()
    for (rpt, out) in report__output()
        value = get(results, out.name, nothing)
        if value === nothing
            continue
        end
        url = output_db_url(report=rpt, _strict=false)
        url === nothing && (url = default_url)
        url_reports = get!(reports, url, Dict())
        report = get!(url_reports, rpt.name, Dict{Symbol,Dict{NamedTuple,TimeSeries}}())
        d = report[out.name] = Dict{NamedTuple,TimeSeries}()
        for (k, v) in pulldims(value, :t)
            inds = first.(v)
            vals = last.(v)
            d[k] = TimeSeries(inds, vals, false, false)
        end
    end
    for (url, url_reports) in reports
        for (rpt_name, output_params) in url_reports
            write_parameters(output_params, url; report=string(rpt_name))
        end
    end
end

"""
    pulldims(input, dims...)

An equivalent dictionary where the given dimensions are pulled from the key to the value.
"""
function pulldims(input::Dict{K,V}, dims::Symbol...) where {K<:NamedTuple,V}
    output = Dict()
    for (key, value) in sort(input)
        output_key = (; (k => v for (k, v) in pairs(key) if !(k in dims))...)
        output_value = ((key[dim] for dim in dims)..., value)
        push!(get!(output, output_key, []), output_value)
    end
    output
end

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by their `String` formulation.
"""
formulation(d::Dict{K,JuMP.ConstraintRef}) where {K} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d)
