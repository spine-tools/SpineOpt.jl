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
    Dict{NamedTuple,JuMP.VariableRef}(
        i => @variable(
            m,
            base_name="flow[$(join(i, ", "))]", # TODO: JuMP_name (maybe use Base.show(..., ::TimeSlice))
            lower_bound=0
        ) for i in flow_indices()
    )
end

function flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything, tail...)
    [
        (u_inds..., node=n, commodity=c, direction=d, t=t1)
        for (n, c) in node__commodity(commodity=commodity, node=node, _compact=false)
            for (u, n, d, blk) in unit__node__direction__temporal_block(
                    node=n, unit=unit, direction=direction, _compact=false)
                for u_inds in indices(has_flow; unit=u, tail..., value_filter=x->x==true)
                    for t1 in intersect(time_slice(temporal_block=blk), t)
    ]
end

function variable_units_online(m::Model)
    Dict{NamedTuple,JuMP.VariableRef}(
        i => @variable(
            m,
            base_name="units_online[$(join(i, ", "))]", # TODO: JuMP_name (maybe use Base.show(..., ::TimeSlice))
            integer=true,
            lower_bound=0
        ) for i in units_online_indices()
    )
end

function units_online_indices(;unit=anything, t=anything, tail...)
    [
        (u_inds..., t=t1)
        for u_inds in indices(has_flow; unit=unit, tail..., value_filter=x->x==true)
            for t1 in intersect(t_highest_resolution([x.t for x in flow_indices(unit=u_inds.unit)]), t)
    ]
end

function objective_minimize_production_cost(m::Model, flow)
    let total_cost = zero(AffExpr)
        for inds in indices(conversion_cost)
            total_cost += sum(
                flow[i] * duration(i.t) * conversion_cost(;inds..., t=i.t)
                for i in flow_indices(;inds...)
            )
        end
        @objective(m, Min, total_cost)
    end
end


# E_Fuel[n=ExtrS,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * (Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t])
# E_Feasible2[n=ExtrS,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] >= Pbeta[n]*Pmin[n]*U[n,t]
# E_Feasible1[n=ExtrS,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] <= Pbeta[n]*Pmax[n]*U[n,t]
####
# E_Feasible1[n=ExtrS,t=1:T], Pbeta[n]*P[n,t] + Qbeta[n]*Q[n,t] - Pbeta[n]*Pmax[n]*U[n,t] <= 0
# indices = (unit=CHP1, commodity=electricity) => flow_coeff = Pbeta, units_online_coeff = -Pbeta*Pmax
# indices = (unit=CHP1, commodity=gas) => flow_coeff = Qbeta
####
# E_Feasible2[n=ExtrS,t=1:T], - Pbeta[n]*P[n,t] - Qbeta[n]*Q[n,t] + Pbeta[n]*Pmin[n]*U[n,t] <= 0
# indices = (unit=CHP1, commodity=electricity) => flow_coeff = -Pbeta, units_online_coeff = Pbeta*Pmin
# indices = (unit=CHP1, commodity=gas) => flow_coeff = -Qbeta
####
# E_Fuel[n=ExtrS,t=1:T], - Pfuel[n,t] + (1/efficiency[n]) * Pbeta[n]*P[n,t] + (1/efficiency[n]) * Qbeta[n]*Q[n,t]) == 0
# indices = (unit=CHP1, commodity=fuel) => flow_coeff = -1
# indices = (unit=CHP1, commodity=electricity) => flow_coeff = (1/efficiency[n]) * Pbeta[n]
# indices = (unit=CHP1, commodity=heat) => flow_coeff = (1/efficiency[n]) * Qbeta[n]
function constraint_flow_affine_expr(m::Model, flow, units_online)
    for cstr in constraint()
        for t in time_slice()
            expr = @expression(
                m,
                + sum(
                    sum(
                        flow[x] * duration(x.t) * flow_coeff(;inds..., t=x.t)
                        for x in flow_indices(;inds..., t=t)
                    )
                    for inds in indices(flow_coeff; constraint=cstr)
                )
                + sum(
                    sum(
                        units_online[x] * duration(x.t) * units_online_coeff(;inds..., t=x.t)
                        for x in units_online_indices(;inds..., t=t)
                    )
                    for inds in indices(units_online_coeff; constraint=cstr)
                )
                + const_term(constraint=cstr, t=t)
            )
            type_ = cstr_type(constraint=cstr)
            if type_ == :lt
                @constraint(m, expr <= 0)
            elseif type_ == :eq
                @constraint(m, expr == 0)
            end
        end
    end
end


# GT_PowerMax[n=GasT,t=1:T], P[n,t] <= Pmax[n]*U[n,t]
# HB_Max[n=HeatB,t=1:T], Q[n,t] <= Qmax[n]*U[n,t]
# BP_CHPModePowerMax[n=BckP,t=1:T], P[n,t] <= Pmax[n]*M1[n,t]
# BP_BoilerModeHeatMax[n=BckP,t=1:T], QM2[n,t] <= Qmax[n]*M2[n,t]
function constraint_flow_capacity(m::Model, flow, units_online)
    for inds in indices(unit_capacity)
        for t in time_slice()
            @constraint(
                m,
                + sum(flow[x] * duration(x.t) for x in flow_indices(;inds..., t=t))
                <=
                + sum(
                    + units_online[x]
                        * unit_capacity(;inds..., t=x.t)
                        * unit_conv_cap_to_flow(;inds..., t=x.t)
                        * duration(x.t)
                    for x in units_online_indices(;inds..., t=t_in_t(t_long=t))
                        if unit_conv_cap_to_flow(;inds..., t=x.t) != nothing
                )
            )
        end
    end
