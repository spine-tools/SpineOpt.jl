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
function run_spinemodel(url::String; optimizer=Cbc.Optimizer, cleanup=true, extend=m -> nothing, rolling=nothing)
    run_spinemodel(url, url; optimizer=optimizer, cleanup=cleanup, extend=extend, rolling=rolling)
end

"""
    run_spinemodel(url_in, url_out; <keyword arguments>)

Run the Spine model from `url_in` and write report to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Keyword arguments

**`optimizer=Cbc.Optimizer`** is the constructor of the optimizer used for building and solving the model.

**`cleanup=true`** tells [`run_spinemodel`](@ref) whether or not convenience function callables should be
set to `nothing` after completion.

**`extend=m -> nothing`** is a function for extending the model. [`run_spinemodel`](@ref) calls this function with
the internal `JuMP.Model` object before calling `JuMP.optimize!`.

**`rolling=nothing`** is the name of a rolling object.
"""
function run_spinemodel(
        url_in::String,
        url_out::String;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m -> nothing,
        rolling=nothing)
    printstyled("Creating convenience functions...\n"; bold=true)
    @time using_spinedb(url_in, @__MODULE__; upgrade=true)
    res_flow = []
    res_trans =[]
    res_units_on = []
    key_dict = Dict()
    val_dict = Dict()
    new_dict = Dict()
    for (rpt, out) in report__output()
        key_dict[out.name] = []
        val_dict[out.name] = []
        new_dict[out.name] = []
    end
    for (k, block_time_slices) in enumerate(window_block_time_slices(rolling))
        printstyled("Window $k\n"; bold=true, color=:underline)
        printstyled("Creating temporal structure...\n"; bold=true)
        @time begin
            generate_time_slice(block_time_slices)
            generate_time_slice_relationships()
        end
