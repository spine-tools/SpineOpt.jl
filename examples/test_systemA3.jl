using Revise
using SpineModel
using SpineInterface
using Cbc

db_url_in = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a3/input/input.sqlite"
db_url_out = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a3/output/output.sqlite"
m = run_spinemodel(db_url_in, db_url_out; optimizer=Cbc.Optimizer)



# constraint_flow_capacity
##########################
# GT_PowerMax[n=GasT,t=1:T], P[n,t] <= Pmax[n]*U[n,t]
# HB_Max[n=HeatB,t=1:T], Q[n,t] <= Qmax[n]*U[n,t]
# BP_CHPModePowerMax[n=BckP,t=1:T], P[n,t] <= Pmax[n]*M1[n,t]
# BP_BoilerModeHeatMax[n=BckP,t=1:T], QM2[n,t] <= Qmax[n]*M2[n,t]
