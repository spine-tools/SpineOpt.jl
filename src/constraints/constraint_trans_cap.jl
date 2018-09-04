# FIXME: some names here don't respect the lower_case convention
function constraint_trans_cap(m::Model,v_Trans)
    @constraint(
        m,
        [
            con in connection(),
            i in node(),
            j in node(),
            t=1:number_of_timesteps(time="timer");
            [i,j] in connection__node__node(connection=con)
        ],
        + (v_Trans[con, i, j, t])
        <=
        + trans_cap_av_frac(connection=con, node1=i, node2=j, t=t)
            * trans_cap(connection=con)
    )
end
