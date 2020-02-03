using Revise
using SpineInterface
using SpineModel
using JuMP

import SpineModel: duration

function add_constraint_flow_affine_expr!(m::Model)
    @fetch flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][:flow_affine_expr] = Dict()
    for cstr in constraint()
        tblk = constraint__temporal_block(constraint=cstr)
        t_list = isempty(tblk) ? time_slice() : time_slice(temporal_block=tblk)
        for t in t_list
            expr = @expression(
                m,
                + sum(
                    sum(
                        flow[u, n, c, d, t1] * duration(t1) * flow_coeff(;ind..., t=t1)
                        for (u, n, c, d, t1) in flow_indices(
                            unit=get(ind, :unit, anything),
                            node=get(ind, :node, anything),
                            commodity=get(ind, :commodity, anything),
                            direction=get(ind, :direction, anything),
                            t=t
                        )
                    )
                    for ind in indices(flow_coeff; constraint=cstr)
                )
                + sum(
                    sum(
                        units_on[u, t1] * duration(t1) * units_on_coeff(;ind..., t=t1)
                        for (u, t1) in units_on_indices(unit=get(ind, :unit, anything), t=t)
                    )
                    for ind in indices(units_on_coeff; constraint=cstr)
                )
                + const_term(constraint=cstr, t=t) * duration(t)
            )
            type_ = cstr_type(constraint=cstr)
            if type_ == :lt
                cons[cstr, t] = @constraint(m, expr <= 0)
            elseif type_ == :eq
                cons[cstr, t] = @constraint(m, expr == 0)
            end
        end
    end
end

function add_constraints(m::Model)
    add_constraint_flow_affine_expr!(m)
end

db_url_in = "sqlite:///$(@__DIR__)/data/test_systemA3.sqlite"
db_url_out = "sqlite:///$(@__DIR__)/data/test_systemA3_out.sqlite"
m = run_spinemodel(db_url_in, db_url_out; add_constraints=add_constraints, cleanup=false, log_level=2)
