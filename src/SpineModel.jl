module SpineModel

# data_io exports
export JuMP_all_out

# equations export
export linear_JuMP_model

#generate variables
export generate_variable_v_Flow
export generate_variable_v_Trans

#generate objecte
export objective_minimize_production_cost

# generate constraints
export constraint_FlowCapacity
export constraint_FixRatioOutputInputFlow
export constraint_MaxCumOutFlowBound
export constraint_TransLoss
export constraint_TransCap
export constraint_commodity_balance

#helper
export generate_CommoditiesNodesUnits
# export generate_ConnectionNodePairs

#export funcitons
export JuMP_variables_to_spine_db


#load packages
using PyCall
using JSON
using JuMP
using Clp
const db_api = PyNULL()

function __init__()
    copy!(db_api, pyimport("spinedatabase_api"))
end

include("helpers/helpers.jl")
include("helpers/generate_CommoditiesNodesUnits.jl")
# include("helpers/generate_ConnectionNodePairs.jl")

include("data_io/Spine.jl")
include("data_io/other_formats.jl")
include("data_io/get_results.jl")
include("data_io/result_to_spine.jl")


#defining relationship class names. Todo:adapt according nomencla
node_unit_rel= "unit_node"
node_commodity_rel= "node_commodity"
unit_commidity_input_rel= "input_commodity"
unit_commidity_output_rel= "output_commodity"
node_connection_rel= "connection_node"
unitgroup_unit_rel="unitgroup_unit"



include("variables/generate_variable_v_Flow.jl")
include("variables/generate_variable_v_Trans.jl")

include("objective/objective_minimize_production_cost.jl")

include("constraints/constraint_MaxCumOutFlowBound.jl")
include("constraints/constraint_FlowCapacity.jl")
include("constraints/constraint_commodity_balance.jl")
include("constraints/constraint_FixRatioOutputInputFlow.jl")
include("constraints/constraint_TransCap.jl")
include("constraints/constraint_TransLoss.jl")

end
