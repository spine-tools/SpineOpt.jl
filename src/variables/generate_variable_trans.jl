function generate_variable_trans(m::Model)
    @variable(
        m,
        v_trans[
            c in connection(),
            i in node(),
            j in node(),
            t = 1:number_of_timesteps(time="timer");
            [c,i,j] in connection__node__node()
        ]
    )
end
