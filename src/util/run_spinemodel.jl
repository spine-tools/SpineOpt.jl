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
    window_start, window_end = rolling_window()
    generate_time_slice(window_start, window_end)
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

**`extend=m -> nothing`** is a function for extending the model. [`run_spinemodel`](@ref) calls this function with
the internal `JuMP.Model` object before calling `JuMP.optimize!`.

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
    @log level0 "Running Spine Model for $(url_in)..."
    @logtime level2 "Creating convenience functions..." using_spinedb(url_in, @__MODULE__; upgrade=true)
    @logtime level2 "Creating temporal structure..." generate_temporal_structure()
    @logtime level2 "Generating indices..." generate_variable_indices()
    @log level1 "Window: $current_window"
    @logtime level2 "Initializing model..." begin
        m = Model(with_optimizer)
        m.ext[:variables] = Dict{Symbol,Dict}()
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
    @logtime level2 "Solving model..." optimize!(m)
    if termination_status(m) == MOI.OPTIMAL
        @log level1 "Optimal solution found, objective function value: $(objective_value(m))"
    end
    return m
    while roll_temporal_structure()
        @log level1 "Window: $current_window"
        save_variables!(m)
        fix_variables!(m)
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
            @logtime level3 "- [constraint_min_up_time]" update_constraint_min_down_time!(m)
            @logtime level3 "- [constraint_min_down_time]" update_constraint_min_up_time!(m)
            @logtime level3 "- [constraint_unit_state_transition]" update_constraint_unit_state_transition!(m)
            @logtime level3 "- [constraint_user]" update_constraint_user(m)
        end        
        @logtime level2 "Solving model..." optimize!(m)
        if termination_status(m) == MOI.OPTIMAL
            @log level1 "Optimal solution found, objective function value: $(objective_value(m))"
        end
    end
    return m

    outputs = Dict()
    for (k, (window_start, window_end)) in enumerate(rolling_windows())
        @log level1 "Window $k, from $window_start to $window_end"
        @logtime level2 "Initializing model..." begin
            m = Model(with_optimizer)
            m.ext[:variables] = results
            m.ext[:constraints] = Dict{Symbol,Dict}()
            create_variables!(m)
            objective_minimize_total_discounted_costs(m)
        end
        
        termination_status(m) != MOI.OPTIMAL && break
        @log level1 "Optimal solution found, objective function value: $(objective_value(m))"
        results = value(m.ext[:variables])
        @logtime level2 "Saving results..." save_outputs!(outputs, results, window_start, window_end)
    end
    @logtime level2 "Writing report..." write_report(outputs, url_out)
    # TODO: cleanup && notusing_spinedb(url_in, @__MODULE__)
    return m
end



"""
    save_outputs!(outputs, results, window_start, window_end)

Update `outputs` with given `results`.
"""
function save_outputs!(outputs, results, window_start, window_end)
    for out in output()
        value = get(results, out.name, nothing)
        if value === nothing
            @warn "can't find results for '$(out.name)'"
            continue
        end
        filter!(x -> window_start <= start(x[1].t) < window_end, value)
        existing_value = get!(outputs, out.name, Dict{NamedTuple,Any}())
        merge!(existing_value, value)
    end
end

function write_report(outputs, default_url)
    reports = Dict()
    for (rpt, out) in report__output()
        output_value = get(outputs, out.name, nothing)
        if output_value === nothing
            continue
        end
        url = output_db_url(report=rpt, _strict=false)
        url === nothing && (url = default_url)
        url_reports = get!(reports, url, Dict())
        rpt = get!(url_reports, rpt.name, Dict{Symbol,Dict{NamedTuple,TimeSeries}}())
        d = rpt[out.name] = Dict{NamedTuple,TimeSeries}()
        for (key, val) in pack_trailing_dims(output_value)
            inds = map(x->x[1], val)
            vals = map(x->x[2], val)
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
    value(d::Dict)

An equivalent dictionary where `JuMP.VariableRef` values are replaced by their `JuMP.value`.
"""
value(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => value(v) for (k, v) in d)

value(v::JuMP.VariableRef) = has_values(owner_model(v)) ? JuMP.value(v) : zero(Float64)
value(x) = x

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by their `String` formulation.
"""
formulation(d::Dict{K,JuMP.ConstraintRef}) where {K} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d)
