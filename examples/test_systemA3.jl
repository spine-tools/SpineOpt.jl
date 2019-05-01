# Load required packaes
using Revise
using SpineModel
using SpineInterface
using JuMP
using Cbc

import SpineModel: duration, variable_flow, flow_indices, variable_units_online, units_online_indices, TimeSlice

# Extend/override SpineModel.jl
# TODO: handle multiple temporal_blocks everywhere. This means using overlapping time slices in all constraints

function variable_flow(m::Model)
    Dict{Tuple,JuMP.VariableRef}(
        (u, n, c, d, md, t) => @variable(
            m, base_name="flow[$u, $n, $c, $d, $md, $(t.JuMP_name)]", lower_bound=0
        ) for (u, n, c, d, md, t) in flow_indices()
    )
end

function flow_indices(;
        commodity=anything, node=anything, unit=anything, direction=anything, mode=anything, t=anything)
    [
        (unit=u, node=n, commodity=c, direction=d, mode=md, t=t1)
        for (n, c) in node__commodity(commodity=commodity, node=node, _compact=false)
            for (u, n_, d, blk) in unit__node__direction__temporal_block(
                    node=n, unit=unit, direction=direction, _compact=false)
                for md in unit__mode(unit=u, _default=Object(:default))
                    for t1 in intersect(time_slice(temporal_block=blk), t)
    ]
end

function variable_units_online(m::Model)
    Dict{Tuple,JuMP.VariableRef}(
        (u, md, t) => @variable(
            m, base_name="units_online[$u, $md, $(t.JuMP_name)]", binary=true
        ) for (u, md, t) in units_online_indices()
    )
end


function units_online_indices(;unit=anything, mode=anything, t=anything)
    [
        (unit=u, mode=md, t=t1)
        for u in intersect(SpineModel.unit(), unit)
            for md in unit__mode(unit=u, _default=Object(:default))
                for t1 in intersect(t_highest_resolution(Array{TimeSlice,1}([x.t for x in flow_indices(unit=u)])), t)
    ]
end

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
# BP_CHPModePowerMax[n=GB,t=1:T], P[n,t] <= Pmax[n]*M1[n,t]
# BP_BoilerModeHeatMax[n=GB,t=1:T], QM2[n,t] <= Qmax[n]*M2[n,t]
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
    for (u, c, md) in indices(unit_capacity; unit=unit(unit_type=:back_pressure_steam))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t)
                    for x in flow_indices(unit=u, commodity=c, mode=md, t=t)
                )
                <=
                + sum(
                    + units_online[y...]
                        * duration(y.t)
                        * unit_capacity(unit=u, commodity=c, mode=md, t=t)
                    for y in units_online_indices(unit=u, mode=md, t=t)
                )
            )
        end
    end
end

# E_Feasible2[n=GA,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] >= Pbeta[n]*Pmin[n]*U[n,t]
# GT_PowerMin[n=GC,t=1:T], P[n,t] >= Pmin[n]*U[n,t]
# HB_Min[n=GD,t=1:T], Q[n,t] >= Qmin[n]*U[n,t]
# BP_CHPModePowerMin[n=GB,t=1:T], P[n,t] >= Pmin[n]*M1[n,t]
# BP_BoilerModeHeatMin[n=GB,t=1:T], QM2[n,t] >= Qmin[n]*M2[n,t]
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
    for (u, c, md) in indices(minimum_operating_point; unit=unit(unit_type=:back_pressure_steam))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    + flow[x...] * duration(x.t)
                    for x in flow_indices(unit=u, commodity=c, mode=md, t=t)
                )
                <=
                + sum(
                    + units_online[y...]
                        * duration(y.t)
                        * minimum_operating_point(unit=u, commodity=c, mode=md, t=t)
                    for y in units_online_indices(unit=u, mode=md, t=t)
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

# BP_CHPModeRatio[n=GB,t=1:T], P[n,t] == ratio[n]*QM1[n,t]
function constraint_fix_ratio_out_out_flow(m::Model, flow)
    for (u, c1, c2, md) in indices(fix_ratio_out_out_flow; unit=unit(unit_type=(:back_pressure_steam)))
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x...] * duration(t)
                    for x in flow_indices(unit=u, commodity=c1, direction=:to_node, mode=md, t=t)
                )
                ==
                + fix_ratio_out_out_flow(unit=u, commodity1=c1, commodity2=c2, mode=md, t=t)
                    * sum(
                        flow[x...] * duration(t)
                        for x in flow_indices(unit=u, commodity=c2, direction=:to_node, mode=md, t=t)
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

# BP_TotalHeat[n=GB,t=1:T], Q[n,t] == QM1[n,t] + QM2[n,t]
# HeatBalance[t=1:T], sum(Q[n,t] for n = 1:N) - heat[t] + HS[t] == 0
# PowerBalance[t=1:T], sum(P[n,t] for n=vcat(GA,GB,GC)) + PW[t] + Pimp[t] == Pself[t] + load[t] - LS[t]
# WindGeneration[t=1:T], PW[t] == wind[t] - WS[t]
function constraint_nodal_balance(m::Model, flow, trans)
	for (n, tblock) in node__temporal_block()
        for t in time_slice(temporal_block=tblock)
            @constraint(
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

# BP_OperationStatus[n=GB,t=1:T], U[n,t] == M1[n,t] + M2[n,t]
function constraint_one_mode_at_a_time(m::Model, units_online)
    for u in unit(unit_type=:back_pressure_steam)
        for t in time_slice()
            @show @constraint(
                m,
                sum(units_online[x...] for x in units_online_indices(unit=u, t=t)) <= 1
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
constraint_fix_ratio_out_out_flow(m, flow)
constraint_fix_ratio_out_in_flow(m, flow)
constraint_nodal_balance(m, flow, trans)
constraint_one_mode_at_a_time(m, units_online)
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
