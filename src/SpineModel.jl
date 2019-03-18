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
# __precompile__()

module SpineModel
# Data_io exports
export JuMP_all_out
export JuMP_results_to_spine_db!

# Export model
export linear_JuMP_model

# Export variables
export generate_variable_flow
export generate_variable_trans
export generate_variable_stor_state

# Export objecte
export objective_minimize_production_cost

# Export constraints
export constraint_flow_capacity
export constraint_fix_ratio_out_in_flow
export constraint_max_cum_in_flow_bound
#export constraint_trans_loss
export constraint_fix_ratio_out_in_trans
export constraint_trans_capacity
export constraint_nodal_balance
export constraint_stor_state
export constraint_stor_capacity

export @butcher

#load packages
using PyCall
using JSON
using JuMP
using Clp
using DataFrames
# using Missings
using Base.Dates
using CSV
const db_api = PyNULL()
const required_spinedatabase_api_version = "0.0.8"

function __init__()
    try
        copy!(db_api, pyimport("spinedatabase_api"))
    catch e
        if isa(e, PyCall.PyError)
            println(e)
            error(
"""
SpineModel couldn't import the required spinedatabase_api python module.
Please make sure spinedatabase_api is in your python path, restart your julia session, and load SpineModel again.

Note: if you have already installed spinedatabase_api for Spine Toolbox, you can also use it for SpineModel.
All you need to do is configure PyCall to use the same python Spine Toolbox is using. Run

    ENV["PYTHON"] = "... path of the python program you want ..."

followed by

    Pkg.build("PyCall")

If you haven't installed spinedatabase_api or don't want to reconfigure PyCall, then you need to do the following:

1. Find out the path of the python program used by PyCall. Run

    PyCall.pyprogramname

2. Install spinedatabase_api using that python. Open a terminal (e.g. command prompt on Windows) and run

    python -m pip install git+https://github.com/Spine-project/Spine-Database-API.git

where 'python' is the path returned by `PyCall.pyprogramname`.
"""
            )
        end
        return
    end
    current_version = db_api[:__version__]
    current_version_split = parse.(Int, split(current_version, "."))
    required_version_split = parse.(Int, split(required_spinedatabase_api_version, "."))
    any(current_version_split .< required_version_split) && error(
"""
SpineModel couldn't find the required spinedatabase_api version.
(Required version is $required_spinedatabase_api_version, whereas current is $current_version)
Please upgrade spinedatabase_api to $required_spinedatabase_api_version, restart your julia session,
and load SpineModel again.

To upgrade spinedatabase_api, open a terminal (e.g. command prompt on Windows) and run

    pip install --upgrade git+https://github.com/Spine-project/Spine-Database-API.git
"""
    )
end
###temporals
using Base.Dates

##creating time_slices struct
struct time_slices
           name::String
           Start_Date::DateTime
           End_Date::DateTime
           duration::Float64
end
### easy readout of start_end_times
function start_date(k::Symbol)
    start_date = Dict()
    start_date = DateTime(start_datetime()[k][1],(start_datetime()[k][2]),
                                (start_datetime()[k][3]),(start_datetime()[k][4]),
                                    (start_datetime()[k][5]),    (start_datetime()[k][6]))
    return start_date
end
##
function end_date(k::Symbol)
    end_date = Dict()
    end_date = DateTime(end_datetime()[k][1],(end_datetime()[k][2]),
                                (end_datetime()[k][3]),(end_datetime()[k][4]),
                                    (end_datetime()[k][5]),    (end_datetime()[k][6]))
    return end_date
end
###
function time_slicemap()
    time_slicemap = Dict()
    time_slices_tempblock = Dict()
