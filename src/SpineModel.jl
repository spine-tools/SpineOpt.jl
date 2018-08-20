module SpineModel

# data_io exports
export JuMP_all_out, JuMP_object
export @JuMPout, @JuMPout_suffix, @JuMPout_with_backup, @JuMPin

# equations export
export linear_JuMP_model
export flow
export trans
export minimize_production_cost
export capacity
export outinratio
export transloss
export transcapa
export constraint_efficiency_definition
export commodity_balance
export find_nodes
export find_connections
export get_all_connection_node_pairs
#export get_all_connection_node_pairs2
# export absolutebounds
export absolutebounds_UnitGroups
export get_units_of_unitgroup
export create_var_table
export get_com_node_unit

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

#defining relationship class names. Todo:adapt according nomencla
 node_unit_rel= "unit_node" #NodeUnitConnection_relationship_name
 node_commodity_rel= "node_commodity"
 unit_commidity_input_rel= "input_commodity"
 unit_commidity_output_rel= "output_commodity"
 node_connection_rel= "connection_node"
 unitgroup_unit_rel="unitgroup_unit"

include("helpers.jl")
include("data_io/Spine.jl")
include("data_io/get_results.jl")
include("data_io/util.jl")
include("data_io/other_formats.jl")
include("constraints/absolutebounds.jl")
include("constraints/capacity.jl")
include("constraints/commodity_balance.jl")
include("constraints/outinratio.jl")
include("constraints/transcapa.jl")
include("constraints/transloss.jl")
include("objective/minimize_production_cost.jl")
include("variables/flow.jl")
include("variables/trans.jl")



end
