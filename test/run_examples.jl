# Examples that we want to check the objective function value
objective_function_reference_values = Dict(
    "6_unit_system.json" => 6.966879153985747e6,
    "reserves.json" => 175971.42857142858,
    "simple_system.json" => 160714.28571428574,
    "unit_commitment.json" => 98637.42857142858,
    "rolling_horizon.json" => 65164.8571429,
    "multi-year_investment_with_econ_discounting_milestones.json" => 71820715.12725478,
    "multi-year_investment_with_econ_discounting_consecutives.json" => 71720404.84378022,
    "multi-year_investment_without_econ_discounting.json" => 131520100.0,
    "capacity_planning.json" => 328503000.0,
    "stochastic.json" => 126964.2857142857,
)

@testset for (file, obj_fn_val) in objective_function_reference_values
    path = joinpath(dirname(@__DIR__), "examples", file)
    input_data = JSON.parsefile(path, use_mmap=false)
    db_url = "sqlite://"
    SpineInterface.close_connection(db_url)
    SpineInterface.open_connection(db_url)
    import_data(db_url, input_data, "No comment")
    m = run_spineopt(db_url, nothing; log_level=0, upgrade=true)
    @test termination_status(m) == MOI.OPTIMAL
    mip_cases = ("6_unit_system.json", "unit_commitment.json")
    if file in mip_cases
        @test abs(objective_value(m) - obj_fn_val) / obj_fn_val ≤ 0.01 
    else
        @test abs(objective_value(m) - obj_fn_val) < 1e-4
    end
end
