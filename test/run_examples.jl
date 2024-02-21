for path in readdir(joinpath(dirname(@__DIR__),"examples");join=true)
    if split(path, ".")[end] == "json"
        inputdata = open(path, "r") do f
            dicttxt = read(f,String) # file information to string
            return JSON.parse(dicttxt) # parse and transform data
        end
        @test termination_status(run_spineopt(inputdata;upgrade=true)) == MOI.OPTIMAL
    end
end