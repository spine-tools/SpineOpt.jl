# for now this is the main script from which the archetypes are created and the corresponding variables and constraints are called.

# using ASTinterpreter2
using Revise
using SpineModel
using JuMP
using Clp
#init databsae file from toolbox and create convinient functions
db_url = "sqlite:///data/testsystem2_v2_multiD.sqlite"
JuMP_all_out(db_url)

## model:
m = Model(solver=ClpSolver())

# setup decision variables
flow = generate_variable_flow(m)
#
trans = generate_variable_trans(m)

# objective function
objective_minimize_production_cost(m, flow)#

# Technological constraints
# unit capacity
constraint_FlowCapacity(m, flow)

##
constraint_FixRatioOutputInputFlow(m, flow)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)
#
# v_Transmission losses
constraint_TransLoss(m, trans)
# v_Transmission capacity
constraint_TransCap(m, trans)
# needed: set of v_Transmission units

# set of v_Transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
constraint_commodity_balance(m, flow, trans)

# absolute bounds on commodities
constraint_MaxCumOutFlowBound(m, flow)
# needed: set/group of unitgroup CHP and Gasplant

status = solve(m)
status == :Optimal && (flow_value = getvalue(flow))
trans_value = getvalue(trans)
println(m)
