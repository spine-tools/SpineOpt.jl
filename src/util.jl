"""
    unpack(dict, keys...)

Unpack keys from dict into variables
"""
macro unpack(dict, keys...)
    kd = [:($key = $dict[$(string(key))]) for key in keys]
    expr = Expr(:block, kd...)
    esc(expr)
end

macro unpack_with_suffix(ref, suffix, keynames...)
    kd = [:($(Symbol(key, suffix)) = $ref[$(string(key))]) for key in keynames]
    expr = Expr(:block, kd...)
    esc(expr)
end

macro unpack_with_backup(ref, bck, keynames...)
    kd = [:($key = haskey($ref, $(string(key)))?$ref[$(string(key))]:$bck[$(string(key))]) for key in keynames]
    expr = Expr(:block, kd...)
    esc(expr)
end

"""
pack variables into dictionary
"""
macro pack(ref, keynames...)
    kd = [:($ref[$(string(key))] = $key) for key in keynames]
    expr = Expr(:block, kd...)
    esc(expr)
end

function extend_parameter(par::Dict, rel::Dict)
    Dict(k => par[v] for (k,v) in rel)
end

function extend_parameter!(ref::Dict, par::String, rel::String)
    ref[par] = extend_parameter(ref[par], ref[rel])
end
