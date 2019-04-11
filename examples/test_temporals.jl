### tesystem temporals
db_url = "sqlite:///$(@__DIR__)/data/new_temporal.sqlite"
out_file = "$(@__DIR__)/data/new_temporal_out.sqlite"
include("../src/run_spinemodel.jl")
