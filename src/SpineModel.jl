module SpineModel

export run_dc_pf!, run_ac_pf!
export JuMP_object
export @JuMPout, @JuMPout_suffix, @JuMPout_with_backup, @JuMPin, extend_parameter!

using SpineData
using Missings
using JuMP
using Ipopt
using DataFrames
using Query
using Clustering
using ODBC
using SQLite

include("util.jl")
include("data/jfo.jl")
include("data/Sink.jl")
include("data/helpers.jl")
include("pf/pf.jl")
include("aggregation/PTDF.jl")
include("aggregation/Ward.jl")
include("aggregation/common.jl")

# Note: The method below overrides the one from DataFrames, so that ODBC.query doesn't fail whenever the driver returns -1 on getRowsCount()
function Data.Schema(types::Array{Type,1}=(), header=["Column$i" for i = 1:length(types)], rows::Union{Integer,Missing}=0, metadata::Dict=Dict())
    rows == -1 && (rows = 100)
    !ismissing(rows) && rows < 0 && throw(ArgumentError("Invalid # of rows for Data.Schema; use `nothing` to indicate an unknown # of rows"))
    types2 = Tuple(types)
    header2 = String[string(x) for x in header]
    cols = length(header2)
    cols != length(types2) && throw(ArgumentError("length(header): $(length(header2)) must == length(types): $(length(types2))"))
    return Data.Schema{!ismissing(rows), Tuple{types2...}}(header2, rows, cols, metadata, Dict(n=>i for (i, n) in enumerate(header2)))
end

# Note: The line below is needed for `JuMP_object` to work accros different Julia versions
Base.get(x::Any) = x

end
