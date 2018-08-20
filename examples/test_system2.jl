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
sdo = SpineData.Spine_object(db)
jfo = JuMP_object(sdo)
JuMP_all_out(db)


number_of_timesteps = jfo["number_of_timesteps"]["timer"]
time_discretisation = jfo["time_discretisation"]["timer"]


# model:
m = Model(solver = ClpSolver())

# setup decision variables
var_flow = flow(m)
var_trans =trans(m,number_of_timesteps)

# objective function
minimize_production_cost(m,var_flow,number_of_timesteps)
#
# Technological constraints
# unit capacity
capacity(m,var_flow,number_of_timesteps) #define input vars, see how manuek did
# relationship output and input var_flows
#
outinratio(m,var_flow,number_of_timesteps)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)
#
# var_transmission losses
transloss(m,var_trans,number_of_timesteps)
# var_transmission capacity
transcapa(m,var_trans,number_of_timesteps)
# needed: set of var_transmission units

# set of var_transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
commodity_balance(m,var_flow, var_trans,number_of_timesteps)

# absolute bounds on commodities
# p(maxxuminvar_flowbound)_ug1,Gas = 1e8 (unit group ug1 is chp and gasplant)
absolutebounds_UnitGroups(m,var_flow, number_of_timesteps)
# needed: set/group of unitgroup CHP and Gasplant



status = solve(m)
status == :Optimal && (flow_value = getvalue(var_flow))
trans_value = getvalue(var_trans)
println(m)
