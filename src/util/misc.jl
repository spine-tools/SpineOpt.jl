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
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

# override `get` and `getindex` so we can access our variable dicts with a `Tuple` instead of the actual `NamedTuple`
function Base.get(d::Dict{K,VariableRef}, key::Tuple{Vararg{ObjectLike}}, default) where {J,K<:Relationship{J}}
    Base.get(d, NamedTuple{J}(key), default)
end

function Base.getindex(d::Dict{K,VariableRef}, key::ObjectLike...) where {J,K<:Relationship{J}}
    Base.getindex(d, NamedTuple{J}(key))
end

"""
    @fetch x, y, ... = d

Assign mapping of :x and :y in `d` to `x` and `y` respectively
"""
macro fetch(expr)
    (expr isa Expr && expr.head == :(=)) || error("please use @fetch with the assignment operator (=)")
    keys, dict = expr.args
    values = if keys isa Expr
        Expr(:tuple, [:($dict[$(Expr(:quote, k))]) for k in keys.args]...)
    else
        :($dict[$(Expr(:quote, keys))])
    end
    esc(Expr(:(=), keys, values))
end

expand_unit_group(::Anything) = anything
expand_node_group(::Anything) = anything
expand_commodity_group(::Anything) = anything

function expand_unit_group(ugs::X) where X >: Anything
    (u for ug in ugs for u in unit_group__unit(unit1=ug, _default=ug))
end

function expand_node_group(ngs::X) where X >: Anything
    (n for ng in ngs for n in node_group__node(node1=ng, _default=ng))
end

function expand_commodity_group(cgs::X) where X >: Anything
    (c for cg in cgs for c in commodity_group__commodity(commodity1=cg, _default=cg))
end

macro log(level, msg)
    quote
        if $(esc(level))
            printstyled($(esc(msg)), "\n"; bold=true)
        end
    end
end


macro logtime(level, msg, expr)
    quote
        if $(esc(level))
            @msgtime $(esc(msg)) $(esc(expr))
        else
            $(esc(expr))
        end
    end
end

macro msgtime(msg, expr)
    quote
        printstyled($(esc(msg)); bold=true)
        @time $(esc(expr))
    end
end


sense_constraint(m, lhs, sense::typeof(<=), rhs) = @constraint(m, lhs <= rhs)
sense_constraint(m, lhs, sense::typeof(==), rhs) = @constraint(m, lhs == rhs)
sense_constraint(m, lhs, sense::typeof(>=), rhs) = @constraint(m, lhs >= rhs)

function sense_constraint(m, lhs, sense::Symbol, rhs)
    if sense == :>=
        @constraint(m, lhs >= rhs)
    elseif sense == :<=
        @constraint(m, lhs <= rhs)
    else
        @constraint(m, lhs == rhs)
    end
end


"""
    name_constraints!(m::Model)

Sets constraint names for more useful diagnostic output
"""
function name_constraints!(m::Model)
    for (con_key, cons) in m.ext[:constraints]
        for (inds, con) in cons
            set_name(con, string(con_key,inds))
        end
    end
end
