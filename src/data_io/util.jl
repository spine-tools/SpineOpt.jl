#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


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
