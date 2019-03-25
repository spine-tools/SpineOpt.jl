function t_in_t()
t_in_t = Dict()
t_above_t = Dict()
for i in keys(time_slicemap())
    t_in_t[i] = Dict()
    for j in keys(time_slicemap())
        t_above_t[j] = Dict()
        if time_slicemap()[i].Start_Date >= time_slicemap()[j].Start_Date && time_slicemap()[i].End_Date <= time_slicemap()[j].End_Date
            if i != j
            t_in_t[i][j] = [time_slicemap()[i] , time_slicemap()[j]]
            t_above_t[j][i] = [time_slicemap()[j] , time_slicemap()[i]]
            end
        end
    end
end
return t_in_t
end
### TO DO
## check
function t_in_t(j::String)
t_in_t = Dict()
for i in keys(time_slicemap())
        if time_slicemap()[i].Start_Date >= time_slicemap()[j].Start_Date && time_slicemap()[i].End_Date <= time_slicemap()[j].End_Date
            t_in_t[i] = Dict()
            t_in_t[i] = [time_slicemap()[i] , time_slicemap()[j]]
        end
end
return t_in_t
end
