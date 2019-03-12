module Temporals

# Load required packages
using Revise
using SpineModel
using Dates
db_url = "sqlite:///C:/Users/u0122387/Desktop/toolbox/projects/temporal_structure/input_timestorage/input_temporal2.sqlite"
JuMP_all_out(db_url)
duration = Dict()
start_date = Dict()
end_date = Dict()
time_slice = Dict()
difference_start_end = Dict()
start_overlapp = Dict()
end_overlapp = Dict()
overlapping_timeslices = Dict()
time_slice_succeed = Dict()
for k in temporal_block()
    duration[k] = Millisecond(Day(time_slice_duration()[k][3])) + Millisecond(Hour(time_slice_duration()[k][4])) +
                    + Millisecond(Minute(time_slice_duration()[k][5])) + Millisecond(Second(time_slice_duration()[k][6]))

    start_date[k] = DateTime(start_datetime()[k][1],(start_datetime()[k][2]),
                                (start_datetime()[k][3]),(start_datetime()[k][4]),
                                    (start_datetime()[k][5]),    (start_datetime()[k][6]))

    end_date[k] = DateTime(end_datetime()[k][1],(end_datetime()[k][2]),
                                (end_datetime()[k][3]),(end_datetime()[k][4]),
                                    (end_datetime()[k][5]),    (end_datetime()[k][6]))
    @show difference_start_end[k] = end_date[k] - start_date[k]
    time_slice[k] = collect(start_date[k]:duration[k]:end_date[k])
end

######
start_intersect = Dict()
map_arg1_lowerarg2 = Dict()
time_slice_overlapp= Dict()
map_with_tempblock = Dict()
for m in temporal_block()
    for n in temporal_block()
        if m !=n
        start_intersect[m,n] = intersect(time_slice[m], time_slice[n])
        if duration[m] < duration[n]
            i = 1
            for j = 1:length(start_intersect[m,n]) ## hier muss abfrage hinj
                for i = 1:length(time_slice[m])
                    if start_intersect[m,n][j] < time_slice[m][i] < start_intersect[m,n][j] + duration[n]
                    @show map_arg1_lowerarg2[time_slice[m][i]] = time_slice[n][j]
                    map_with_tempblock[m,n,time_slice[m][i]] = time_slice[n][j]
                    end
                end
            end
        end
    end
    end
end

###succeed?
end
