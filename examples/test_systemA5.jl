using Revise
using SpineModel
using SpineInterface
using JuMP
using Cbc

using SpineModel: @catch_undef

# TODO:
# - implement Base.-(::TimeSlice, ::Period) Ok
# - implement overlap_duration(::TimeSlice, ::TimeSlice) Ok
@catch_undef function constraint_fix_delay_out_in_trans(m::Model)
    @fetch trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:fix_delay_out_in_trans] = Dict()
    for (conn, n_out, n_in) in indices(fix_delay_out_in_trans)
        for t in time_slice()
            constr_dict[conn, n_out, n_in, t] = @constraint(
                m,
                + sum(
                    + trans[conn_, n_out_, c, d, t1] * duration(t1)
                    for (conn_, n_out_, c, d, t1) in trans_indices(
                        connection=conn,
                        node=n_out,
                        direction=:to_node,
                        t=t
                    )
                )
                ==
                + sum(
                    + trans[conn_, n_in_, c, d, t1]
                        * overlap_duration(
                            t1,
                            t - fix_delay_out_in_trans(connection=conn, node1=n_out, node2=n_in, t=t)
                        )
                    for (conn_, n_in_, c, d, t1) in trans_indices(
                        connection=conn,
                        node=n_in,
                        direction=:from_node,
                        t=t_overlaps_t(t - fix_delay_out_in_trans(connection=conn, node1=n_out, node2=n_in, t=t))
                    )
                )
            )
        end
    end
end

function extend_model(m::Model)
    constraint_fix_delay_out_in_trans(m)
end

db_url_in = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a5/input/input.sqlite"
db_url_out = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a5/output/output.sqlite"
m = run_spinemodel(db_url_in, db_url_out; result_name="testing", extend_model=extend_model, cleanup=false)
