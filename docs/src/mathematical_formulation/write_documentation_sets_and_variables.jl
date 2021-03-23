using CSV
using DataFrames

function write_documentation_sets_variables()
    variables = DataFrame(CSV.File("$(@__DIR__)/variables.csv"))
    variables.index .= replace.(variables.index, r"node="=>"")
    variables.index .= replace.(variables.index, r"unit="=>"")
    variables.index .= replace.(variables.index, r"connection="=>"")
    variables.index .= replace.(variables.index, r"direction="=>"")
    variables.index .= replace.(variables.index, r"stochastic_scenario="=>"")
    variables.index .= replace.(variables.index, r"t="=>"")
    variables.index .= replace.(variables.index, r"i="=>"")
    variables.variable_name .= replace.(variables.variable_name, r"_"=>"\\_")
    variables.variable_name .= "``v_{" .* variables.variable_name .* "}" .* variables.index .* "``"
    variables.index .= replace.(variables.index, r"node="=>"")
    variables.index .= replace.(variables.index, r"unit="=>"")
    variables.index .= replace.(variables.index, r"connection="=>"")
    variables.index .= replace.(variables.index, r"direction="=>"")
    variables.index .= replace.(variables.index, r"stochastic_scenario="=>"")
    variables.index .= replace.(variables.index, r"t="=>"")
    variables.index .= replace.(variables.index, r"i="=>"")
    variables.indices .= replace.(variables.indices, r"_"=>"\\_")
    variable_string = "# Variables \n"
    variable_string = string(variable_string,"| Variable name  | Description |  \n")
    variable_string = string(variable_string, "| :--------------------| :------------------- | \n")
    sets = dropmissing(DataFrame(CSV.File("$(@__DIR__)/sets.csv")))#
    # variables = DataFrame(CSV.File("$(@__DIR__)/variables.csv"))
    sets.indices .= replace.(sets.indices, r"_"=>"\\_")
    sets.index .= replace.(sets.index, r"_"=>"\\_")
    sets.index .= replace.(sets.index, r"node="=>"")
    sets.index .= replace.(sets.index, r"unit="=>"")
    sets.index .= replace.(sets.index, r"connection="=>"")
    sets.index .= replace.(sets.index, r"direction="=>"")
    sets.index .= replace.(sets.index, r"stochastic\\_scenario="=>"")
    sets.index .= replace.(sets.index, r"t="=>"")
    sets.index .= replace.(sets.index, r"i="=>"")
    set_string = "# Sets \n"
    set_string = string(set_string,"| Name | Description | \n")
    set_string = string(set_string, "| :--------------------| :------------------- | \n")
    for i = 1:size(sets,1)
        if !isempty(findall(x -> x==sets.indices[i],variables.indices))
            indexed_variables = join(variables.variable_name[findall(x -> x==sets.indices[i],variables.indices)],",")
            set_string =  string(set_string,"| ``$(sets.index[i]) \\in $(sets.indices[i])`` | Indices of the variable(s) $(indexed_variables) | \n")
        else
            set_string =  string(set_string,"| ``$(sets.index[i]) \\in $(sets.indices[i])`` | $(sets.Description[i]) | \n")
        end
    end

    for i = 1:size(variables,1)
        variable_string =  string(variable_string, "| $(variables.variable_name[i]) | $(variables.description[i]) | \n")
    end

    io = open("$(@__DIR__)/variables.md", "w");
    write(io, variable_string)
    close(io)

    io = open("$(@__DIR__)/sets.md", "w");
    write(io, set_string)
    close(io)

    io = open("$(@__DIR__)/variables__forlatex.csv", "w");
    write(io, join(variables.variable_name,"\n"))
    close(io)

    io = open("$(@__DIR__)/sets__forlatex.csv", "w");
    write(io, join(sets.index,"\t",sets.indices,"\n"))
    close(io)


end

#
## insert | before every column
