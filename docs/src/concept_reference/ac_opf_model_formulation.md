The model formulation of AC optimal power flow is governed by the parameter ac\_opf\_model\_formulation](@ref). Currently three values are possible:

`ac_opf_conic`: activates the second order cone programming (SOCP) relaxation of optimal power flow problem in rectangular coordinates. Computationally the most demanding formulation which requires a solver which accepts second order cone constraints.

`ac_opf_linear`: activates the linear approximation of second order cone programming (SOCP) relaxation of optimal power flow problem in rectangular coordinates.

`ac_opf_lindistflow`: activates the linearized Distflow formulation.