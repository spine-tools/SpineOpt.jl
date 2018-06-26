"product of dictionaries"
function Base.:*(x::Dict, y::Dict)
    Dict(k => x[k] * y[k] for k in keys(x) if haskey(y, k))
end

function Base.:*(x::Any, y::Dict)
    Dict(k => x * val for (k, val) in y)
end


function Base.:+(x::Dict, y::Dict)
    Dict(k => x[k] + y[k] for k in keys(x) if haskey(y, k))
end

function Base.:-(x::Dict, y::Dict)
    Dict(k => x[k] - y[k] for k in keys(x) if haskey(y, k))
end

function Base.:/(x::Dict, y::Dict)
    Dict(k => x[k] / y[k] for k in keys(x) if haskey(y, k))
end
