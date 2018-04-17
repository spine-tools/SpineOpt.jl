"""
    JuMPout(dict, keys...)

Assign the value within `dict` of each key in `keys` to a variable named after that key.

# Example
```julia
julia> @JuMPout(jfo, pmax, pmin);
julia> pmax == jfo["pmax"]
true
julia> pmin == jfo["pmin"]
true
```
"""
macro JuMPout(dict, keys...)
    kd = [:($key = $dict[$(string(key))]) for key in keys]
    expr = Expr(:block, kd...)
    esc(expr)
end

"""
    JuMPout_suffix(dict, suffix, keys...)

Like [`@JuMPout(dict, keys...)`](@ref) but appending `suffix` to the variable name.

# Example
```julia
julia> @JuMPout_suffix(jfo, _new, pmax, pmin);
julia> pmax_new == jfo["pmax"]
true
julia> pmin_new == jfo["pmin"]
true
```
"""
macro JuMPout_suffix(dict, suffix, keys...)
    kd = [:($(Symbol(key, suffix)) = $dict[$(string(key))]) for key in keys]
    expr = Expr(:block, kd...)
    esc(expr)
end


"""
    JuMPout_with_backup(dict, backup, keys...)

Like [`@JuMPout(dict, keys...)`](@ref) but also looking into `backup` if the key is not in `dict`.
"""
macro JuMPout_with_backup(dict, backup, keys...)
    kd = [:($key = haskey($dict, $(string(key)))?$dict[$(string(key))]:$backup[$(string(key))]) for key in keys]
    expr = Expr(:block, kd...)
    esc(expr)
end

"""
    JuMPin(dict, vars...)

Assign the value of each variable in `vars` to a key in `dict` named after that variable.

# Example
```julia
julia> @JuMPin(jfo, pgen, vmag);
julia> jfo["pgen"] == pgen
true
julia> jfo["vmag"] == vmag
true
```
"""
macro JuMPin(dict, vars...)
    kd = [:($dict[$(string(var))] = $var) for var in vars]
    expr = Expr(:block, kd...)
    esc(expr)
end

function extend_parameter(par::Dict, rel::Dict)
    Dict(k => par[v] for (k,v) in rel)
end

function extend_parameter!(ref::Dict, par::String, rel::String)
    ref[par] = extend_parameter(ref[par], ref[rel])
end
