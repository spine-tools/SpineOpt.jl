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

# Export objecte
export objective_minimize_production_cost

# Export constraints
export constraint_flow_capacity
export constraint_fix_ratio_out_in_flow
export constraint_max_cum_in_flow_bound
export constraint_trans_loss
export constraint_trans_cap
export constraint_nodal_balance

export @butcher

#load packages
using PyCall
using JSON
using JuMP
using Clp
using DataFrames
using Dates
using Suppressor
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
