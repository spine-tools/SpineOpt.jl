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
        with_optimizer=with_optimizer(Cbc.Optimizer, logLevel=0), 
        cleanup=true, 
        add_constraint_user=m -> nothing, 
        update_constraint_user=m -> nothing, 
        log_level=3)
    run_spinemodel(
        url, url; 
        with_optimizer=with_optimizer, 
        cleanup=cleanup, 
        add_constraint_user=add_constraint_user, 
        update_constraint_user=update_constraint_user, 
        log_level=log_level
    )
end


function generate_temporal_structure()
    generate_current_window()
    generate_time_slice()
    generate_time_slice_relationships()
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

**`add_constraint_user=m -> nothing`** allows adding user contraints.

**`update_constraint_user=m -> nothing`** allows updating contraints added by `add_constraint_user`.

**`log_level=3`** is the log level.
"""
function run_spinemodel(
        url_in::String,
        url_out::String;
        with_optimizer=with_optimizer(Cbc.Optimizer, logLevel=0),
        cleanup=true,
        add_constraint_user=m -> nothing, 
        update_constraint_user=m -> nothing, 
        log_level=3)
    level0 = log_level >= 0
    level1 = log_level >= 1
    level2 = log_level >= 2
    level3 = log_level >= 3
    results = Dict()
    @log level0 "Running Spine Model for $(url_in)..."
    @logtime level2 "Creating convenience functions..." using_spinedb(url_in, @__MODULE__; upgrade=true)
    @logtime level2 "Creating temporal structure..." generate_temporal_structure()
    @logtime level2 "Generating indices..." generate_variable_indices()
    @log level1 "Window 1: $current_window"
    @logtime level2 "Initializing model..." begin
        m = Model(with_optimizer)
        m.ext[:variables] = Dict{Symbol,Dict}()
        m.ext[:variables_lb] = Dict{Symbol,Any}()
        m.ext[:variables_ub] = Dict{Symbol,Any}()
        m.ext[:values] = Dict{Symbol,Dict}()
        m.ext[:constraints] = Dict{Symbol,Dict}()
        create_variables!(m)
        fix_variables!(m)
        objective_minimize_total_discounted_costs(m)
    end
    @logtime level2 "Adding constraints...\n" begin
        @logtime level3 "- [constraint_flow_capacity]" add_constraint_flow_capacity!(m)
        @logtime level3 "- [constraint_fix_ratio_out_in_flow]" add_constraint_fix_ratio_out_in_flow!(m)
        @logtime level3 "- [constraint_max_ratio_out_in_flow]" add_constraint_max_ratio_out_in_flow!(m)
        @logtime level3 "- [constraint_min_ratio_out_in_flow]" add_constraint_min_ratio_out_in_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_out_out_flow]" add_constraint_fix_ratio_out_out_flow!(m)
        @logtime level3 "- [constraint_max_ratio_out_out_flow]" add_constraint_max_ratio_out_out_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_in_in_flow]" add_constraint_fix_ratio_in_in_flow!(m)
        @logtime level3 "- [constraint_max_ratio_in_in_flow]" add_constraint_max_ratio_in_in_flow!(m)
        @logtime level3 "- [constraint_fix_ratio_out_in_trans]" add_constraint_fix_ratio_out_in_trans!(m)
        @logtime level3 "- [constraint_max_ratio_out_in_trans]" add_constraint_max_ratio_out_in_trans!(m)
        @logtime level3 "- [constraint_min_ratio_out_in_trans]" add_constraint_min_ratio_out_in_trans!(m)
        @logtime level3 "- [constraint_trans_capacity]" add_constraint_trans_capacity!(m)
        @logtime level3 "- [constraint_nodal_balance]" add_constraint_nodal_balance!(m)
        @logtime level3 "- [constraint_max_cum_in_flow_bound]" add_constraint_max_cum_in_flow_bound!(m)
        @logtime level3 "- [constraint_stor_capacity]" add_constraint_stor_capacity!(m)
        @logtime level3 "- [constraint_stor_state]" add_constraint_stor_state!(m)
        @logtime level3 "- [constraint_units_on]" add_constraint_units_on!(m)
        @logtime level3 "- [constraint_units_available]" add_constraint_units_available!(m)
        @logtime level3 "- [constraint_minimum_operating_point]" add_constraint_minimum_operating_point!(m)
        @logtime level3 "- [constraint_min_down_time]" add_constraint_min_down_time!(m)
        @logtime level3 "- [constraint_min_up_time]" add_constraint_min_up_time!(m)
        @logtime level3 "- [constraint_unit_state_transition]" add_constraint_unit_state_transition!(m)
        @logtime level3 "- [constraint_user]" add_constraint_user(m)
    end
    k = 2
    while true
        @logtime level2 "Solving model..." optimize!(m)
        if termination_status(m) == MOI.OPTIMAL
            @log level1 "Optimal solution found, objective function value: $(objective_value(m))"
            @logtime level2 "Saving results..." begin
                save_values!(m)
                save_results!(results, m)
            end
        else
            @log level1 "Unable to find solution (reason: $(termination_status(m))), exiting..."
            break
        end
        roll_temporal_structure() || break
        @log level1 "Window $k: $current_window"
        @logtime level2 "Updating model..." begin            
            update_variables!(m)
            fix_variables!(m)
            objective_minimize_total_discounted_costs(m)
        end
        @logtime level2 "Updating constraints...\n" begin
            @logtime level3 "- [constraint_flow_capacity]" update_constraint_flow_capacity!(m)
            @logtime level3 "- [constraint_fix_ratio_out_in_flow]" update_constraint_fix_ratio_out_in_flow!(m)
            @logtime level3 "- [constraint_max_ratio_out_in_flow]" update_constraint_max_ratio_out_in_flow!(m)
            @logtime level3 "- [constraint_min_ratio_out_in_flow]" update_constraint_min_ratio_out_in_flow!(m)
            @logtime level3 "- [constraint_fix_ratio_out_out_flow]" update_constraint_fix_ratio_out_out_flow!(m)
            @logtime level3 "- [constraint_max_ratio_out_out_flow]" update_constraint_max_ratio_out_out_flow!(m)
            @logtime level3 "- [constraint_fix_ratio_in_in_flow]" update_constraint_fix_ratio_in_in_flow!(m)
            @logtime level3 "- [constraint_max_ratio_in_in_flow]" update_constraint_max_ratio_in_in_flow!(m)
            @logtime level3 "- [constraint_fix_ratio_out_in_trans]" update_constraint_fix_ratio_out_in_trans!(m)
            @logtime level3 "- [constraint_max_ratio_out_in_trans]" update_constraint_max_ratio_out_in_trans!(m)
            @logtime level3 "- [constraint_min_ratio_out_in_trans]" update_constraint_min_ratio_out_in_trans!(m)
            @logtime level3 "- [constraint_trans_capacity]" update_constraint_trans_capacity!(m)
            @logtime level3 "- [constraint_nodal_balance]" update_constraint_nodal_balance!(m)
            @logtime level3 "- [constraint_stor_capacity]" update_constraint_stor_capacity!(m)
            @logtime level3 "- [constraint_stor_state]" update_constraint_stor_state!(m)
            @logtime level3 "- [constraint_units_on]" update_constraint_units_on!(m)
            @logtime level3 "- [constraint_units_available]" update_constraint_units_available!(m)
            @logtime level3 "- [constraint_minimum_operating_point]" update_constraint_minimum_operating_point!(m)
            @logtime level3 "- [constraint_min_down_time]" update_constraint_min_up_time!(m)
            @logtime level3 "- [constraint_min_up_time]" update_constraint_min_down_time!(m)
            @logtime level3 "- [constraint_unit_state_transition]" update_constraint_unit_state_transition!(m)
            @logtime level3 "- [constraint_user]" update_constraint_user(m)
        end
        k += 1
    end
    @logtime level2 "Writing report..." write_report(results, url_out)
    # TODO: cleanup && notusing_spinedb(url_in, @__MODULE__)
    m
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
        # filter!(x -> window_start <= start(x[1].t) < window_end, value)
        existing_result = get!(results, out.name, Dict{NamedTuple,Any}())
        merge!(existing_result, value)
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
        rpt = get!(url_reports, rpt.name, Dict{Symbol,Dict{NamedTuple,TimeSeries}}())
        d = rpt[out.name] = Dict{NamedTuple,TimeSeries}()
        for (key, val) in pack_trailing_dims(value)
            inds = first.(val)
            vals = last.(val)
            d[key] = TimeSeries(inds, vals, false, false)
        end
    end
    for (url, url_reports) in reports
        for (rpt, output_params) in url_reports
            write_parameters(output_params, url; report=string(rpt))
        end
    end
end

"""
    pack_trailing_dims(dictionary::Dict, n::Int64=1)

An equivalent dictionary where the last `n` dimensions are packed into a matrix
"""
function pack_trailing_dims(dictionary::Dict{K,V}, n::Int64=1) where {K<:NamedTuple,V}
    left_dict = Dict()
    for (key, value) in dictionary
        # TODO: handle length(key) < n and stuff like that?
        bp = length(key) - n
        left_key = NamedTuple{Tuple(collect(keys(key))[1:bp])}(collect(values(key))[1:bp])
        right_key = NamedTuple{Tuple(collect(keys(key))[bp + 1:end])}(collect(values(key))[bp + 1:end])
        right_dict = get!(left_dict, left_key, Dict())
        right_dict[right_key] = value
    end
    if n > 1
        Dict(key => reshape([(k, v) for (k, v) in sort(collect(value))], n, :) for (key, value) in left_dict)
    else
        Dict(key => [(k, v) for (k, v) in sort(collect(value))] for (key, value) in left_dict)
    end
end

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by their `String` formulation.
"""
formulation(d::Dict{K,JuMP.ConstraintRef}) where {K} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d)
