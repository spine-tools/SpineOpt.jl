using CPLEX

include(raw"D:\Workspace\Spine\Timeslicetool_jl\run_timeslicetool.jl")

run_timeslicetool(raw"sqlite:///D:\Workspace\Spine\Spinetoolbox\projects\Ireland_A1B1_2\.spinetoolbox\items\timeslice_tool_test\casestudy_a1_b1_3.sqlite",
with_optimizer=optimizer_with_attributes(CPLEX.Optimizer, "CPX_PARAM_EPGAP" => 0.03))
