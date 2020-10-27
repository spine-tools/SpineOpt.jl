using JSON
s="$(@__DIR__)\\..\\..\\data\\spineopt_template.json"
parsed_json = JSON.parsefile(s)
pj=parsed_json
function writing_systemcomponentsfile(pj::Dict; file_name="systemcomponents.md")
    system_string=[]
    push!(system_string,"# System Components\n\n")
    for k in ["object_classes",]
        push!(system_string,"## $(k)\n\n")
        for j in 1:length(pj[k])
            push!(system_string,"### `$(pj[k][j][1])`\n\n")
            push!(system_string,"$(pj[k][j][2])\n\n")
        end
    end
    for k in ["relationship_classes",]
        push!(system_string,"## $(k)\n\n")
        for j in 1:length(pj[k])
            push!(system_string,"### `$(pj[k][j][1])`\n\n")
            push!(system_string,"**Relates object classes:** `$(join([pj[k][j][2]...],repeat([",",],length(pj[k][j][2])-1)...))`\n\n")
            push!(system_string,"$(pj[k][j][3])\n\n")
        end
    end

    for k in ["object_parameters" ,]
        push!(system_string,"## $(k)\n\n")
        for j in 1:length(pj[k])
            push!(system_string,"### `$(pj[k][j][2])`\n\n")
            push!(system_string,"**Object class:** [`$(pj[k][j][1])`](#$(pj[k][j][1]))\n\n")
            pj[k][j][3] != nothing && push!(system_string,"**Default value:** `$(pj[k][j][3])`\n\n")
            pj[k][j][4] != nothing && push!(system_string,"**Parameter value list:** [`$(pj[k][j][4])`](#$(pj[k][j][4]))\n\n")
            pj[k][j][5] != nothing && push!(system_string,"$(pj[k][j][5])\n\n")
        end
    end

    for k in ["relationship_parameters" ,]
        push!(system_string,"## $(k)\n\n")
        for j in 1:length(pj[k])
            push!(system_string,"### `$(pj[k][j][2])`\n\n")
                        push!(system_string,"**Relationship class**: [`$(pj[k][j][1])`](#$(pj[k][j][1]))\n\n")
            pj[k][j][3] != nothing && push!(system_string,"**Default value**: `$(pj[k][j][3])`\n\n")
            pj[k][j][4] != nothing && push!(system_string,"**Parameter value list**: [`$(pj[k][j][4])`](#$(pj[k][j][4]))\n\n")
            pj[k][j][5] != nothing && push!(system_string,"$(pj[k][j][5])\n\n")
        end
    end

    for k in ["parameter_value_lists" ,]
        push!(system_string,"## $(k)\n\n")
        for j in 1:length(pj[k])
        #unique([x[1] for x in pj["parameter_value_lists" ,]])
            if j > 1 && pj[k][j][1] == pj[k][j-1][1]
                pj[k][j][2] != nothing && push!(system_string,"**Value**: `$(pj[k][j][2])`\n\n")
            else
                push!(system_string,"### `$(pj[k][j][1])`\n\n")
                pj[k][j][2] != nothing && push!(system_string,"**Value**: `$(pj[k][j][2])`\n\n")
            end

        end
    end

    system_string=join(system_string)
    #system_string = replace(system_string,"_" => "\\_")
    open(joinpath(@__DIR__, "$(file_name)"), "w") do file
    write(file, system_string)
    close(file)
    end
end
writing_systemcomponentsfile(parsed_json)
