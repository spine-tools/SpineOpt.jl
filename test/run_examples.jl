# Examples that we want to check the objective function value
objective_function_reference_values = Dict(
    "6_unit_system.json" => 6.966879153985747e6,
    "reserves.json" => 175971.42857142858,
    "simple_system.json" => 160714.28571428574,
    "unit_commitment.json" => 98637.42857142858,
    "rolling_horizon.json" => 65164.8571429,
    "multi-year_investment_with_econ_params_with_milestones" => 41025092.819187716,
    "multi-year_investment_with_econ_params_without_milestones" => 71720404.84378022,
    "multi-year_investment_without_econ_params" => 203360142.85714287,
    "capacity_planning" => 352127000,
    "stochastic" => 126964.2857142857,
)

@testset for path in readdir(joinpath(dirname(@__DIR__), "examples"); join=true)
    if splitext(path)[end] == ".json"
        input_data = JSON.parsefile(path, use_mmap=false)
        db_url = "sqlite://"
        SpineInterface.close_connection(db_url)
        SpineInterface.open_connection(db_url)
        import_data(db_url, SpineOpt.template(), "Initialise input DB with SpineOpt template")
        import_data(db_url, input_data, "No comment")
        m = run_spineopt(db_url, nothing; log_level=0, upgrade=true)
        @test termination_status(m) == MOI.OPTIMAL
        obj_fn_val = get(objective_function_reference_values, basename(path), nothing)
        if obj_fn_val !== nothing
            mip_cases = ("6_unit_system.json", "unit_commitment.json")
            if basename(path) in mip_cases
                @test abs(objective_value(m) - obj_fn_val) / obj_fn_val ≤ 0.01 
            else
                @test abs(objective_value(m) - obj_fn_val) < 1e-4
            end
        end
    end
end
