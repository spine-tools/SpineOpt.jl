""""
test_system2.jl is a skript to run the second testsystem
while including the corresponding database testsystem2_v2_multiD.sqlite and
    the necessary equations
"""

## load required packaes
using Revise
using SpineModel
using JuMP
using Clp

## init databsae file from toolbox and create convinient functions
db_url = "sqlite:///examples/data/testsystem2_v2_multiD.sqlite"
JuMP_all_out(db_url)

## model:
m = Model(solver=ClpSolver())

## setup decision variables
flow = generate_variable_flow(m)
#
trans = generate_variable_trans(m)

## objective function
objective_minimize_production_cost(m, flow)#

## Technological constraints

# unit capacity
constraint_flow_capacity(m, flow)

# ratio of in/out flows of a unit
constraint_fix_ratio_out_in_flow(m, flow)

# transmission losses
constraint_trans_loss(m, trans)

# transmission line capacity
constraint_trans_cap(m, trans)

# nodal balance
constraint_nodal_balance(m, flow, trans)

# absolute bounds on commodities
constraint_max_cum_out_flow_bound(m, flow)
# needed: set/group of unitgroup CHP and Gasplant

status = solve(m)
status == :Optimal && (flow_value = getvalue(flow))
trans_value = getvalue(trans)
println(m)
