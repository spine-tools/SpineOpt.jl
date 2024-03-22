# Examples that we want to check the objective function value
objective_function_reference_values = Dict(
    "6_unit_system.json" => 6.966879153985747e6,
    "reserves.json" => 175971.42857142858,
    "simple_system.json" => 160714.28571428574,
    "unit_commitment.json" => 98637.42857142858
)

@testset for path in readdir(joinpath(dirname(@__DIR__), "examples"); join=true)
    if splitext(path)[end] == ".json"
        input_data = JSON.parsefile(path)
        m = run_spineopt(input_data, nothing; log_level=3)        
        @test termination_status(m) == MOI.OPTIMAL
        if haskey(objective_function_reference_values, basename(path))
            @test abs(objective_value(m) - objective_function_reference_values[basename(path)]) < 1e-4
        end
    end
end
