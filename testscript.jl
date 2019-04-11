for (u, cg_out, cg_in) in unit__out_commodity_group__in_commodity_group()
    global time_slices_constraint_original= []
    global time_slices_constraint= []
    global  time_slices_constraint_out = []
    global time_slices_constraint_in = []
    global gathering = []
    global both_condtions = []
    global test
    global constraint_generate_on = []
        for (c_out,n,tblock) in commodity__node__unit__direction__temporal_block(unit = u,direction = :out)
            if c_out in commodity_group__commodity(commodity_group=cg_out)
                for t in time_slice(temporal_block=tblock)
                    time_slices_constraint_out  = push!(time_slices_constraint_out ,t)
                    time_slices_constraint_original  = push!(time_slices_constraint_original,t)
                end
            end
        end
        for (c_in,n,tblock) in commodity__node__unit__direction__temporal_block(unit = u,direction = :in)
            if c_in in commodity_group__commodity(commodity_group=cg_in)
                for t in time_slice(temporal_block=tblock)
                    time_slices_constraint_in= push!(time_slices_constraint_in,t)
                    time_slices_constraint_original  = push!(time_slices_constraint_original,t)
                end
            end
        end
        unique!(time_slices_constraint_out )
        unique!(time_slices_constraint_in)
        for t_in in time_slices_constraint_in
                test = t_overlaps_t(t_overlap=t_in)
                for test2 in test
                    both_conditions = time_slices_constraint_out[findall(x -> x == test2, time_slices_constraint_out)]
                    @show both_conditions
                    if both_conditions != []
                        @show "gathered"
                        gathering = push!(gathering, t_in)
                        gathering = push!(gathering, both_conditions[1])
                        ## TODO make sure that gathering[1] is start always
                    end
                end
        end

        j=1
        i =1
        while i < length(gathering)
             while j <= length(gathering) && (gathering[i].start == gathering[j].start || gathering[i].end_ == gathering[j].end_) ##NOTE: sufficient?
                 if gathering[i].end_ < gathering[j].end_
                    i = j
                else #go to next [j]
                    j += 1
                end
             end
             constraint_generate_on = push!(constraint_generate_on, gathering[i])
            i = j
         end

        # t_out= []
        # t_out_old = []
        # while  t_out != t_out_old
        #     t_out = t_in_t(t_short = t_out)
        # end
        #
        # # unique!(time_slices_constraint_out )
        # # unique!(time_slices_constraint_in)
        # push!(all_slice,time_slices_constraint_out )
        # push!(all_slice,time_slices_constraint_in)
        # unique!(all_slice)
        # # for test in time_slices_constraint_out
        # #     find(test.start,time_slices_constraint_in.start)
        # # end
end
