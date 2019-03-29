# Write model to file
model_string = "$m"
open(joinpath(@__DIR__, "model.so_model"), "w") do file
    write(file, model_string)
end
