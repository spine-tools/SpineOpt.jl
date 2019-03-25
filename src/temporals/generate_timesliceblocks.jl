function time_slices_tempblock()
    time_slices_tempblock = Dict()
    for k in temporal_block()
        time_slices_tempblock[k] = Dict()
            if length(time_slice_duration()[k])==1
                test = collect(start_date(k):Minute(time_slice_duration()[k][1]):end_date(k))
                for i = 1: length(test)
                if i == 1
                time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                else
                time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                end
                end
            else
                for i = 1: length(time_slice_duration()[k])
                    if i == 1
                    time_slices_tempblock[k]["$(k)_t_$(i)"] = "$(k)_t_$(i)"
                    else
                    time_slices_tempblock[k]["$(k)_t_$(i)"]  = "$(k)_t_$(i)"
                    end
                end
            end
    end
    return time_slices_tempblock
end