################WIP: to do for all variable not only fix_flow! but also fix_trans, TODO: write to d.b. in the end
#### flow variable:
        if !isempty(res_flow)
            let i=0
                for ((u,n,c,d) , result_values) in pack_trailing_dims(SpineModel.value(res_flow))
                    i += 1
                    if isempty(result_values) # check if there's actually results for this variable
                        continue
                    else
                        if (unit=u, node =n , direction =d) in fix_flow.classes[1].relationships #if the relationship already exists
                            index = findfirst(x ->x == (unit=u, node =n , direction =d), fix_flow.classes[1].relationships) # find position in array
                            for j = 1:length(result_values) # go through all the results of this relationship
                                positions  = findall(x -> x == first(result_values[j]).t.start, ((((fix_flow.classes[1]).values[index]).fix_flow).value).indexes)
                                if isempty(positions)#this means: relationship already exist, but not for this timestep
                                    if first(result_values[j]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                        # @show "this timeslice $(first(result_values[j]).t) -  rel already exist, adding new values"
                                        push!(((((fix_flow.classes[1]).values[index]).fix_flow).value).indexes,(first(result_values[j]).t).start)
                                        push!(((((fix_flow.classes[1]).values[index]).fix_flow).value).values, last(result_values[j]))
                                        # @show ((((fix_flow.classes[1]).values[index]).fix_flow).value)
                                    end
                                else #this means: relationship already exist, and value already for this timestep -> replace it
                                    if first(result_values[j]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                        # @show "this timeslice $(first(result_values[j]).t) -  rel already exist, overwriting values"
                                        ((((fix_flow.classes[1]).values[index]).fix_flow).value).values[positions] =  last(result_values[j])
                                    end
                                end
                            end
                        else
                            # @show "now this"
                            for res_val_length = 1:length(result_values)
                                index2 = findfirst(x ->x == (unit=u, node =n , direction =d), fix_flow.classes[1].relationships)
                                if first(result_values[res_val_length]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                    if index2 == nothing
                                        push!(fix_flow.classes[1].relationships,(unit = u,node = n,direction = d))
                                        push!(fix_flow.classes[1].values,(fix_flow = SpineInterface.TimeSeriesCallable{Array{DateTime,1},Float64}(TimeSeries(DateTime[first(result_values[res_val_length]).t.start], [last(result_values[res_val_length])], false, false)),))
                                    else
                                        push!(((((fix_flow.classes[1]).values[index2]).fix_flow).value).indexes,(first(result_values[res_val_length]).t).start)
                                        push!(((((fix_flow.classes[1]).values[index2]).fix_flow).value).values, last(result_values[res_val_length]))
                                    end
                            end
                        end
                        end #else if (relationship exists or not)
                    end #end else if  (result is empty or nor)
                end #for
            end #let i
        end # end if k>1
#### trans variable:
        if !isempty(res_trans)
            let i=0
                for ((conn,n,c,d) , result_values) in pack_trailing_dims(SpineModel.value(res_trans))
                    i += 1
                    if isempty(result_values) # check if there's actually results for this variable
                        continue
                    else
                        if (connection=conn, node =n , direction =d) in fix_trans.classes[1].relationships #if the relationship already exists
                            index = findfirst(x ->x == (connection=conn, node =n , direction =d), fix_trans.classes[1].relationships) # find position in array
                            for j = 1:length(result_values) # go through all the results of this relationship
                                positions  = findall(x -> x == first(result_values[j]).t.start, ((((fix_trans.classes[1]).values[index]).fix_trans).value).indexes)
                                if isempty(positions)#this means: relationship already exist, but not for this timestep
                                    if first(result_values[j]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                        # @show "this timeslice $(first(result_values[j]).t) -  rel already exist, adding new values"
                                        push!(((((fix_trans.classes[1]).values[index]).fix_trans).value).indexes,(first(result_values[j]).t).start)
                                        push!(((((fix_trans.classes[1]).values[index]).fix_trans).value).values, last(result_values[j]))
                                    end
                                else #this means: relationship already exist, and value already for this timestep -> replace it
                                    if first(result_values[j]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                        # @show "this timeslice $(first(result_values[j]).t) -  rel already exist, overwriting values"
                                        ((((fix_trans.classes[1]).values[index]).fix_trans).value).values[positions] =  last(result_values[j])
                                    end
                                end
                            end
                        else
                            # @show "now this"
                            for res_val_length = 1:length(result_values)
                                index2 = findfirst(x ->x == (connection=conn, node =n , direction =d), fix_trans.classes[1].relationships)
                                if first(result_values[res_val_length]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                    if index2 == nothing
                                        push!(fix_trans.classes[1].relationships,(connection=conn,node = n,direction = d))
                                        push!(fix_trans.classes[1].values,(fix_trans = SpineInterface.TimeSeriesCallable{Array{DateTime,1},Float64}(TimeSeries(DateTime[first(result_values[res_val_length]).t.start], [last(result_values[res_val_length])], false, false)),))
                                    else
                                        push!(((((fix_trans.classes[1]).values[index2]).fix_trans).value).indexes,(first(result_values[res_val_length]).t).start)
                                        push!(((((fix_trans.classes[1]).values[index2]).fix_trans).value).values, last(result_values[res_val_length]))
                                    end
                            end
                        end
                        end #else if (relationship exists or not)
                    end #end else if  (result is empty or nor)
                end #for
            end #let i
        end # end if k>1

#### units_on variable:
        if !isempty(res_units_on)
            let i=0
                for ((u,) , result_values) in pack_trailing_dims(SpineModel.value(res_units_on))
                    i += 1
                    if isempty(result_values) # check if there's actually results for this variable
                        continue
                    else
                        if (fix=Object("fix"), unit = u) in fix_unit_on.classes[1].relationships #if the relationship already exists
                            index = findfirst(x ->x == (fix=Object("fix"), unit = u), fix_unit_on.classes[1].relationships) # find position in array
                            for j = 1:length(result_values) # go through all the results of this relationship
                                positions  = findall(x -> x == first(result_values[j]).t.start, ((((fix_unit_on.classes[1]).values[index]).fix_unit_on).value).indexes)
                                if isempty(positions)#this means: relationship already exist, but not for this timestep
                                    if first(result_values[j]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                        # @show "this timeslice $(first(result_values[j]).t) -  rel already exist, adding new values"
                                        push!(((((fix_unit_on.classes[1]).values[index]).fix_unit_on).value).indexes,(first(result_values[j]).t).start)
                                        push!(((((fix_unit_on.classes[1]).values[index]).fix_unit_on).value).values, last(result_values[j]))
                                    end
                                else #this means: relationship already exist, and value already for this timestep -> replace it
                                    if first(result_values[j]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                        # @show "this timeslice $(first(result_values[j]).t) -  rel already exist, overwriting values"
                                        ((((fix_unit_on.classes[1]).values[index]).fix_unit_on).value).values[positions] =  last(result_values[j])
                                    end
                                end
                            end
                        else
                            # @show "now this"
                            for res_val_length = 1:length(result_values)
                                index2 = findfirst(x ->x == (fix=Object("fix"), unit = u), fix_unit_on.classes[1].relationships)
                                if first(result_values[res_val_length]).t in block_time_slices[Object("DA_quarterly-hours_initial_condition")] ##TODO: hard coded, how to make this universal?
                                    if index2 == nothing
                                        push!(fix_unit_on.classes[1].relationships,(fix=Object("fix"), unit = u))
                                        push!(fix_unit_on.classes[1].values,(fix_unit_on = SpineInterface.TimeSeriesCallable{Array{DateTime,1},Float64}(TimeSeries(DateTime[first(result_values[res_val_length]).t.start], [last(result_values[res_val_length])], false, false)),))
                                    else
                                        push!(((((fix_unit_on.classes[1]).values[index2]).fix_unit_on).value).indexes,(first(result_values[res_val_length]).t).start)
                                        push!(((((fix_unit_on.classes[1]).values[index2]).fix_unit_on).value).values, last(result_values[res_val_length]))
                                    end
                            end
                        end
                        end #else if (relationship exists or not)
                    end #end else if  (result is empty or nor)
                end #for
            end #let i
        end # end if k>1
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
            write_report(m, url_out,key_dict, val_dict, new_dict,false)
        else
            break
        end
        printstyled("Done.\n"; bold=true)
        res_flow = get(m.ext[:variables], Object("flow").name, nothing) # this is required for the enxt loop
        res_trans = get(m.ext[:variables], Object("trans").name, nothing) # this is required for the enxt loop
        res_units_on = get(m.ext[:variables], Object("units_on").name, nothing) # this is required for the enxt loop
    end
    write_report(m, url_out,key_dict, val_dict, new_dict,true)
    # cleanup && notusing_spinedb(url_in, @__MODULE__)
end


function write_report(m, default_url, key_dict, val_dict, new_dict,final) ####### always have a look -> these value dicts will need a key to identify out put variable...
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
        out_parameters = get!(url_reports, rpt.name, Dict())
        out_parameters[out.name] = d = Dict()
        # resolve marge:
        # for (key, val) in pack_trailing_dims(value(out_var))
        #     inds, vals = zip(val...)
        #     d[key] = TimeSeries(collect(inds), collect(vals), false, false)
        for (key, val) in pack_trailing_dims(SpineModel.value(out_var)) ### key: relationship (u,n,c,d); val: Array of tuples as in (t,value)
            if key in key_dict[out.name] ### for the case that there is already the key existing/ rel already in output vars
                pos = findfirst(x -> x == key, key_dict[out.name]) ### look up position
                for i = 1:length(val) ### go through all results of this run (for this relationship)
                    was_found = false
                    for k = 1:length(val_dict[out.name][pos]) ### go through all already existing results
                         if first(val[i]).t == (first(val_dict[out.name][pos][k]).t) ### if there is already a value for this timeslice
                             val_dict[out.name][pos][k] = val[i] ### reassign to new value
                             was_found = true
                        end
                    end
                    if !was_found
                        push!(val_dict[out.name][pos],val[i]) ### else push complet results for this relitonhsip
                    end
                end
            else ## rel does not exist yet, so push to dict
                push!(key_dict[out.name],key)
                push!(val_dict[out.name],val)
            end
        end
        new_dict[out.name] = []
        for i = 1:length(val_dict[out.name])
            push!(new_dict[out.name],(key_dict[out.name][i],val_dict[out.name][i]))
        end ### rather ineffieceint, does the job for now
        if final == true
            for (key, val) in new_dict[out.name]
                inds_dict = Array{NamedTuple{(:t,),Tuple{TimeSlice}},1}()
                vals_dict= []
                for j = 1:length(val)
                    push!(vals_dict,last(val[j]))
                    push!(inds_dict,val[j][1])
                end
                    TimeSeries(inds_dict, vals_dict, false, false)
                    d[key] = to_database(TimeSeries(inds_dict, vals_dict, false, false))
            end ### write results to database
        end
    end
    # see merge
    # for (url, url_reports) in reports
    #     for (report, out_parameters) in url_reports
    #         write_parameters(out_parameters, url; report=string(report))
    if final == true
        for (url, url_reports) in reports
            for (report, out_parameters) in url_reports
                write_parameters(url; report=report, out_parameters...)
            end
        end
    end
    key_dict,val_dict,new_dict
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
value(d::Dict{K,V}) where {K,V} = Dict{K,Any}(k => v isa JuMP.VariableRef ? JuMP.value(v) : v for (k, v) in d)

"""
    formulation(d::Dict)

An equivalent dictionary where `JuMP.ConstraintRef` values are replaced by a `String` showing their formulation.
"""
formulation(d::Dict{K,JuMP.ConstraintRef}) where {K} = Dict{K,Any}(k => sprint(show, v) for (k, v) in d)
