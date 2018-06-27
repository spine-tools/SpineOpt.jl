module SpineModel

export JuMP_object
# export run_dc_pf!, run_ac_pf!, run_ac_opf!
export @JuMPout, @JuMPout_prefix,  @JuMPout_suffix, @JuMPout_key_suffix, @JuMPout_all_suffix,
    @JuMPout_with_backup, @JuMPin, pass_parameter!, scale_parameter!

using SpineData
using Missings
using JuMP
using Ipopt
using Clp
using DataFrames
using Query
using Clustering
using ODBC
using SQLite
using JSON
using Clp

include("util.jl")
include("data/jfo.jl")
include("data/helpers.jl")
# include("data/Sink.jl")
# include("pf/pf.jl")
# include("aggregation/base.jl")
# include("aggregation/util.jl")
# include("aggregation/power.jl")
# include("aggregation/PTDF.jl")
# include("aggregation/Ward.jl")

# NOTE: The method below overrides the one from DataFrames, so that ODBC.query doesn't fail whenever the driver returns -1 on getRowsCount()
# function Data.Schema(types::Array{Type,1}=(), header=["Column$i" for i = 1:length(types)], rows::Union{Integer,Missing}=0, metadata::Dict=Dict())
#     rows == -1 && (rows = 100)
#     !ismissing(rows) && rows < 0 && throw(ArgumentError("Invalid # of rows for Data.Schema; use `nothing` to indicate an unknown # of rows"))
#     types2 = Tuple(types)
#     header2 = String[string(x) for x in header]
#     cols = length(header2)
#     cols != length(types2) && throw(ArgumentError("length(header): $(length(header2)) must == length(types): $(length(types2))"))
#     return Data.Schema{!ismissing(rows), Tuple{types2...}}(header2, rows, cols, metadata, Dict(n=>i for (i, n) in enumerate(header2)))
# end

# NOTE: The line below is needed for `JuMP_object` to work accros different Julia versions
# Not needed now, since SpineData exports it
# Base.get(x::Any) = x

end
