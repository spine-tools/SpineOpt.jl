using SpineModel
using SQLite
using JuMP
using Clp


db = SQLite.DB("simple_test_system.sqlite")
jfo = JuMP_object(db)

m = linear_JuMP_model()
flow = variable_flow(m)
objective_minimize_production_cost(m, flow)
constraint_use_of_capacity(m, flow)
constraint_efficiency_definition(m, flow)
constraint_commodity_balance(m, flow)
status = solve(m)
status == :Optimal && (flow_value = getvalue(flow))
println(m)
