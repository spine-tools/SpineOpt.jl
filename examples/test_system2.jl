#= for now this is the main script from which the archetypes are created and the corresponding variables and constraints are called.
Moreover, the model is solved =#
using ASTinterpreter2
#initializing required packages
push!(LOAD_PATH, joinpath(@__DIR__,"..","src"))
using SpineModel
using SQLite
using JuMP
using Clp

p = joinpath(@__DIR__,"data","testsystem2_db.sqlite")
db = SQLite.DB(AbstractString(p))
sdo=SpineData.Spine_object(db)
jfo = JuMP_object(sdo)
 JuMP_all_out(db)




number_of_timesteps = jfo["number_of_timesteps"]["timer"]
time_discretisation = jfo["time_discretisation"]["timer"]
# was macht das?


## model:
m = Model(solver = ClpSolver())
flow = flow(m)
trans =trans(m,jfo,number_of_timesteps)

## objective function
minimize_production_cost(m,flow,number_of_timesteps)

## Technological constraints
# unit capacity
capacity(m,flow,number_of_timesteps) #define input vars, see how manuek did
# relationship output and input flows
##
outinratio(m,flow)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)

# transmission losses
transloss(m,trans)
# transmission capacity
transcapa(m,trans)
# needed: set of transmission units

## set of transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
commodity_balance(m,flow,trans)

## absolute bounds on commodities
# p(maxxuminflowbound)_ug1,Gas = 1e8 (unit group ug1 is chp and gasplant)
absolutebounds(m,flow)
# needed: set/group of unitgroup CHP and Gasplant

status = solve(m)
status == :Optimal && (flow_value = getvalue(flow))
println(m)
