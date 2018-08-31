# for now this is the main script from which the archetypes are created and the corresponding variables and constraints are called.

# using ASTinterpreter2
using SpineModel
using JuMP
using Clp
#init databsae file from toolbox and create convinient functions
db_url = "sqlite:///examples//data//testsystem2_v2_multiD.sqlite"
JuMP_all_out(db_url)

## model:
m = Model(solver = ClpSolver())

# setup decision variables
v_Flow = generate_variable_v_Flow(m)
#
v_Trans = generate_variable_v_Trans(m)

# objective function
objective_minimize_production_cost(m, v_Flow)#

# Technological constraints
# unit capacity
constraint_FlowCapacity(m, v_Flow)

##
constraint_FixRatioOutputInputFlow(m,v_Flow)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)
#
# v_Transmission losses
constraint_TransLoss(m,v_Trans)
# v_Transmission capacity
constraint_TransCap(m,v_Trans)
# needed: set of v_Transmission units

# set of v_Transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
constraint_commodity_balance(m,v_Flow, v_Trans)

# absolute bounds on commodities
constraint_MaxCumOutFlowBound(m,v_Flow)
# needed: set/group of unitgroup CHP and Gasplant



status = solve(m)
status == :Optimal && (flow_value = getvalue(v_Flow))
trans_value = getvalue(v_Trans)
println(m)
