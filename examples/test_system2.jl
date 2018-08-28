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



## model:
m = Model(solver = ClpSolver())

# setup decision variables
v_Flow = generate_v_Flow(m)
v_Trans =generate_v_Trans(m)

# objective function
minimize_production_cost(m,v_Flow)
#
# Technological constraints
# unit capacity
capacity(m,v_Flow) #define input vars, see how manuek did
# relationship output and input v_Flows
#
outinratio(m,v_Flow)
# needed: set of "conventional units"
# possibly split up in conventional and complex power plants (not really needed)
#
# v_Transmission losses
transloss(m,v_Trans)
# v_Transmission capacity
transcapa(m,v_Trans)
# needed: set of v_Transmission units

# set of v_Transmissions and actual units needed, differentiation "for all ... connected to"
# energy balance / commodity balance
commodity_balance(m,v_Flow, v_Trans)

# absolute bounds on commodities
# p(maxxuminv_Flowbound)_ug1,Gas = 1e8 (unit group ug1 is chp and gasplant)
absolutebounds_UnitGroups(m,v_Flow)
# needed: set/group of unitgroup CHP and Gasplant



status = solve(m)
status == :Optimal && (flow_value = getvalue(v_Flow))
trans_value = getvalue(v_Trans)
println(m)
