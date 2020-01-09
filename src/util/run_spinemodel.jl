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
function run_spinemodel(url::String; optimizer=Cbc.Optimizer, cleanup=true, extend=m -> nothing)
    run_spinemodel(url, url; optimizer=optimizer, cleanup=cleanup, extend=extend)
end

"""
    run_spinemodel(url_in, url_out; <keyword arguments>)

Run the Spine model from `url_in` and write report to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Keyword arguments

**`optimizer=Cbc.Optimizer`** is the constructor of the optimizer used for building and solving the model.

**`cleanup=true`** tells [`run_spinemodel`](@ref) whether or not convenience functors should be
set to `nothing` after completion.

**`extend=m -> nothing`** is a function for extending the model. [`run_spinemodel`](@ref) calls this function with
the internal `JuMP.Model` object before calling `JuMP.optimize!`.
"""
function run_spinemodel(
        url_in::String,
        url_out::String;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m->nothing)
    printstyled("Creating convenience functions...\n"; bold=true)
    @time using_spinedb(url_in, @__MODULE__; upgrade=true)
    m = nothing
    initialize_time_slice_history()
    outputs = Dict()
    for (k, (window_start, window_end)) in enumerate(rolling_windows())
        printstyled("Window $k\n"; bold=true, color=:underline)
        init_conds = variable_values(m)
        printstyled("Creating temporal structure...\n"; bold=true)
        @time generate_time_slice(window_start, window_end)
        printstyled("Initializing model...\n"; bold=true)
        @time begin
            m = Model(with_optimizer(optimizer))
            m.ext[:variables] = init_conds
            m.ext[:constraints] = Dict{Symbol,Dict}()
            create_variable_flow!(m)
            create_variable_units_on!(m)
            create_variable_units_available!(m)
            create_variable_units_started_up!(m)
            create_variable_units_shut_down!(m)
            create_variable_trans!(m)
            create_variable_stor_state!(m)
            objective_minimize_total_discounted_costs(m)
        end
        printstyled("Generating constraints...\n"; bold=true)
        @time begin
            println("[constraint_flow_capacity]")
            @time constraint_flow_capacity(m)
            println("[constraint_fix_ratio_out_in_flow]")
            @time constraint_fix_ratio_out_in_flow(m)
            println("[constraint_max_ratio_out_in_flow]")
            @time constraint_max_ratio_out_in_flow(m)
            println("[constraint_min_ratio_out_in_flow]")
            @time constraint_min_ratio_out_in_flow(m)
            println("[constraint_fix_ratio_out_out_flow]")
            @time constraint_fix_ratio_out_out_flow(m)
            println("[constraint_max_ratio_out_out_flow]")
            @time constraint_max_ratio_out_out_flow(m)
            println("[constraint_fix_ratio_in_in_flow]")
            @time constraint_fix_ratio_in_in_flow(m)
            println("[constraint_max_ratio_in_in_flow]")
            @time constraint_max_ratio_in_in_flow(m)
            println("[constraint_fix_ratio_out_in_trans]")
            @time constraint_fix_ratio_out_in_trans(m)
            println("[constraint_max_ratio_out_in_trans]")
            @time constraint_max_ratio_out_in_trans(m)
            println("[constraint_min_ratio_out_in_trans]")
            @time constraint_min_ratio_out_in_trans(m)
            println("[constraint_trans_capacity]")
            @time constraint_trans_capacity(m)
            println("[constraint_nodal_balance]")
            @time constraint_nodal_balance(m)
            println("[constraint_max_cum_in_flow_bound]")
            @time constraint_max_cum_in_flow_bound(m)
            println("[constraint_stor_capacity]")
            @time constraint_stor_capacity(m)
            println("[constraint_stor_state]")
            @time constraint_stor_state(m)
            println("[constraint_units_on]")
            @time constraint_units_on(m)
            println("[constraint_units_available]")
            @time constraint_units_available(m)
            println("[constraint_minimum_operating_point]")
            @time constraint_minimum_operating_point(m)
            println("[constraint_min_down_time]")
            @time constraint_min_down_time(m)
            println("[constraint_min_up_time]")
            @time constraint_min_up_time(m)
            println("[constraint_unit_state_transition]")
            @time constraint_unit_state_transition(m)
            println("[extend]")
            @time extend(m)
        end
        printstyled("Solving model...\n"; bold=true)
        @time optimize!(m)
        status = termination_status(m)
        status != MOI.OPTIMAL && break
        println("Optimal solution found")
        println("Objective function value: $(objective_value(m))")
        printstyled("Saving results...\n"; bold=true)
        @time save_outputs!(outputs, m, window_end)
    end
    printstyled("Writing report...\n"; bold=true)
    # TODO: cleanup && notusing_spinedb(url_in, @__MODULE__)
    @time write_report(outputs, url_out)
    return m
end

"""
    variable_values(m)

A dictionary mapping variable names to their value in the given model.
"""
function variable_values(m::Model)
    Dict{Symbol,Dict}(
        #:flow => variable_flow_value(m), # Not included in dynamical constraints. TODO: Relevant for future ramp constraints?
        :stor_state => variable_stor_state_value(m),
        :trans => variable_trans_value(m),
        #:units_available => variable_units_available_value(m), # Not included in dynamical constraints. TODO: Create if necessary?
        :units_on => variable_units_on_value(m),
        :units_shut_down => variable_units_shut_down_value(m),
        :units_started_up => variable_units_started_up_value(m),
    )
end

variable_values(::Nothing) = Dict{Symbol,Dict}()

"""
    save_outputs!(outputs, m)

Update `outputs` with values from `m`
"""
function save_outputs!(outputs, m, window_end)
    results = Dict(var => SpineModel.value(val) for (var, val) in m.ext[:variables])
    for out in output()
        value = get(results, out.name, nothing)
        if value === nothing
            @warn "can't find results for '$(out.name)'"
            continue
        end
        filter!(x -> x[1].t.start < window_end, value)
        existing_value = get!(outputs, out.name, Dict{NamedTuple,Any}())
        merge!(existing_value, value)
    end
end

function write_report(outputs, default_url)
    reports = Dict()
    for (rpt, out) in report__output()
        output_value = get(outputs, out.name, nothing)
        if output_value === nothing
            @warn "can't find outputs for '$(out.name)'"
            continue
        end
        url = output_db_url(report=rpt)
        url === nothing && (url = default_url)
        url_reports = get!(reports, url, Dict())
        rpt = get!(url_reports, rpt.name, Dict())
        d = rpt[out.name] = Dict()
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
function pack_trailing_dims(dictionary::Dict{S,T}, n::Int64=1) where {S<:NamedTuple,T}
    left_dict = Dict{Any,Any}()
    for (key, value) in dictionary
        # TODO: handle length(key) < n and stuff like that?
        left_key = NamedTuple{Tuple(collect(keys(key))[1:end-n])}(collect(values(key))[1:end-n])
        right_key = NamedTuple{Tuple(collect(keys(key))[end-n+1:end])}(collect(values(key))[end-n+1:end])
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

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by their `String` formulation.
"""
formulation(d::Dict{K,JuMP.ConstraintRef}) where {K} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d)
