function t_in_t_excl(j::String)
t_in_t = Dict()
for i in keys(time_slicemap())
        if time_slicemap()[i].Start_Date >= time_slicemap()[j].Start_Date && time_slicemap()[i].End_Date <= time_slicemap()[j].End_Date
            if i != j
            t_in_t[i] = Dict()
            t_in_t[i] = [time_slicemap()[i] , time_slicemap()[j]]
            end
        end
end
return t_in_t
end
