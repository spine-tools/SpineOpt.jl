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
### finding overlapping time_slices
for m in temporal_block()
    for n in temporal_block()
        if n != m
        if (start_date[m] > end_date[n] || end_date[m] < start_date[n])
            @show  start_overlapp[m,n] = []
        else
            if start_date[m] <= start_date[n]
                start_overlapp[m,n] = findmin(time_slice[m]-start_date[n])[2]
                ##return the position of m in which the overlap start (ToDo: ensure )
                if end_date[m] <= end_date[n]
                    end_overlapp[m,n] = findlast(time_slice[m])
                elseif end_date[m] > end_date[n]
                    end_overlapp[m,n] = findmax((time_slice[m]-end_date[n]))[2]
                end
            else start_date[m] > start_date[n]
                start_overlapp[m,n] = findmin(time_slice[m]-start_date[n])[2]
                ##return the position of m in which the overlap start (ToDo: ensure )
                if end_date[m] <= end_date[n]
                    end_overlapp[m,n] = findlast(time_slice[m])
                elseif end_date[m] > end_date[n]
                    end_overlapp[m,n] = findmax((time_slice[m]-end_date[n]))[2]
                end
        end
        overlapping_timeslices[m,n] = time_slice[m][start_overlapp[m,n]:end_overlapp[m,n]]
    end
    end
    end
end
### directly succeeding timestep

for k in temporal_block()
    time_slice_succeed[k] = collect(start_date[k]+duration[k]:duration[k]:end_date[k]+duration[k])
end

### für die direkt aufeinander folgenden dinger muss ich mir nur die overlapps angucken -> nur hier kann was passieren
t_before_t = Dict()
for k in temporal_block()
    for m in temporal_block()
        for i = 1:length(time_slice[k])
            if k == m
                t_before_t[k,m] = collect(start_date[k]+duration[k]:duration[k]:end_date[k]+duration[k])
            else
                if start_date[k] = end_date[m] + duration[m]
                t_before_t[k,m] =
    end
    end
end
t_t_below = Dict()
###time_slice_map
for k in temporal_block()
    for m in temporal_block()
        if duration[k] < duration[m]
            t_t_below[k,m] = overlapping_timeslices[k,m]
            #was ich eigentlich will t_t_below(timeslice1,timeslice2)?
        end
    end
end
