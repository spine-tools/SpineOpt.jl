#= for now this is the main script from which the archetypes are created and the corresponding variables and constraints are called.
Moreover, the model is solved =#

#initializing required packages
using SpineModel
using SQLite
using JuMP
using Clp

p = joinpath(@__DIR__, "testsystem2_db.sqlite")
db = SQLite.DB(AbstractString(p))
sdo=SpineData.Spine_object(db)
jfo = JuMP_object(sdo)
 JuMP_all_out(db)

number_of_timesteps = jfo["number_of_timesteps"]["timer"]
time_discretisation = jfo["time_discretisation"]["timer"]
# was macht das?

## model:
m = Model(solver = ClpSolver())
flow = variable_flow(m,number_of_timesteps)
trans = variable_trans(m,number_of_timesteps)

## objective function
obj_minimizecosts()

## Technological constraints
# unit capacity
constraint_capacity(m,flow) #define input vars, see how manuek did
# relationship output and input flows
constraint_outinratio(m,flow)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)

# transmission losses
constraint_transloss(m,trans)
# transmission capacity
constraint_transcapa(m,trans)
# needed: set of transmission units

## set of transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
constraint_commodity_balance(m,flow,trans)

## absolute bounds on commodities
# p(maxxuminflowbound)_ug1,Gas = 1e8 (unit group ug1 is chp and gasplant)
constraint_absolutebounds(m,flow)
# needed: set/group of unitgroup CHP and Gasplant

status = solve(m)
status == :Optimal && (flow_value = getvalue(flow))
println(m)
