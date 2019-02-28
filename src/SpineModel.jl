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
export generate_variable_state

# Export objecte
export objective_minimize_production_cost

# Export constraints
export constraint_flow_capacity
export constraint_fix_ratio_out_in_flow
export constraint_max_cum_in_flow_bound
export constraint_trans_loss
export constraint_trans_cap
export constraint_nodal_balance
export constraint_node_state_cyclic_bound

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
    println("Cheers!")
    try
        copy!(db_api, pyimport("spinedatabase_api"))
    catch e
        if isa(e, PyCall.PyError) && pyisinstance(e.val, py"ModuleNotFoundError")
            error(
"""
SpineModel couldn't find the required Python module `spinedatabase_api`.
Please make sure `spinedatabase_api` is in your Python path, restart your Julia session,
and try using SpineModel again.

NOTE: if you have already installed Spine Toolbox, then you can use the same `spinedatabase_api`
provided with it in SpineModel.
All you need to do is configure PyCall to use the same Python program as Spine Toolbox. Run

    ENV["PYTHON"] = "... path of the Python program you want ..."

followed by

    Pkg.build("PyCall")

If you haven't installed Spine Toolbox or don't want to reconfigure PyCall, then you can do the following:

1. Find out the path of the Python program used by PyCall. Run

    PyCall.pyprogramname

2. Install spinedatabase_api using that Python. Open a terminal (e.g. command prompt on Windows) and run

    python -m pip install git+https://github.com/Spine-project/Spine-Database-API.git

where 'python' is the path returned by `PyCall.pyprogramname`.
"""
            )
        else
            rethrow()
        end
        return
    end
    current_version = db_api[:__version__]
    current_version_split = parse.(Int, split(current_version, "."))
    required_version_split = parse.(Int, split(required_spinedatabase_api_version, "."))
    any(current_version_split .< required_version_split) && error(
"""
SpineModel couldn't find the required version of `spinedatabase_api`.
(Required version is $required_spinedatabase_api_version, whereas current is $current_version)
Please upgrade `spinedatabase_api` to $required_spinedatabase_api_version, restart your julia session,
and try using SpineModel again.

To upgrade `spinedatabase_api`, open a terminal (e.g. command prompt on Windows) and run

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
include("variables/generate_variable_state.jl")

include("objective/objective_minimize_production_cost.jl")

include("constraints/constraint_max_cum_in_flow_bound.jl")
include("constraints/constraint_flow_capacity.jl")
include("constraints/constraint_nodal_balance.jl")
include("constraints/constraint_node_state_cyclic_bound.jl")
include("constraints/constraint_fix_ratio_out_in_flow.jl")
include("constraints/constraint_trans_cap.jl")
include("constraints/constraint_trans_loss.jl")

end
