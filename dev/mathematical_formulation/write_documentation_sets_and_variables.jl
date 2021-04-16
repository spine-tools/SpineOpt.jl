using CSV
using DataFrames

function write_documentation_sets_variables()
    variables = DataFrame(CSV.File("$(@__DIR__)/variables.csv"))
    variables[:variable_name_latex] = replace.(variables.variable_name, r"_" => "\\_")
    variables.variable_name_latex .= "``v_{" .* variables.variable_name_latex .* "} ``"
    variables.indices .= replace.(variables.indices, r"_" => "\\_")
    variable_string = "# Variables \n"
    for i in 1:size(variables, 1)
        variable_string = string(variable_string, "## `$(variables.variable_name[i])` \n\n")
        variable_string = string(variable_string, " > **Math symbol:** $(variables.variable_name_latex[i]) \n\n")
        variable_string = string(variable_string, " > **Indices:** $(variables.index[i]) \n\n")
        variable_string = string(variable_string, " > **Indices function:** $(variables.indices[i]) \n\n")
        variable_string = string(variable_string, "$(variables.description[i]) \n\n")
    end
    sets = dropmissing(DataFrame(CSV.File("$(@__DIR__)/sets.csv")))
    set_string = "# Sets \n"
    for i in 1:size(sets, 1)
            set_string = string(set_string, "## `$(sets.indices[i])` \n\n")
            set_string = string(set_string, "$(sets.Description[i]) \n\n")
    end

    io = open("$(@__DIR__)/variables.md", "w")
    write(io, variable_string)
    close(io)

    io = open("$(@__DIR__)/sets.md", "w")
    write(io, set_string)
    close(io)
end
