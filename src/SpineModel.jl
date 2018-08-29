module SpineModel

# data_io exports
export JuMP_all_out

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
include("data_io/other_formats.jl")
include("equations/core.jl")

end
