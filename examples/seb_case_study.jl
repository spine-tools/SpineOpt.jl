using SpineOpt
using Gurobi

db_url_in = "sqlite:///$(@__DIR__)/../../case_study_b2.sqlite"
db_url_out = "sqlite:///$(@__DIR__)/../../case_study_b2_out.sqlite"
m = run_spineopt(db_url_in, db_url_out;mip_solver=Gurobi.Optimizer(), cleanup=false, log_level=3,use_direct_model=true)
# Show active variables and constraints
println("*** Active constraints: ***")
for key in keys(m.ext[:constraints])
    !isempty(m.ext[:constraints][key]) && println(key)
end
println("*** Active variables: ***")
for key in keys(m.ext[:variables])
    !isempty(m.ext[:variables][key]) && println(key)
end
