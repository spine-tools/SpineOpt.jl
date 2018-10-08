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

# Data_io exports
export JuMP_all_out
export JuMP_results_to_spine_db!

# Export model
export linear_JuMP_model

# Export variables
export generate_variable_flow
export generate_variable_trans

# Export objecte
export objective_minimize_production_cost

# Export constraints
export constraint_flow_capacity
export constraint_fix_ratio_out_in_flow
export constraint_max_cum_in_flow_bound
export constraint_trans_loss
export constraint_trans_cap
export constraint_nodal_balance

#load packages
using PyCall
using JSON
using JuMP
using Clp
using DataFrames
using Missings
using Dates
using CSV
const db_api = PyNULL()

function __init__()
    copy!(db_api, pyimport("spinedatabase_api"))
end

include("helpers/helpers.jl")

include("data_io/from_spine.jl")
include("data_io/to_spine.jl")
# include("data_io/other_formats.jl")
# include("data_io/get_results.jl")

include("variables/generate_variable_flow.jl")
include("variables/generate_variable_trans.jl")

include("objective/objective_minimize_production_cost.jl")

include("constraints/constraint_max_cum_in_flow_bound.jl")
include("constraints/constraint_flow_capacity.jl")
include("constraints/constraint_nodal_balance.jl")
include("constraints/constraint_fix_ratio_out_in_flow.jl")
include("constraints/constraint_trans_cap.jl")
include("constraints/constraint_trans_loss.jl")

end
