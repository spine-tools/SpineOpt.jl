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
    expand_unit_group(ugs::X) where X >: Anything

Expand `unit_group` `ugs` into an `Array` of included `units`.
"""
expand_unit_group(::Anything) = anything
function expand_unit_group(ugs::X) where X >: Anything
    (u for ug in ugs for u in unit_group__unit(unit1=ug, _default=ug))
end

"""
    expand_node_group(ngs::X) where X >: Anything

Expand `node_group` `ngs` into an `Array` of included `nodes`.
"""
expand_node_group(::Anything) = anything
function expand_node_group(ngs::X) where X >: Anything
    (n for ng in ngs for n in node_group__node(node1=ng, _default=ng))
end

"""
    expand_commodity_group(cgs::X) where X >: Anything

Expand `commodity_group` `cgs` into an `Array` of included `commodities`.
"""
expand_commodity_group(::Anything) = anything
function expand_commodity_group(cgs::X) where X >: Anything
    (c for cg in cgs for c in commodity_group__commodity(commodity1=cg, _default=cg))
end

"""
    log(level, msg)

TODO: Print stuff?
"""
macro log(level, msg)
    quote
        if $(esc(level))
            printstyled($(esc(msg)), "\n"; bold=true)
        end
    end
end

"""
    logtime(level, msg, expr)

TODO: Logs time taken by commands?
"""
macro logtime(level, msg, expr)
    quote
        if $(esc(level))
            @msgtime $(esc(msg)) $(esc(expr))
        else
            $(esc(expr))
        end
    end
end

"""
    msgtime(msg, expr)

TODO: Prints stuff with time?
"""
macro msgtime(msg, expr)
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
    for conn_mon in connection(connection_monitored=:value_true)
        print(io, string(conn_mon), ",")
    end
    print(io, "\n")
    for conn_cont in connection(connection_contingency=:value_true)
        n_from, n_to = connection__from_node(connection=conn_cont, direction=anything)
        print(io, string(conn_cont), ",", string(n_from), ",", string(n_to))
        for conn_mon in connection(connection_monitored=:value_true)
            print(io, ",")
            for (conn_cont, conn_mon) in indices(lodf; connection1=conn_cont, connection2=conn_mon)
                print(io, lodf(connection1=conn_cont, connection2=conn_mon))
            end
        end
        print(io, "\n")
    end
    close(io)
end
