module SpineModel

# data_io exports
export JuMP_all_out
export JuMP_variables_to_spine_db

# equations export
export linear_JuMP_model

# Export variables
export generate_variable_flow
export generate_variable_trans

# Export objecte
export objective_minimize_production_cost

# Export constraints
export constraint_flow_capacity
export constraint_fix_ratio_out_in_flow
export constraint_max_cum_out_flow_bound
export constraint_trans_loss
export constraint_trans_cap
export constraint_commodity_balance

#load packages
using PyCall
using JSON
using JuMP
using Clp
using DataFrames
using Missings
using CSV
const db_api = PyNULL()

function __init__()
    copy!(db_api, pyimport("spinedatabase_api"))
end

include("helpers/helpers.jl")

include("data_io/Spine.jl")
include("data_io/other_formats.jl")
include("data_io/get_results.jl")
include("data_io/result_to_spine.jl")

include("variables/generate_variable_flow.jl")
include("variables/generate_variable_trans.jl")

include("objective/objective_minimize_production_cost.jl")

include("constraints/constraint_max_cum_out_flow_bound.jl")
include("constraints/constraint_flow_capacity.jl")
include("constraints/constraint_commodity_balance.jl")
include("constraints/constraint_fix_ratio_out_in_flow.jl")
include("constraints/constraint_trans_cap.jl")
include("constraints/constraint_trans_loss.jl")

end
