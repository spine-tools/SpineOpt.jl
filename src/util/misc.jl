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

# override `get` and `getindex` so we can access our variable dicts with a `Tuple` instead of the actual `NamedTuple`
function Base.get(d::Dict{K,VariableRef}, key::Tuple{Vararg{ObjectLike}}, default) where {J,K<:RelationshipLike{J}}
    Base.get(d, NamedTuple{J}(key), default)
end

function Base.getindex(d::Dict{K,VariableRef}, key::ObjectLike...) where {J,K<:RelationshipLike{J}}
    Base.getindex(d, NamedTuple{J}(key))
end

_ObjectArrayLike = Union{ObjectLike,Array{T,1} where T<:ObjectLike}
_RelationshipArrayLike{K} = NamedTuple{K,V} where {K,V<:Tuple{Vararg{_ObjectArrayLike}}}

function Base.getindex(d::Dict{K,V}, key::_ObjectArrayLike...) where {J,K<:_RelationshipArrayLike{J},V<:ConstraintRef}
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

"""
    log(level, threshold, msg)

TODO: Print stuff?
"""
macro log(level, threshold, msg)
    quote
        if $(esc(level)) >= $(esc(threshold))
            printstyled($(esc(msg)), "\n"; bold=true)
        end
    end
end

"""
    timelog(level, threshold, msg, expr)

TODO: Logs time taken by commands?
"""
macro timelog(level, threshold, msg, expr)
    quote
        if $(esc(level)) >= $(esc(threshold))
            @timemsg $(esc(msg)) $(esc(expr))
        else
            $(esc(expr))
        end
    end
end

"""
    timemsg(msg, expr)

TODO: Prints stuff with time?
"""
macro timemsg(msg, expr)
    quote
        printstyled($(esc(msg)); bold=true)
        @time $(esc(expr))
    end
end

"""
    sense_constraint(m, lhs, sense::Symbol, rhs)

Create a JuMP constraint with the desired left-hand-side `lhs`, `sense`, and right-hand-side `rhs`.
"""
function sense_constraint(m, lhs, sense::Symbol, rhs)
    if sense == :>=
        @constraint(m, lhs >= rhs)
    elseif sense == :<=
        @constraint(m, lhs <= rhs)
    else
        @constraint(m, lhs == rhs)
    end
end
sense_constraint(m, lhs, sense::typeof(<=), rhs) = @constraint(m, lhs <= rhs)
sense_constraint(m, lhs, sense::typeof(==), rhs) = @constraint(m, lhs == rhs)
sense_constraint(m, lhs, sense::typeof(>=), rhs) = @constraint(m, lhs >= rhs)

"""
    expr_sum(iter; init::Number)

Sum elements in iter to init in-place, and return the result as a GenericAffExpr.
"""
function expr_sum(iter; init::Number)
    result = AffExpr(init)
    isempty(iter) && return result
    result += first(iter)  # NOTE: This is so result has the right type, e.g., `GenericAffExpr{Call,VariableRef}`
    for item in Iterators.drop(iter, 1)
        add_to_expression!(result, item)
    end
    result
end

"""
    write_ptdfs()

Write `ptdf` parameter values to a `ptdfs.csv` file.
"""
function write_ptdfs()
    io = open("ptdfs.csv", "w")
    print(io, "connection,")
    for n in node(has_ptdf=true)
        print(io, string(n), ",")
    end
    print(io, "\n")
    for conn in connection(has_ptdf=true)
        print(io, string(conn), ",")
        for n in node(has_ptdf=true)
            print(io, ptdf(connection=conn, node=n), ",")
        end
        print(io, "\n")
    end
    close(io)
end

"""
    write_lodfs()

Write `lodf` parameter values to a `lodsfs.csv` file.
"""
function write_lodfs()
    io = open("lodfs.csv", "w")
    print(io, raw"contingency line,from_node,to node,")
    for conn_mon in connection(connection_monitored=true)
        print(io, string(conn_mon), ",")
    end
    print(io, "\n")
    for conn_cont in connection(connection_contingency=true)
        n_from, n_to = connection__from_node(connection=conn_cont, direction=anything)
        print(io, string(conn_cont), ",", string(n_from), ",", string(n_to))
        for conn_mon in connection(connection_monitored=true)
            print(io, ",")
            for (conn_cont, conn_mon) in indices(lodf; connection1=conn_cont, connection2=conn_mon)
                print(io, lodf(connection1=conn_cont, connection2=conn_mon))
            end
        end
        print(io, "\n")
    end
    close(io)
end
