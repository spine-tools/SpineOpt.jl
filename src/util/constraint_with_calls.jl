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

import DataStructures.OrderedDict
import JuMP: AbstractVariableRef, Model, GenericAffExpr, ScalarConstraint, MOI

struct GreaterThanCall <: MOI.AbstractScalarSet
    lower::Call
end

struct LessThanCall <: MOI.AbstractScalarSet
    upper::Call
end

struct EqualToCall <: MOI.AbstractScalarSet
    value::Call
end

_build_set_with_call(::MOI.GreaterThan, call::Call) = GreaterThanCall(call)
_build_set_with_call(::MOI.LessThan, call::Call) = LessThanCall(call)
_build_set_with_call(::MOI.EqualTo, call::Call) = EqualToCall(call)

function _build_aff_expr_with_calls(constant::Call, coef::Call, var::K) where {K}
    terms = OrderedDict{K,Call}()
    terms[var] = coef
    return GenericAffExpr{Call,K}(constant, terms)
end

function Base.show(io::IO, e::GenericAffExpr{Call,K}) where K
    str = string(join([string(coeff, " * ", var) for (var, coeff) in e.terms], " + "), " + ", e.constant)
    print(io, str)
end

# realize
SpineInterface.realize(s::GreaterThanCall) = MOI.GreaterThan(SpineInterface.realize(s.lower))
SpineInterface.realize(s::LessThanCall) = MOI.LessThan(SpineInterface.realize(s.upper))
SpineInterface.realize(s::EqualToCall) = MOI.EqualTo(SpineInterface.realize(s.value))

function SpineInterface.realize(e::GenericAffExpr{Call,K}) where K
    constant = SpineInterface.realize(e.constant)
    terms = OrderedDict{K,typeof(constant)}(k => SpineInterface.realize(v) for (k, v) in e.terms)
    GenericAffExpr(constant, terms)
end

# add_to_expression!
JuMP.add_to_expression!(aff::GenericAffExpr{Call,K}, call::Call) where K = (aff.constant = call + aff.constant; aff)

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,V}, other::GenericAffExpr{C,V}) where {C,V}
    merge!(+, aff.terms, other.terms)
    aff.constant += other.constant
    aff
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,V}, new_coef::Call, new_var::V) where {C,V}
    if !iszero(new_coef)
        aff.terms[new_var] = get(aff.terms, new_var, zero(V)) + new_coef
    end
    aff
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,V}, new_var::V, new_coef::Call) where {C,V}
    JuMP.add_to_expression!(aff, new_coef, new_var)
end

# constraint macro
function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,K}, set::MOI.AbstractScalarSet) where K
    call_for_set = Call(-, (expr.constant,), ())
    expr.constant = Call(0.0)
    set_with_call = _build_set_with_call(set, call_for_set)
    ScalarConstraint(expr, set_with_call)
end

function JuMP.add_constraint(model::Model, con::ScalarConstraint{GenericAffExpr{Call,K},S}, name::String="") where {K,S}
    materialized_con = ScalarConstraint(SpineInterface.realize(con.func), SpineInterface.realize(con.set))
    con_ref = JuMP.add_constraint(model, materialized_con, name)
    # TODO: register `con` in `model` so we can then `update(model)` or something, 
    # where we use `realize` combined with `set_normalized_coefficient` and `set_normalized_rhs`
    con_ref
end

# operators
# Call--AbstractVariableRef
Base.:+(lhs::Call, rhs::AbstractVariableRef) = _build_aff_expr_with_calls(lhs, Call(1.0), rhs)
Base.:-(lhs::Call, rhs::AbstractVariableRef) = _build_aff_expr_with_calls(lhs, Call(-1.0), rhs)
Base.:*(lhs::Call, rhs::AbstractVariableRef) = _build_aff_expr_with_calls(Call(0.0), lhs, rhs)
Base.:+(lhs::AbstractVariableRef, rhs::Call) = (+)(rhs, lhs)
Base.:-(lhs::AbstractVariableRef, rhs::Call) = (+)(lhs, -rhs)
Base.:*(lhs::AbstractVariableRef, rhs::Call) = (*)(rhs, lhs)

# Call--GenericAffExpr
function Base.:+(lhs::Call, rhs::GenericAffExpr{V,K}) where {V,K}
    constant = lhs + rhs.constant
    terms = OrderedDict{K,Call}(var => Call(coeff) for (var, coeff) in rhs.terms)
    GenericAffExpr(constant, terms)
end
Base.:-(lhs::Call, rhs::GenericAffExpr) = (+)(lhs, -rhs)
function Base.:*(lhs::Call, rhs::GenericAffExpr{V,K}) where {V,K}
    constant = lhs * rhs.constant
    terms = OrderedDict{K,Call}(var => lhs * coeff for (var, coeff) in rhs.terms)
    GenericAffExpr(constant, terms)
end
Base.:/(lhs::Call, rhs::GenericAffExpr) = (*)(lhs, 1.0 / rhs)
Base.:+(lhs::GenericAffExpr, rhs::Call) = (+)(rhs, lhs)
Base.:-(lhs::GenericAffExpr, rhs::Call) = (+)(lhs, -rhs)
Base.:*(lhs::GenericAffExpr, rhs::Call) = (*)(rhs, lhs)
Base.:/(lhs::GenericAffExpr, rhs::Call) = (*)(lhs, 1.0 / rhs)

# GenericAffExpr{Call,V}--GenericAffExpr
Base.:+(lhs::GenericAffExpr{Call,V}, rhs::GenericAffExpr{C,V}) where {C,V} = JuMP.add_to_expression!(copy(lhs), rhs)
Base.:-(lhs::GenericAffExpr{Call,V}, rhs::GenericAffExpr{C,V}) where {C,V} = (+)(lhs, -rhs)
Base.:+(lhs::GenericAffExpr{C,V}, rhs::GenericAffExpr{Call,V}) where {C,V} = (+)(rhs, lhs)
Base.:-(lhs::GenericAffExpr{C,V}, rhs::GenericAffExpr{Call,V}) where {C,V} = (+)(lhs, -rhs)