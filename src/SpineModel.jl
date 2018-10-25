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
using Missings
using Dates
using CSV
const db_api = PyNULL()


function __init__()
    # Check Python version
    python = PyCall.pyprogramname
    @pyimport sys
    if sys.version_info[1] == 2
        error("""
Wrong Python version.
The PyCall module is currently configured to use the Python version at:

$python

which has version $pyversion. However, at least Python version 3.5 is required.

(PyCall is used by SpineModel to call the spinedatabase_api Python package from Julia,
in order to interact with Spine databases.)

The solution is to re-configure PyCall to use a Python
version 3.5 or higher: as explained in the PyCall manual,
set ENV["PYTHON"] to the path/name of the python
executable you want to use, run Pkg.build("PyCall"), re-launch Julia, and try using SpineModel again.
""")
    end
    try
        copy!(db_api, pyimport("spinedatabase_api"))
    catch e
        if isa(e, PyCall.PyError)
            repo_url = "https://github.com/Spine-project/Spine-Database-API.git#spinedatabase_api"
            info("""
Installing the spinedatabase_api Python package from $repo_url.
(spinedatabase_api is used by SpineModel to interact with Spine databases.)
""")
            run(`$python -m pip install git+$repo_url`)
            copy!(db_api, pyimport("spinedatabase_api"))
        end
    end
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
