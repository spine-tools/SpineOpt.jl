"""
    JuMPout(dict, keys...)

Create a variable named after each one of `keys`, by taking its value from `dict`.

# Example
```julia
julia> @JuMPout(jfo, capacity, node);
julia> node == jfo["node"]
true
julia> capacity == jfo["capacity"]
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
Useful when working with several systems at a time.

# Example
```julia
julia> @JuMPout_suffix(jfo, _new, capacity, node);
julia> capacity_new == jfo["capacity"]
true
julia> node_new == jfo["node"]
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

Create one key in `dict` named after each one of `vars`, by taking the value from that variable.

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
