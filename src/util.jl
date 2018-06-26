"""
    JuMPout(dict, keys...)

Copy the value in `dict` of each one of `keys...` into a variable named after it.

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

macro JuMPout_prefix(dict, prefix, keys...)
    kd = [:($(Symbol(prefix, key)) = $dict[$(string(key))]) for key in keys]
    expr = Expr(:block, kd...)
    esc(expr)
end

macro JuMPout_all_suffix(dict, suffix, keys...)
    kd = [:($(Symbol(key, suffix)) =
        isa($dict[$(string(key))], Dict)?
        Dict(string(k, $suffix) => isa(v, Array)?[string(i, $suffix) for i in v]:string(v, $suffix) for (k,v) in $dict[$(string(key))]):
        isa($dict[$(string(key))], Array)?[string(item, $suffix) for item in $dict[$(string(key))]]:nothing
    ) for key in keys]
    expr = Expr(:block, kd...)
    esc(expr)
end

macro JuMPout_key_suffix(dict, suffix, keys...)
    kd = [:($(Symbol(key, suffix)) =
        isa($dict[$(string(key))], Dict)?
        Dict(string(k, $suffix) => v for (k,v) in $dict[$(string(key))]):
        isa($dict[$(string(key))], Array)?[string(item, $suffix) for item in $dict[$(string(key))]]:nothing
    ) for key in keys]
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

Copy the value of each one of `vars` into a key in `dict` named after it.

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


"""
    pass_parameter!(parameter::Dict{String,Any}, to_object::Array{String,1}, by_relationship::Dict{String,Any})

Update `parameter` with values for all objects in `to_object`. Values are 'passed' from the related objects in
`by_relationships`.
"""
function pass_parameter!(
        parameter::Dict{String,T},
        to_object::Array{String,1},
        by_relationship::Dict{String,Any}) where T
    for object in to_object
        related_object = by_relationship[object]
        isa(related_object, Array) && error(
            object,
            " is related to more than one object via ",
            relationship
        )
        parameter[object] = parameter[related_object]
    end
end

function extended_relationship(
        to_object::Array{String,1},
        by_relationship::Dict{String,<:Any},
        relationship::Dict{String,<:Any}
    )
    extended = Dict{String,Any}()
    for object in to_object
        haskey(by_relationship, object) || continue
        related_object = by_relationship[object]
        if isa(related_object, Array)
            extended[object] = vcat([relationship[o] for o in related_object if haskey(relationship, o)]...)
        elseif haskey(relationship, related_object)
            extended[object] = relationship[related_object]
        end
    end
    extended
end

function scale_parameter!(jfo::Dict, factor, parameters::String...)
    for parameter in parameters
        for (key,value) in jfo[parameter]
            jfo[parameter][key] = factor * value
        end
    end
end

# Borrowd from Suppressor.jl

"""
    @suppress_err expr
Suppress the STDERR stream for the given expression.
"""
macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end
    end
end
