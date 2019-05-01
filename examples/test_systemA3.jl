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
    let total_cost = zero(AffExpr)
        for (u, c) in indices(conversion_cost)
            total_cost += sum(
                flow[x...] * duration(x.t) * conversion_cost(unit=u, commodity=c, t=x.t)
                for x in flow_indices(unit=u, commodity=c)
            )
        end
        @objective(m, Min, total_cost)
    end
end

# E_Feasible1[n=GA,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] <= Pbeta[n]*Pmax[n]*U[n,t]
# GT_PowerMax[n=GC,t=1:T], P[n,t] <= Pmax[n]*U[n,t]
# HB_Max[n=GD,t=1:T], Q[n,t] <= Qmax[n]*U[n,t]
function constraint_flow_capacity(m::Model, flow, units_online)
    for (u, c) in indices(unit_capacity; unit=unit(unit_type=:extraction_steam), commodity=:electricity)
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t) * marginal_fuel_consumption(unit=u, commodity=x.commodity, t=t)
                    for x in flow_indices(unit=u, t=t)
                )
                <=
                + sum(
                    + units_online[y...]
                        * duration(y.t)
                        * unit_capacity(unit=u, commodity=c, t=t)
                        * marginal_fuel_consumption(unit=u, commodity=c, t=t)
                    for y in units_online_indices(unit=u, t=t)
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
                    + units_online[y...]
                        * duration(y.t)
                        * unit_capacity(unit=u, commodity=c, t=t)
                    for y in units_online_indices(unit=u, t=t)
                )
            )
        end
    end
end

# E_Feasible2[n=GA,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] >= Pbeta[n]*Pmin[n]*U[n,t]
# GT_PowerMin[n=GC,t=1:T], P[n,t] >= Pmin[n]*U[n,t]
# HB_Min[n=GD,t=1:T], Q[n,t] >= Qmin[n]*U[n,t]
function constraint_minimum_operating_point(m::Model, flow, units_online)
    for (u, c) in indices(minimum_operating_point; unit=unit(unit_type=:extraction_steam), commodity=:electricity)
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(t) * marginal_fuel_consumption(unit=u, commodity=x.commodity, t=t)
                    for x in flow_indices(unit=u, t=t)
                )
                >=
                + sum(
                    + units_online[y...]
                        * duration(y.t)
                        * minimum_operating_point(unit=u, commodity=c, t=t)
                        * marginal_fuel_consumption(unit=u, commodity=c, t=t)
                    for y in units_online_indices(unit=u, t=t)
                )
            )
        end
    end
    for (u, c) in indices(minimum_operating_point; unit=unit(unit_type=(:gas_turbine, :heat_boiler)))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t)
                    for x in flow_indices(unit=u, commodity=c, t=t)
                )
                <=
                + sum(
                    + units_online[y...]
                        * duration(y.t)
                        * minimum_operating_point(unit=u, commodity=c, t=t)
                    for y in units_online_indices(unit=u, t=t)
                )
            )
        end
    end
end

# E_Feasible3[n=GA,t=1:T], P[n,t] >= ratio[n]*Q[n,t]
# GT_Ratio[n=GC,t=1:T], P[n,t] >= ratio[n]*Q[n,t]
function constraint_min_ratio_out_out_flow(m::Model, flow)
    for (u, c1, c2) in indices(min_ratio_out_out_flow; unit=unit(unit_type=(:extraction_steam, :gas_turbine)))
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
    for (u, c_out, c_in) in indices(
            fix_ratio_out_in_flow;
            unit=unit(unit_type=(:heat_boiler, :gas_turbine, :back_pressure_steam, :converter))
        )
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x...] * duration(x.t)
                    for x in flow_indices(
                        unit=u,
                        commodity=commodity_group__commodity(commodity1=c_out, _default=c_out),
                        direction=:to_node,
                        t=t_in_t(t_long=t)
                    )
                )
                ==
                + fix_ratio_out_in_flow(unit=u, commodity1=c_out, commodity2=c_in, t=t)
                    * sum(
                        flow[y...] * duration(y.t)
                        for y in flow_indices(
                            unit=u,
                            commodity=commodity_group__commodity(commodity1=c_in, _default=c_in),
                            direction=:from_node,
                            t=t_in_t(t_long=t)
                        )
                    )
            )
        end
    end
    for (u, c_out, c_in) in indices(fix_ratio_out_in_flow; unit=unit(unit_type=(:extraction_steam)))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x...] * duration(x.t) * marginal_fuel_consumption(unit=u, commodity=x.commodity, t=t)
                    for x in flow_indices(
                        unit=u,
                        commodity=commodity_group__commodity(commodity1=c_out, _default=c_out),
                        direction=:to_node,
                        t=t_in_t(t_long=t)
                    )
                )
                ==
                + fix_ratio_out_in_flow(unit=u, commodity1=c_out, commodity2=c_in, t=t)
                    * sum(
                        flow[y...] * duration(y.t)
                        for y in flow_indices(
                            unit=u,
                            commodity=commodity_group__commodity(commodity1=c_in, _default=c_in),
                            direction=:from_node,
                            t=t_in_t(t_long=t)
                        )
                    )
            )
        end
    end
end

# HeatBalance[t=1:T], sum(Q[n,t] for n = 1:N) - heat[t] + HS[t] == 0
# PowerBalance[t=1:T], sum(P[n,t] for n=vcat(GA,GB,GC)) + PW[t] + Pimp[t] == Pself[t] + load[t] - LS[t]
# WindGeneration[t=1:T], PW[t] == wind[t] - WS[t]
function constraint_nodal_balance(m::Model, flow, trans)
	for (n, tblock) in node__temporal_block()
        @show n
        for t in time_slice(temporal_block=tblock)
            @show @constraint(
                m,
    			0
                ==
                # Demand for the commodity
    			- demand(node=n, t=t) * duration(t)
                # Output of units into this node, and their input from this node
                + reduce(
                    +,
                    flow[x...] * duration(x.t)
                    for x in flow_indices(node=n, t=t_in_t(t_long=t), direction=:to_node);
                    init=0
                )
    			- reduce(
                    +,
                    flow[x...] * duration(x.t)
                    for x in flow_indices(node=n, t=t_in_t(t_long=t), direction=:from_node);
                    init=0
                )
                # Transfer of commodities between nodes
    			+ reduce(
                    +,
                    trans[y...] * duration(y.t)
                    for y in trans_indices(node=n, t=t_in_t(t_long=t), direction=:to_node);
                    init=0
                )
    			- reduce(
                    +,
                    trans[y...] * duration(y.t)
                    for y in trans_indices(node=n, t=t_in_t(t_long=t), direction=:from_node);
                    init=0
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
trans = variable_trans(m)
units_online = variable_units_online(m)
# Create objective function
objective_minimize_production_cost(m, flow)
# Add constraints
constraint_flow_capacity(m, flow, units_online)
constraint_minimum_operating_point(m, flow, units_online)
constraint_min_ratio_out_out_flow(m, flow)
constraint_fix_ratio_out_in_flow(m, flow)
constraint_nodal_balance(m, flow, trans)
optimize!(m)
status = termination_status(m)
println("Saving results...")
if status == MOI.OPTIMAL
    println("units_online")
    for (k,v) in sort(pack_trailing_dims(SpineModel.value(units_online), 1)) @show k, v end
    println("flow")
    for (k,v) in sort(pack_trailing_dims(SpineModel.value(flow), 1)) @show k, v end
    println("trans")
    for (k,v) in sort(pack_trailing_dims(SpineModel.value(trans), 1)) @show k, v end
end
