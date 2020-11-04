#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    add_variable!(m::Model, name::Symbol, indices::Function; <keyword arguments>)

Add a variable to `m`, with given `name` and indices given by interating over `indices()`.

# Arguments

- `lb::Union{Function,Nothing}=nothing`: given an index, return the lower bound.
- `ub::Union{Function,Nothing}=nothing`: given an index, return the upper bound.
- `bin::Union{Function,Nothing}=nothing`: given an index, return whether or not the variable should be binary
- `int::Union{Function,Nothing}=nothing`: given an index, return whether or not the variable should be integer
- `fix_value::Union{Function,Nothing}=nothing`: given an index, return a fix value for the variable of nothing
"""
function add_variable!(
        m::Model, 
        name::Symbol,
        indices::Function;
        lb::Union{Function,Nothing}=nothing,
        ub::Union{Function,Nothing}=nothing,
        bin::Union{Function,Nothing}=nothing,
        int::Union{Function,Nothing}=nothing,
        fix_value::Union{Function,Nothing}=nothing
    )
    m.ext[:variables_definition][name] = Dict{Symbol,Union{Function,Nothing}}(
        :indices => indices, :lb => lb, :ub => ub, :bin => bin, :int => int, :fix_value => fix_value
    )
    var = m.ext[:variables][name] = Dict(
        ind => _variable(m, name, ind, lb, ub, bin, int) 
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
    )
    ( (bin != nothing) || (int != nothing) ) && push!(m.ext[:integer_variables], name)
end

"""
    _base_name(name, ind)

Create JuMP `base_name` from `name` and `ind`.
"""
_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

"""
    _variable(m, name, ind, lb, ub, bin, int)

Create a JuMP variable with the input properties.
"""
function _variable(m, name, ind, lb, ub, bin, int)
    var = @variable(m, base_name=_base_name(name, ind))
    lb != nothing && set_lower_bound(var, lb(ind))
    ub != nothing && set_upper_bound(var, ub(ind))
    bin != nothing && bin(ind) && set_binary(var)
    int != nothing && int(ind) && set_integer(var)
    var
end


function relax_integer_vars(m::Model)
    for name in m.ext[:integer_variables]
        def = m.ext[:variables_definition][name]        
        bin = def[:bin]
        int = def[:int]
        var = m.ext[:variables][name]
        for ind in def[:indices](m; t=vcat(history_time_slice(m), time_slice(m)))            
            if end_(ind.t) <= end_(current_window(m))
                @info name ind var typeof(ind) typeof(var)                
                fix(var[ind], _variable_value(var[ind]); force=true)
            end
            bin != nothing && bin(ind) && unset_binary(var[ind])
            int != nothing && int(ind) && unset_integer(var[ind])
        end
    end
end


function unrelax_integer_vars(m::Model)
    for name in m.ext[:integer_variables]
        def = m.ext[:variables_definition][name]        
        bin = def[:bin]
        int = def[:int]
        indices = def[:indices]
        for ind in indices(m; t=vcat(history_time_slice(m), time_slice(m)))
            var = m.ext[:variables][name]
            bin != nothing && bin(ind) && set_binary(var[ind])
            int != nothing && int(ind) && set_integer(var[ind])
        end        
    end
    refix_integer_variables(m)                    
end


"""
Refix all integer and binary variables to original fix_values that were previously fixed to obtain dual solution
"""
function refix_integer_variables!(m::Model)
    for name in m.ext[:integer_variables]    
        definition = m.ext[:variables_definition][name]
        _fix_variable!(m, name, definition[:indices], definition[:fix_value])
    end
end