function generate_t_in_t_excl(timeslicemap)
@butcher t_in_t = Dict()
for i in keys(timeslicemap)
    t_in_t[i] = Dict()
    for j in keys(timeslicemap)
        if timeslicemap[i].Start_Date >= timeslicemap[j].Start_Date && timeslicemap[i].End_Date <= timeslicemap[j].End_Date
            if i != j
            t_in_t[i][j] = [timeslicemap[i] , timeslicemap[j]]
            end
        end
    end
end
return t_in_t
end
