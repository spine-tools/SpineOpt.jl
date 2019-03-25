function time_slicemap()
    time_slicemap = Dict()
    for k in temporal_block()
            #if length(time_slice_duration()[k])==1
                test = collect(start_date(k):Minute(time_slice_duration()[k][1]):end_date(k))
                for i = 1: length(test)
                if i == 1
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
                else
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
                end
                end
#=
            else
                for i = 1: length(time_slice_duration()[k])
                    if i == 1
                    time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][i]),Minute(time_slice_duration()[k][i]))
                    else
                    time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][i]),+Minute(time_slice_duration()[k][i]))
                    end
                end
            end
                            =#
    end
    return time_slicemap
end
