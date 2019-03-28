function time_slicemap()
    time_slicemap = []
    duration = []
    time_slicemap_detail = []
    for k in temporal_block()
        if time_slice_duration()[k][2] == nothing
            for x in collect(start_date(k):Minute(time_slice_duration()[k][1]):end_date(k)-Minute(time_slice_duration()[k][1]))
                time_slice_symbol = Symbol("t_$(year(x))_$(month(x))_$(day(x))_$(hour(x))_$(minute(x))__$(year(x+Minute(time_slice_duration()[k][1])))_$(month(x+Minute(time_slice_duration()[k][1])))_$(day(x+Minute(time_slice_duration()[k][1])))_$(hour(x+Minute(time_slice_duration()[k][1])))_$(minute(x+Minute(time_slice_duration()[k][1])))")
                time_slicemap = push!(time_slicemap,time_slice_symbol)
                duration = push!(duration,Tuple([time_slice_symbol, (Minute(time_slice_duration()[k][1]))]))
                time_slicemap_detail = push!(time_slicemap_detail,Tuple([x,x+Minute(time_slice_duration()[k][1])]))
            end
        else
            x = start_date(k)
            for j = 1:(length(time_slice_duration()[k])-1)
                time_slice_symbol = Symbol("t_$(year(x))_$(month(x))_$(day(x))_$(hour(x))_$(minute(x))__$(year(x+Minute(time_slice_duration()[k][j])))_$(month(x+Minute(time_slice_duration()[k][j])))_$(day(x+Minute(time_slice_duration()[k][j])))_$(hour(x+Minute(time_slice_duration()[k][j])))_$(minute(x+Minute(time_slice_duration()[k][j])))")
                time_slicemap = push!(time_slicemap,time_slice_symbol)
                duration = push!(duration,Tuple([time_slice_symbol, (Minute(time_slice_duration()[k][j]))]))
                time_slicemap_detail = push!(time_slicemap_detail,Tuple([time_slice_symbol,x,x+Minute(time_slice_duration()[k][1])]))
                x = x+Minute(time_slice_duration()[k][j])
            end
            if x != end_date(k)
                @warn "WARNING: Last timeslice of $k doesn't coinside with defined enddate for temporalblock $k"
            end
        end
    end
    unique!(time_slicemap)
    time_slicemap, duration, time_slicemap_detail
end
