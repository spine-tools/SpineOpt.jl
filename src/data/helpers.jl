"product of dictionaries"
function prod(x::Dict, y::Dict)
    Dict(k => x[k] * y[k] for k in keys(x) if haskey(y, k))
end
