@testset "benchmark_input_data" begin
    Pkg.activate(joinpath(@__DIR__, "..","benchmark"))
    Pkg.instantiate()
    include(joinpath(@__DIR__, "..", "benchmark", "benchmarks.jl"))
    m = run_spineopt(url_in_basic, url_out_basic; log_level=3, optimize=false)
    @test typeof(m) == Model
end