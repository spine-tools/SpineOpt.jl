#The method below overrides the one from DataFrames, so that ODBC.query doesn't fail whenever the driver returns -1 on getRowsCount()
function Data.Schema(types::Array{Type,1}=(), header=["Column$i" for i = 1:length(types)], rows::Union{Integer,Missing}=0, metadata::Dict=Dict())
    rows == -1 && (rows = 100)
    !ismissing(rows) && rows < 0 && throw(ArgumentError("Invalid # of rows for Data.Schema; use `nothing` to indicate an unknown # of rows"))
    types2 = Tuple(types)
    header2 = String[string(x) for x in header]
    cols = length(header2)
    cols != length(types2) && throw(ArgumentError("length(header): $(length(header2)) must == length(types): $(length(types2))"))
    return Data.Schema{!ismissing(rows), Tuple{types2...}}(header2, rows, cols, metadata, Dict(n=>i for (i, n) in enumerate(header2)))
end

function is_excel(dsn::ODBC.DSN)
    dsns = ODBC.dsns()
    i = findfirst(dsn.dsn .== dsns[:,1])
    contains(lowercase(dsns[i,2]), "excel")
end

is_excel_on_windows(dsn::ODBC.DSN) = @static is_windows()?is_excel(dsn):false

compose_table_name(dsn::ODBC.DSN, tbl::String) = is_excel_on_windows(dsn)?string("[", tbl, "\$]"):tbl

spine2julia = Dict{String,Type}(
    "string" => String,
    "number" => Float64,
    "float" => Float64,
    "integer" => Int64,
    "boolean" => Bool,
    "datetime" => DateTime,
    "any" => String
)