end

# GT_PowerMin[n=GasT,t=1:T], P[n,t] >= Pmin[n]*U[n,t]
# HB_Min[n=HeatB,t=1:T], Q[n,t] >= Qmin[n]*U[n,t]
# BP_CHPModePowerMin[n=BckP,t=1:T], P[n,t] >= Pmin[n]*M1[n,t]
# BP_BoilerModeHeatMin[n=BckP,t=1:T], QM2[n,t] >= Qmin[n]*M2[n,t]
function constraint_minimum_operating_point(m::Model, flow, units_online)
    for inds in indices(minimum_operating_point)
        for t in time_slice()
            @constraint(
                m,
                + sum(flow[x] * duration(x.t) for x in flow_indices(;inds..., t=t))
                <=
                + sum(
                    + units_online[x]
                        * minimum_operating_point(;inds..., t=x.t)
                        * unit_conv_cap_to_flow(;inds..., t=x.t)
                        * duration(x.t)
                    for x in units_online_indices(;inds..., t=t_in_t(t_long=t))
                        if unit_conv_cap_to_flow(;inds..., t=x.t) != nothing
                )
            )
        end
    end
end

# E_Feasible3[n=ExtrS,t=1:T], P[n,t] >= ratio[n]*Q[n,t]
# GT_Ratio[n=GasT,t=1:T], P[n,t] >= ratio[n]*Q[n,t]
function constraint_min_ratio_out_out_flow(m::Model, flow)
    for inds in indices(min_ratio_out_out_flow)
        for t in time_slice()
            @constraint(
                m,
                + sum(flow[x] * duration(x.t) for x in flow_indices(;
                    inds..., commodity=inds.commodity1, t=t))
                >=
                + min_ratio_out_out_flow(;inds..., t=t)
                    * sum(flow[x] * duration(x.t) for x in flow_indices(;
                        inds..., commodity=inds.commodity2, t=t))
            )
        end
    end
end

# BP_CHPModeRatio[n=BckP,t=1:T], P[n,t] == ratio[n]*QM1[n,t]
function constraint_fix_ratio_out_out_flow(m::Model, flow)
    for inds in indices(fix_ratio_out_out_flow)
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x] * duration(x.t)
                    for x in flow_indices(;inds..., commodity=inds.commodity1, t=t)
                )
                ==
                + fix_ratio_out_out_flow(;inds..., t=t)
                    * sum(
                        flow[x] * duration(x.t)
                        for x in flow_indices(;inds..., commodity=inds.commodity2, t=t)
                    )
            )
        end
    end
end


# HB_Fuel[n=HeatB,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * Q[n,t]
# BP_Fuel[n=BckP,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * (P[n,t]+Q[n,t])
# GT_Fuel[n=GasT,t=1:T], Pfuel[n,t] == (1/efficiency[n]) * (ratio[n]+1) / ratio[n] * P[n,t]
function constraint_fix_ratio_out_in_flow(m::Model, flow)
    for inds in indices(fix_ratio_out_in_flow)
        for t in time_slice()
            @constraint(
                m,
                + sum(
                    flow[x] * duration(x.t)
                    for x in flow_indices(;
                        inds...,
                        commodity=commodity_group__commodity(
                            commodity1=inds.commodity1, _default=inds.commodity1
                        ),
                        t=t_in_t(t_long=t)
                    )
                )
                ==
                + fix_ratio_out_in_flow(;inds..., t=t)
                    * sum(
                        flow[x] * duration(x.t)
                        for x in flow_indices(;
                            inds...,
                            commodity=commodity_group__commodity(
                                commodity1=inds.commodity2, _default=inds.commodity2
                            ),
                            t=t_in_t(t_long=t)
                        )
                    )
            )
        end
    end
end

# BP_TotalHeat[n=BckP,t=1:T], Q[n,t] == QM1[n,t] + QM2[n,t]
# HeatBalance[t=1:T], sum(Q[n,t] for n = 1:N) - heat[t] + HS[t] == 0
# PowerBalance[t=1:T], sum(P[n,t] for n=vcat(ExtrS,BckP,GasT)) + PW[t] + Pimp[t] == Pself[t] + load[t] - LS[t]
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
                    flow[x] * duration(x.t)
                    for x in flow_indices(node=n, t=t_in_t(t_long=t), direction=:to_node);
                    init=0
                )
    			- reduce(
                    +,
                    flow[x] * duration(x.t)
                    for x in flow_indices(node=n, t=t_in_t(t_long=t), direction=:from_node);
                    init=0
                )
                # Transfer of commodities between nodes
    			+ reduce(
                    +,
                    trans[y] * duration(y.t)
                    for y in trans_indices(node=n, t=t_in_t(t_long=t), direction=:to_node);
                    init=0
                )
    			- reduce(
                    +,
                    trans[y] * duration(y.t)
                    for y in trans_indices(node=n, t=t_in_t(t_long=t), direction=:from_node);
                    init=0
                )
            )
        end
    end
end

# BP_OperationStatus[n=BckP,t=1:T], U[n,t] == M1[n,t] + M2[n,t]
# TODO: replace this by constraint_units_available and constraint_units_online
function constraint_one_mode_at_a_time(m::Model, units_online)
    for u in unit(unit_type=:back_pressure_steam)
        for t in time_slice()
            @show @constraint(
                m,
                sum(units_online[x] for x in units_online_indices(unit=u, t=t)) <= 1
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
constraint_flow_affine_expr(m, flow, units_online)
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
