@testset "benchmark_input_data" begin
    previous_project_dir = dirname(Base.active_project())
    Pkg.activate(joinpath(@__DIR__, "..","benchmark"))
    Pkg.instantiate()
    include(joinpath(@__DIR__, "..", "benchmark", "benchmarks.jl"))
    m = run_spineopt(url_in_basic, url_out_basic; log_level=3, optimize=false)
    @test typeof(m) == Model
    Pkg.activate(previous_project_dir)
end