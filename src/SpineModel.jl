module SpineModel

# data_io exports
export JuMP_all_out, JuMP_object
export @JuMPout, @JuMPout_suffix, @JuMPout_with_backup, @JuMPin

# equations export
export linear_JuMP_model

## generate tuples
export generate_ConnectionNodePairs
export generate_CommoditiesNodesUnits
export generate_UnitGroups

## generate variables
export generate_variable_v_Flow
export generate_variable_v_Trans

export objective_minimize_production_cost

## generate constraints
export constraint_FlowCapacity
export constraint_FixRatioOutputInputFlow
export constraint_MaxCumOutFlowBound
export constraint_TransLoss
export constraint_TransCap
export constraint_commodity_balance


## data handling (Steffen)
export create_var_table

## load packages
using SpineData
using Missings
using JuMP
using Clp
using DataFrames
using Query
using ODBC
using SQLite
using JSON
using Clp
import DataValues: isna
##
#defining relationship class names. Todo:adapt according nomencla
 node_unit_rel= "unit_node"
 node_commodity_rel= "node_commodity"
 unit_commidity_input_rel= "input_commodity"
 unit_commidity_output_rel= "output_commodity"
 node_connection_rel= "connection_node"
 unitgroup_unit_rel="unitgroup_unit"

include("helpers/suppress_err.jl")
include("data_io/Spine.jl")
include("data_io/get_results.jl")
include("data_io/util.jl")
include("data_io/other_formats.jl")

include("helpers/generate_UnitGroups.jl")
include("helpers/generate_ConnectionNodePairs.jl")
include("helpers/generate_CommoditiesNodesUnits.jl")

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
