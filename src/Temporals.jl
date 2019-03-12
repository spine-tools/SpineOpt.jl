module Temporals
using SpineModel
using Base.Dates

function duration()
    duration = Dict()
    for k in temporal_block()
        duration[k] = Millisecond(Day(time_slice_duration()[k][3])) + Millisecond(Hour(time_slice_duration()[k][4])) +
                        + Millisecond(Minute(time_slice_duration()[k][5])) + Millisecond(Second(time_slice_duration()[k][6]))
    end
    return duration
end
function duration(y::Symbol)
    duration = Dict()
        duration = Millisecond(Day(time_slice_duration()[y][3])) + Millisecond(Hour(time_slice_duration()[y][4])) +
                        + Millisecond(Minute(time_slice_duration()[y][5])) + Millisecond(Second(time_slice_duration()[y][6]))
    return duration
end
function start_date()
    start_date = Dict()
    for k in temporal_block()
        start_date[k] = DateTime(start_datetime()[k][1],(start_datetime()[k][2]),
                                    (start_datetime()[k][3]),(start_datetime()[k][4]),
                                        (start_datetime()[k][5]),    (start_datetime()[k][6]))
    end
    return start_date
end
function start_date(k::Symbol)
    start_date = Dict()
    start_date = DateTime(start_datetime()[k][1],(start_datetime()[k][2]),
                                (start_datetime()[k][3]),(start_datetime()[k][4]),
                                    (start_datetime()[k][5]),    (start_datetime()[k][6]))
    return start_date
end
function end_date()
    end_date = Dict()
    for k in temporal_block()
        end_date[k] = DateTime(end_datetime()[k][1],(end_datetime()[k][2]),
                                    (end_datetime()[k][3]),(end_datetime()[k][4]),
                                        (end_datetime()[k][5]),    (end_datetime()[k][6]))
    end
    return end_date
end
function end_date(k::Symbol)
    end_date = Dict()
    end_date = DateTime(end_datetime()[k][1],(end_datetime()[k][2]),
                                (end_datetime()[k][3]),(end_datetime()[k][4]),
                                    (end_datetime()[k][5]),    (end_datetime()[k][6]))
    return end_date
end



function time_slice()
time_slice = Dict()
for k in temporal_block()
    time_slice[k] = collect(start_date(k):duration(k):end_date(k))
end
return time_slice
end

function time_slice(k::Symbol)
time_slice = Dict()
time_slice = collect(start_date(k):duration(k):end_date(k))
return time_slice
end


######
function t_in_t(m::Symbol,n::Symbol)
start_intersect = Dict()
map_arg1_lowerarg2 = Dict()
start_intersect[m,n] = intersect(time_slice(m), time_slice(n))
    if duration(m) < duration(n)
        i = 1
        for j = 1:length(start_intersect[m,n])
            for i = 1:length(time_slice(m))
                if start_intersect[m,n][j] < time_slice(m)[i] < start_intersect[m,n][j] + duration(n)
                map_arg1_lowerarg2[time_slice(m)[i]] = time_slice(m)[j]
                end
            end
        end
    end
    return map_arg1_lowerarg2
end

function t_before_t(m::Symbol,n::Symbol)
t_before = Dict()
if m == n
    for i = 1:length(time_slice(m))
    t_before[time_slice(m)[i]] = collect(start_date(k)+duration(k):duration(k):end_date(k)+duration(k))
end
else
    if start_date(m) == end_date(n) + duration(n)
        t_before[time_slice(m)] = end_date(n)
    end
end
return t_before
end





function t_map()
    ##returns all lower timeslices and their "higher elements"
start_intersect = Dict()
map_arg1_lowerarg2 = Dict()
map_with_tempblock = Dict()
for m in temporal_block()
    for n in temporal_block()
        if m !=n
        start_intersect[m,n] = intersect(time_slice(m), time_slice(n))
            if duration(m) < duration(n)
            i = 1
                for j = 1:length(start_intersect[m,n]) ## hier muss abfrage hinj
                    for i = 1:length(time_slice(m))
                        if start_intersect[m,n][j] < time_slice(m)[i] < start_intersect[m,n][j] + duration(n)
                            map_arg1_lowerarg2[time_slice(m)[i]] = time_slice(m)[j]
                            map_with_tempblock[m,n,time_slice(m)[i]] = time_slice(m)[j]
                        end
                    end
                end
            end
        end
    end
end
return map_arg1_lowerarg2
end

export time_slice
export duration
export start_date
export end_date
export t_map
export t_in_t
export t_before_t
end
