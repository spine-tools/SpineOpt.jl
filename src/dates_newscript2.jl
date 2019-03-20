# Load required packaes
using Revise
using SpineModel
using Base.Dates

# Export contents of database into the current session
db_url = "sqlite:///C:/Users/u0122387/Desktop/toolbox/projects/temporal_structure/input_timestorage/new_temporal.sqlite"
JuMP_all_out(db_url)

### time_slices (Liste mit allen namen)
struct time_slices
           name::String
           Start_Date::DateTime
           End_Date::DateTime
           duration::Float64
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


time_slicemap = Dict()
time_slices_tempblock = Dict()
### time_slice_duration()
for k in temporal_block()
    time_slices_tempblock[k] = Dict()
        ## unterscheidung ob duration einzel wert ist oder mehrere
        if length(time_slice_duration()[k])==1
            test = collect(start_date(k):Minute(time_slice_duration()[k][1]):end_date(k))
            @show length(test)
            for i = 1: length(test)
            if i == 1
            time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
            time_slices_tempblock[k]["$(k)_t_$(i)"] = time_slicemap["$(k)_t_$(i)"]
            else
            time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][1]),Minute(time_slice_duration()[k][1]))
            time_slices_tempblock[k]["$(k)_t_$(i)"] = time_slicemap["$(k)_t_$(i)"]
            end
            end
        else
            for i = 1: length(time_slice_duration()[k])
                if i == 1
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",start_date(k),start_date(k)+Minute(time_slice_duration()[k][i]),Minute(time_slice_duration()[k][i]))
                time_slices_tempblock[k]["$(k)_t_$(i)"] = time_slicemap["$(k)_t_$(i)"]
                else
                time_slicemap["$(k)_t_$(i)"] =  time_slices("$(k)_t_$(i)",time_slicemap["$(k)_t_$(i-1)"].End_Date,time_slicemap["$(k)_t_$(i-1)"].End_Date+Minute(time_slice_duration()[k][i]),+Minute(time_slice_duration()[k][i]))
                time_slices_tempblock[k]["$(k)_t_$(i)"]  = time_slicemap["$(k)_t_$(i)"]
                end
            end
        end
end

t_in_t = Dict()
t_above_t = Dict()
for i in keys(time_slicemap)
    t_in_t[i] = Dict()
    for j in keys(time_slicemap)
        t_above_t[j] = Dict()
        if time_slicemap[i].Start_Date >= time_slicemap[j].Start_Date && time_slicemap[i].End_Date <= time_slicemap[j].End_Date
            if i != j
            t_in_t[i][j] = [time_slicemap[i] , time_slicemap[j]]
            t_above_t[j][i] = [time_slicemap[j] , time_slicemap[i]]
            end
        end
end
end


### t_t_overlapp (alle Zeitschritte die Zeit geminsam haben)
n=1
t_t_overlapp = Dict()
t_t_test = Dict()
for i in keys(time_slicemap)
    t_t_overlapp[i] = Dict()
    for j in keys(time_slicemap)
        t_t_overlapp[j] = Dict()
        if (time_slicemap[i].Start_Date >= time_slicemap[j].Start_Date) && (time_slicemap[i].Start_Date < time_slicemap[j].End_Date) && (i!=j)
                t_t_overlapp[i][j] = [time_slicemap[i] , time_slicemap[j]]
                t_t_overlapp[j][i] = [time_slicemap[j] , time_slicemap[i]]
        end
    end
end
####??? check t_t_overlapp
### t_in_t (alle Zeitschritte die innerhalb eines anderen liegen)

### t_before_t (gibt zu jedem Zeitschritt denjendigen raus, der genau davor ist)

t_before_t = Dict()
t_after_t = Dict()
for i in keys(time_slicemap)
    t_before_t[i] = Dict()
    for j in keys(time_slicemap)
        t_after_t[j] = Dict()
        if time_slicemap[i].End_Date == time_slicemap[j].Start_Date
            t_before_t[i][j] = [time_slicemap[i] , time_slicemap[j]]
            t_after_t[j][i] = [time_slicemap[j] , time_slicemap[i]]
        end
    end
end

### time_slices_map ?
# timeslice name -> duration, start_Date, end_date
# time_slice1 = time_slices("time_slice1",DateTime(2013,7,1,12,30,59,1), DateTime(2013,7,1,12,30,59,1),30.00)


filter((x,y)->isequal(x,"half-hour_t_1"), t_in_t)
