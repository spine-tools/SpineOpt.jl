# Load required packaes
using Revise
using SpineModel
using SpineInterface
using JuMP
using Cbc

import SpineModel: duration

# Extend/override SpineModel.jl
# TODO: handle multiple temporal_blocks everywhere. This means using overlapping time slices in all constraints

"""
    objective_minimize_production_cost(m::Model, flow)

Minimize the `production_cost` correspond to the sum over all
`conversion_cost` of each `unit`.
"""
function objective_minimize_production_cost(m::Model, flow)
    # TODO: Add the other terms
    @objective(
        m,
        Min,
        sum(
            flow[u, n, c, d, t] * duration(t) * conversion_cost(unit=u, commodity=c, t=t)
            for (u_, c_) in unit__commodity() for (u, n, c, d, t) in flow_indices(unit=u_, commodity=c_)
                if conversion_cost(unit=u, commodity=c, t=t) != nothing
        )
    )
end

# E_Feasible1[n=GA,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] <= Pbeta[n]*Pmax[n]*U[n,t]
# GT_PowerMax[n=GC,t=1:T], P[n,t] <= Pmax[n]*U[n,t]
# HB_Max[n=GD,t=1:T], Q[n,t] <= Qmax[n]*U[n,t]
function constraint_unit_capacity(m::Model, flow, unit_online)
    for (u, c) in indices(unit_capacity; unit=unit(unit_type=:extraction_steam), commodity=:electricity)
        @show u, c
        for t in time_slice()
            @show @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t) * marginal_fuel_consumption(unit=u, commodity=x.commodity, t=t)
                    for x in flow_indices(unit=u, t=t)
                )
                <=
                + sum(
                    + unit_online[y...]
                        * duration(y.t)
                        * unit_capacity(unit=u, commodity=c, t=t)
                        * marginal_fuel_consumption(unit=u, commodity=c, t=t)
                    for y in unit_online_indices(unit=u, t=t)
                )
            )
        end
    end
    for (u, c) in indices(unit_capacity; unit=unit(unit_type=(:gas_turbine, :heat_boiler)))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t)
                    for x in flow_indices(unit=u, commodity=c, t=t)
                )
                <=
                + sum(
                    + unit_online[y...]
                        * duration(y.t)
                        * unit_capacity(unit=u, commodity=c, t=t)
                    for y in unit_online_indices(unit=u, t=t)
                )
            )
        end
    end
end

# E_Feasible2[n=GA,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] >= Pbeta[n]*Pmin[n]*U[n,t]
# GT_PowerMin[n=GC,t=1:T], P[n,t] >= Pmin[n]*U[n,t]
# HB_Min[n=GD,t=1:T], Q[n,t] >= Qmin[n]*U[n,t]
function constraint_unit_min_output(m::Model, flow, unit_online)
    for (u, c) in indices(unit_min_output; unit=unit(unit_type=:extraction_steam))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(t) * marginal_fuel_consumption(unit=u, commodity=x.commodity, t=t)
                    for x in flow_indices(unit=u, t=t)
                )
                >=
                + sum(
                    + unit_online[y...]
                        * duration(y.t)
                        * unit_min_output(unit=u, commodity=c, t=t)
                        * marginal_fuel_consumption(unit=u, commodity=c, t=t)
                    for y in unit_online_indices(unit=u, t=t)
                )
            )
        end
    end
    for (u, c) in indices(unit_min_output; unit=unit(unit_type=(:gas_turbine, :heat_boiler)))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t)
                    for x in flow_indices(unit=u, commodity=c, t=t)
                )
                <=
                + sum(
                    + unit_online[y...]
                        * duration(y.t)
                        * unit_min_output(unit=u, commodity=c, t=t)
                    for y in unit_online_indices(unit=u, t=t)
                )
            )
        end
    end
end

# E_Feasible3[n=GA,t=1:T], P[n,t] >= ratio[n]*Q[n,t]
# GT_Ratio[n=GC,t=1:T], P[n,t] >= ratio[n]*Q[n,t]
function constraint_min_ratio_out_out_flow(m::Model, flow)
    for (u, c1, c2) in min_ratio_out_out_flow_indices(
            unit=unit(unit_type=(:extraction_steam, :gas_turbine)), _indices=:all
        )
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x...] * duration(t)
                    for x in flow_indices(unit=u, commodity=c1, direction=:to_node, t=t)
                )
                >=
                + min_ratio_out_out_flow(unit=u, commodity1=c1, commodity2=c2, t=t)
                    * sum(
                        flow[x...] * duration(t)
                        for x in flow_indices(unit=u, commodity=c2, direction=:to_node, t=t)
                    )
            )
        end
    end
end


# E_Fuel[n=GA,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * (Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t])
# HB_Fuel[n=GD,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * Q[n,t]
# BP_Fuel[n=GB,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * (P[n,t]+Q[n,t])
# GT_Fuel[n=GC,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * (ratio[n]+1) / ratio[n] * P[n,t]
function constraint_fix_ratio_out_in_flow(m::Model, flow)
    for inds in indices(fix_ratio_out_in_flow); (u, c_out, c_in) = inds
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x...] * duration(x.t)
                    for x in flow_indices(
                        unit=u,
                        commodity=commodity_group__commodity(commodity_group=c_out, _default=c_out),
                        direction=:to_node,
                        t=t_in_t(t_long=t)
                    )
                )
                ==
                + fix_ratio_out_in_flow(;inds..., t=t)
                    * sum(
                        flow[y...] * duration(y.t)
                        for y in flow_indices(
                            unit=u,
                            commodity=commodity_group__commodity(commodity_group=c_in, _default=c_in),
                            direction=:from_node,
                            t=t_in_t(t_long=t)
                        )
                    )
            )
        end
    end
end

db_url = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a3/input/input.sqlite"
using_spinemodeldb(db_url; upgrade=true)
generate_time_slice()
generate_time_slice_relationships()
# Init model
m = Model(with_optimizer(Cbc.Optimizer))
# Create decision variables
flow = variable_flow(m)
unit_online = variable_unit_online(m)
# Create objective function
objective_minimize_production_cost(m, flow)
# Add constraints
constraint_unit_capacity(m, flow, unit_online)
constraint_unit_min_output(m, flow, unit_online)
constraint_min_ratio_out_out_flow(m, flow)
constraint_fix_ratio_out_in_flow(m, flow)
optimize!(m)
status = termination_status(m)
println("Saving results...")
if status == MOI.OPTIMAL
    @show pack_trailing_dims(SpineModel.value(flow), 1)
    @show pack_trailing_dims(SpineModel.value(unit_online), 1)
end
