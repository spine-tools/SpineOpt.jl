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
function run_spinemodel(url::String; optimizer=Cbc.Optimizer, cleanup=true, extend=m->nothing, rolling=:default)
    run_spinemodel(url, url; optimizer=optimizer, cleanup=cleanup, extend=extend, rolling=rolling)
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
        rolling=nothing)
    printstyled("Creating convenience functions...\n"; bold=true)
    @time using_spinedb(url_in, @__MODULE__; upgrade=true)
    let out_var = Dict()
    for (k, block_time_slices) in enumerate(window_block_time_slices(rolling))
        printstyled("Window $k\n"; bold=true, color=:underline)
        printstyled("Creating temporal structure...\n"; bold=true)
        @time begin
            generate_time_slice(block_time_slices)
            generate_time_slice_relationships()
        end
################WIP: to do for all variable not only fix_flow!
        if !isempty(out_var)
            let i=0
            for ((u,n,c,d) , result_values) in pack_trailing_dims(SpineModel.value(out_var))
              i += 1
                if isempty(result_values) # check if there's actually results for this variable
                  continue
                else
                    @show typeof(u)
                    if (unit=u, node =n , direction =d) in fix_flow.classes[1].relationships #if the relationship already exists
                        @show "this is a relationship"
                    index = findfirst(x ->x == (unit=u, node =n , direction =d), fix_flow.classes[1].relationships) # find position in array
                       for j = 1:length(result_values) # go through all the results of this relationship
                           @show result_values[j]
                          positions  = findall(x -> x == first(result_values[j]).t.start, ((((fix_flow.classes[1]).values[index]).fix_flow).value).indexes)
                         if isempty(positions)#this means: relationship already exist, but not for this timestep
                           push!(((((fix_flow.classes[1]).values[index]).fix_flow).value).indexes,(first(result_values[j]).t).start)
                           push!(((((fix_flow.classes[1]).values[index]).fix_flow).value).values, last(result_values[j]))
                       else #this means: relationship already exist, and value already for this timestep -> replace it
                            ((((fix_flow.classes[1]).values[index]).fix_flow).value).values[positions] =  last(result_values[j])
                       end
                     end
                   else
                     push!(fix_flow.classes[1].relationships,(unit = u,node = n,direction = d))
                     index2 = findfirst(x ->x == (unit=u, node =n , direction =d), fix_flow.classes[1].relationships) #...or just go to the end
                     push!(fix_flow.classes[1].values,(fix_flow = SpineInterface.TimeSeriesCallable{Array{DateTime,1},Float64}(TimeSeries(DateTime[first(result_values[1]).t.start], [last(result_values[1])], false, false)),))
                    #  push!(fix_flow.classes[1].values,(fix_flow = SpineInterface.TimeSeriesCallable{TimeSlice,Float64}(TimeSeries([first(result_values[1]).t], [last(result_values[1])], false, false)),))
                     for i = 2:length(result_values)
                     # TimeSeries{Array{Dates.DateTime,1},Float64}(Dates.DateTime[2000-01-01T00:00:00, 2000-01-01T01:00:00, 2030-01-03T02:00:00], [0.0, 0.0, 147.0], false, false)
                     push!(((((fix_flow.classes[1]).values[index2]).fix_flow).value).indexes,(first(result_values[i]).t).start)
                     push!(((((fix_flow.classes[1]).values[index2]).fix_flow).value).values, last(result_values[i]))
                      end
                   end
                 end
               end
            end
        end
#####################WIP
        ### what if relationship doesn't exist yet?
        ### commodity_node -> node
        ### after time_slices_bock have been created -> push fix_flow
        # but only if t in initial_condition_window
        # for u in unit()
        # update!(fix_flow,u,value_flow)
        # end
        # for con in connection()
        # update!(fix_trans,conn,value_trans)
        # end
        printstyled("Initializing model...\n"; bold=true)
        @time begin
            global m = Model(with_optimizer(optimizer))
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
            # Create objective function
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
        if status == MOI.OPTIMAL
            println("Optimal solution found")
            println("Objective function value: $(objective_value(m))")
            printstyled("Writing report...\n"; bold=true)
            write_report(m, url_out)
        end
        printstyled("Done.\n"; bold=true)
        out_var = get(m.ext[:variables], Object("flow").name, nothing)
        # @show out_var
        @show time_slice
        #here results need to be passed to global workspace
    end
    # cleanup && notusing_spinedb(url_in, @__MODULE__)
    m
end #let out_Var
end


function write_report(m, default_url)
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
