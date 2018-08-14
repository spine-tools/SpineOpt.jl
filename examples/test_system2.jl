#= for now this is the main script from which the archetypes are created and the corresponding variables and constraints are called.
Moreover, the model is solved =#
using ASTinterpreter2
#initializing required packages
push!(LOAD_PATH, joinpath(@__DIR__,"..","src"))
using SpineModel
using SQLite
using JuMP
using Clp
using Gadfly

p = joinpath(@__DIR__,"data","testsystem2_db.sqlite")
db = SQLite.DB(AbstractString(p))
sdo = SpineData.Spine_object(db)
jfo = JuMP_object(sdo)
 JuMP_all_out(db)


number_of_timesteps = jfo["number_of_timesteps"]["timer"]
time_discretisation = jfo["time_discretisation"]["timer"]

##
# model:
m = Model(solver = ClpSolver())

# setup decision variables
flow = flow(m)
trans =trans(m,number_of_timesteps,jfo)

# objective function
minimize_production_cost(m,flow,number_of_timesteps)

# Technological constraints
# unit capacity
capacity(m,flow,number_of_timesteps) #define input vars, see how manuek did
# relationship output and input flows
#
outinratio(m,flow,number_of_timesteps)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)
#
# transmission losses
transloss(m,trans,number_of_timesteps,jfo)
# transmission capacity
transcapa(m,trans,number_of_timesteps,jfo)
# needed: set of transmission units

# set of transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
commodity_balance(m,flow, trans,number_of_timesteps,jfo)

# absolute bounds on commodities
# p(maxxuminflowbound)_ug1,Gas = 1e8 (unit group ug1 is chp and gasplant)
absolutebounds_UnitGroups(m,flow, jfo, number_of_timesteps)
# needed: set/group of unitgroup CHP and Gasplant



status = solve(m)
status == :Optimal && (flow_value = getvalue(flow))
##
trans_value = getvalue(trans)
println(m)
##
m = 1
# function myelectricitynodes(flow_value,number_of_timesteps)
# for n in node()
#     if CommodityAffiliation(n) == "Electricity"
#      for u in units()
#          if NodeUnitConnection(n)
#              for t = 1:number_of_timesteps
#                  myelectricity_nodes[m,t] = flow_value["Electricity",n,u,t]
#              end
#         m = m+1
#         end
#     end
# end
# end
# end
#
# @enter myelectricitynodes
