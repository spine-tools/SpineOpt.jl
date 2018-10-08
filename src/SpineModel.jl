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
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


module SpineModel

# data_io exports
export JuMP_all_out, JuMP_object
export @JuMPout, @JuMPout_suffix, @JuMPout_with_backup, @JuMPin

# equations export
export linear_JuMP_model
export variable_flow
export objective_minimize_production_cost
export constraint_use_of_capacity
export constraint_efficiency_definition
export constraint_commodity_balance

using PyCall
using JSON
using JuMP
using Clp
const db_api = PyNULL()

function __init__()
    copy!(db_api, pyimport("spinedatabase_api"))
end

# using SpineData
# using Missings
# using DataFrames
# using Query
# using ODBC
# using SQLite
# import DataValues: isna

include("helpers.jl")
include("data_io/Spine.jl")
include("data_io/util.jl")
include("data_io/other_formats.jl")
include("equations/core.jl")

end
