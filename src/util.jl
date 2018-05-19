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
#macro JuMPout_suffix(dict, suffix, keys...)
#    kd = [:($(Symbol(key, suffix)) = [string(value, $suffix) for value in $dict[$(string(key))]]) for key in keys]
#    expr = Expr(:block, kd...)
#    esc(expr)
#end

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

function extend_parameter!(reference::Dict;
        parameter::String="",
        object::String="",
        relationship::String="")
    for to_object in reference[object]
        from_object = reference[relationship][to_object]
        isa(from_object, Array) && error(
            to_object,
            " is related to more than one object via relationship ",
            relationship
        )
        reference[parameter][to_object] = reference[parameter][from_object]
    end
end

function extend_relationship(relationship::Dict;
        object=Array(),
        with_relationship=Dict()
    )
    new_relationship = Dict()
    for o in object
        new_relationship[o] = Array{Any,1}()
        !haskey(with_relationship, o) && continue
        with_object = with_relationship[o]
        for wo in with_object
            !haskey(relationship, wo) && continue
            relationship_object = relationship[wo]
            if isa(relationship_object, Array)
                for ro in relationship_object
                    push!(new_relationship[o], ro)
                    new_relationship[ro] = o
                end
            else
                push!(new_relationship[o], relationship_object)
                new_relationship[relationship_object] = o
            end
        end
    end
    new_relationship
end
