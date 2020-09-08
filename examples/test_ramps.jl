using SpineOpt
using Gurobi

url_in = "sqlite:///C:\\Users\\u0122387\\Documents\\EUsysflex\\project_C2_convert\\.spinetoolbox\\items\\testing_ramp_down\\ramp_test.sqlite"
url_out = "sqlite:///C:\\Users\\u0122387\\Documents\\EUsysflex\\project_C2_convert\\.spinetoolbox\\items\\testing_ramp_down\\ramp_test_out.sqlite"

m = run_spineopt(url_in, url_out; with_optimizer=SpineOpt.JuMP.with_optimizer(Gurobi.Optimizer,MIPGap=0.001), cleanup=true)

# Show active variables and constraints
println("*** Active constraints: ***")
for key in keys(m.ext[:constraints])
    !isempty(m.ext[:constraints][key]) && println(key)
end
println("*** Active variables: ***")
for key in keys(m.ext[:variables])
    !isempty(m.ext[:variables][key]) && println(key)
end

SpineOpt.writing_modelfile(m;file_name = "ramp_log.so_model")
