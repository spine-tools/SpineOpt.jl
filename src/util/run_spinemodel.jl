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
    run_spinemodel(
        url;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m->nothing
    )

Run the Spine model from `url` and write report to the same `url`.
Keyword arguments have the same purpose as for [`run_spinemodel`](@ref).
"""
function run_spinemodel(url::String; optimizer=Cbc.Optimizer, cleanup=true, extend=m->nothing)
    run_spinemodel(url, url; optimizer=optimizer, cleanup=cleanup, extend=extend)
end

"""
    run_spinemodel(
        url_in, url_out;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m->nothing
    )

Run the Spine model from `url_in` and write report to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Optional keyword arguments

**`optimizer`** is the constructor of the optimizer used for building and solving the model.

**`cleanup`** tells [`run_spinemodel`](@ref) whether or not convenience function callables should be
set to `nothing` after completion.

**`extend`** is a function for extending the model. [`run_spinemodel`](@ref) calls this function with
the internal `JuMP.Model` object before calling `JuMP.optimize!`.
"""
function run_spinemodel(
        url_in::String,
        url_out::String;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m->nothing,
        rolling_horizon=:default)
    printstyled("Creating convenience functions...\n"; bold=true)
    @time using_spinedb(url_in; upgrade=true)
    for (roll_count, block_time_slices) in enumerate(block_time_slices_split())
        printstyled("Roll $roll_count\n"; bold=true, color=:underline)
        printstyled("Creating temporal structure...\n"; bold=true)
        @time begin
            generate_time_slice(block_time_slices)
            generate_time_slice_relationships()
        end
        printstyled("Initializing model...\n"; bold=true)
        @time begin
            m = Model(with_optimizer(optimizer))
            m.ext[:variables] = Dict{Symbol,Dict}()
            m.ext[:constraints] = Dict{Symbol,Dict}()
            # Create decision variables
            variable_flow(m)
            variable_units_on(m)
            variable_units_available(m)
            variable_units_started_up(m)
            variable_units_shut_down(m)
            variable_trans(m)
            variable_stor_state(m)
            ## Create objective function
            objective_minimize_total_discounted_costs(m)
            # Add constraints
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
        # Run model
        printstyled("Solving model...\n"; bold=true)
        @time optimize!(m)
        status = termination_status(m)
        if status == MOI.OPTIMAL
            println("Optimal solution found")
            println("Objective function value: $(objective_value(m))")
            printstyled("Writing report...\n"; bold=true)
            write_report(m, url_out)
        end
        printstyled("Done.\n"; bold=true)
    end
    cleanup && notusing_spinedb(url_in)
    m
end


@catch_undef function write_report(m, default_url)
    reports = Dict()
    for (rpt, out) in report__output()
        out_var = get(m.ext[:variables], out.name, nothing)
        if out_var === nothing
            @warn "can't find output '$(out.name)'"
            continue
        end
        url = output_db_url(report=rpt)
        url === nothing && (url = default_url)
        url_reports = get!(reports, url, Dict())
        out_parameters = get!(url_reports, string(rpt.name), Dict())
        out_parameters[out.name] = d = Dict()
        for (key, val) in pack_trailing_dims(SpineModel.value(out_var))
            inds, vals = zip(val...)
            d[key] = to_database(TimeSeries(collect(inds), collect(vals), false, false))
        end
    end
    for (url, url_reports) in reports
        @show url
        for (report, out_parameters) in url_reports
            write_parameters(url; report=report, out_parameters...)
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
value(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => JuMP.value(v) for (k, v) in d if v isa JuMP.VariableRef)

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by a `String` showing their formulation.
"""
formulation(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d if v isa JuMP.ConstraintRef)