### time_slice_duration()
    for k in temporal_block()
        time_slices_tempblock[k] = Dict()
            ## unterscheidung ob duration einzel wert ist oder mehrere
            if length(time_slice_duration()[k])==1
                test = collect(start_date(k):Minute(time_slice_duration()[k][1]):end_date(k))
                #@show length(test)
                for i = 1: length(test)
                if i == 1
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
                time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                else
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
                time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                end
                end
            else
                for i = 1: length(time_slice_duration()[k])
                    if i == 1
                    time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][i]),Minute(time_slice_duration()[k][i]))
                    time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                    else
                    time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][i]),+Minute(time_slice_duration()[k][i]))
                    time_slices_tempblock[k]["$(k)_t_$(i)"]  = "$(k)_t_$(i)"
                    end
                end
            end
    end
    return time_slicemap
end
function time_slices_tempblock()
    time_slicemap = Dict()
    time_slices_tempblock = Dict()
### time_slice_duration()
    for k in temporal_block()
        time_slices_tempblock[k] = Dict()
            ## unterscheidung ob duration einzel wert ist oder mehrere
            if length(time_slice_duration()[k])==1
                test = collect(start_date(k):Minute(time_slice_duration()[k][1]):end_date(k))
                #@show length(test)
                for i = 1: length(test)
                if i == 1
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
                time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                else
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
                time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                end
                end
            else
                for i = 1: length(time_slice_duration()[k])
                    if i == 1
                    time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][i]),Minute(time_slice_duration()[k][i]))
                    time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                    else
                    time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][i]),+Minute(time_slice_duration()[k][i]))
                    time_slices_tempblock[k]["$(k)_t_$(i)"]  = "$(k)_t_$(i)"
                    end
                end
            end
    end
    return time_slices_tempblock
end
###
function t_in_t()
t_in_t = Dict()
t_above_t = Dict()
for i in keys(time_slicemap())
    t_in_t[i] = Dict()
    for j in keys(time_slicemap())
        t_above_t[j] = Dict()
        if time_slicemap()[i].Start_Date >= time_slicemap()[j].Start_Date && time_slicemap()[i].End_Date <= time_slicemap()[j].End_Date
            if i != j
            t_in_t[i][j] = [time_slicemap()[i] , time_slicemap()[j]]
            t_above_t[j][i] = [time_slicemap()[j] , time_slicemap()[i]]
            end
        end
    end
end
return t_in_t
end
###
#hier2
function t_in_t_excl(j::String)
t_in_t = Dict()
for i in keys(time_slicemap())
        if time_slicemap()[i].Start_Date >= time_slicemap()[j].Start_Date && time_slicemap()[i].End_Date <= time_slicemap()[j].End_Date
            if i != j
            t_in_t[i] = Dict()
            t_in_t[i] = [time_slicemap()[i] , time_slicemap()[j]]
            end
        end
end
return t_in_t
end
function t_in_t(j::String)
t_in_t = Dict()
for i in keys(time_slicemap())
        if time_slicemap()[i].Start_Date >= time_slicemap()[j].Start_Date && time_slicemap()[i].End_Date <= time_slicemap()[j].End_Date
            t_in_t[i] = Dict()
            t_in_t[i] = [time_slicemap()[i] , time_slicemap()[j]]
        end
end
return t_in_t
end
# #hier2
###

export start_date
export end_date
export time_slicemap
export time_slices_tempblock
export t_in_t
export t_in_t_excl
###

include("helpers/helpers.jl")

include("data_io/from_spine.jl")
include("data_io/to_spine.jl")
# include("data_io/other_formats.jl")
# include("data_io/get_results.jl")

include("variables/generate_variable_flow.jl")
include("variables/generate_variable_trans.jl")
include("variables/generate_variable_stor_state.jl")

include("objective/objective_minimize_production_cost.jl")

include("constraints/constraint_max_cum_in_flow_bound.jl")
include("constraints/constraint_flow_capacity.jl")
include("constraints/constraint_nodal_balance.jl")
include("constraints/constraint_fix_ratio_out_in_flow.jl")
include("constraints/constraint_fix_ratio_out_in_trans.jl")
include("constraints/constraint_trans_capacity.jl")
#include("constraints/constraint_trans_loss.jl")
include("constraints/constraint_stor_capacity.jl")
include("constraints/constraint_stor_state.jl")

end
