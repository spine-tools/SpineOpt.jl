function generate_t_in_t(timeslicemap)
@butcher t_in_t = Dict()
for i in keys(timeslicemap)
    t_in_t[i] = Dict()
    for j in keys(timeslicemap)
        if timeslicemap[j].Start_Date >= timeslicemap[i].Start_Date && timeslicemap[j].End_Date <= timeslicemap[i].End_Date
            t_in_t[i][j] = [timeslicemap[i] , timeslicemap[j]]
        end
    end
end
return t_in_t
end
### TO DO
## check
#=
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
=#
