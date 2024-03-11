@testset for path in readdir(joinpath(dirname(@__DIR__), "examples"); join=true)
    if splitext(path)[end] == ".json"
        input_data = JSON.parsefile(path)
        @test termination_status(run_spineopt(input_data, nothing; log_level=3)) == MOI.OPTIMAL
    end
end