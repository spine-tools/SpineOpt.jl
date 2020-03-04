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

# Here we extend `JuMP.@constraint` so we're able to build constraints involving `Call` objects.
# In `JuMP.add_constraint`, we `realize` all `Call`s to compute a constraint that can be added to the model.
# But more importantly, we save all dynamic constraints (involving `Call`s) in the `Model` object,
# so we're able to automatically update them later, in `update_dynamic_constraints!`.

import DataStructures: OrderedDict
import JuMP: MOI

struct GreaterThanCall <: MOI.AbstractScalarSet
    value::Call
end

struct LessThanCall <: MOI.AbstractScalarSet
    value::Call
end

struct EqualToCall <: MOI.AbstractScalarSet
    value::Call
end

function Base.show(io::IO, e::GenericAffExpr{Call,V}) where V
    str = string(join([string(coeff, " * ", var) for (var, coeff) in e.terms], " + "), " + ", e.constant)
    print(io, str)
end

# realize
SpineInterface.realize(s::GreaterThanCall) = MOI.GreaterThan(SpineInterface.realize(s.value))
SpineInterface.realize(s::LessThanCall) = MOI.LessThan(SpineInterface.realize(s.value))
SpineInterface.realize(s::EqualToCall) = MOI.EqualTo(SpineInterface.realize(s.value))

function SpineInterface.realize(e::GenericAffExpr{C,VariableRef}) where C
    constant = realize(e.constant)
    terms = OrderedDict{VariableRef,typeof(constant)}(k => realize(v) for (k, v) in e.terms)
    GenericAffExpr(constant, terms)
end

# add_to_expression!
function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, call::Call)
    aff.constant = call + aff.constant
    aff
end

function JuMP.add_to_expression!(
        aff::GenericAffExpr{Call,VariableRef}, other::GenericAffExpr{C,VariableRef}
    ) where C
    merge!(+, aff.terms, other.terms)
    aff.constant += other.constant
    aff
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, new_coef::Call, new_var::VariableRef)
    if !iszero(new_coef)
        aff.terms[new_var] = get(aff.terms, new_var, zero(VariableRef)) + new_coef
    end
    aff
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, new_var::VariableRef, new_coef::Call)
    JuMP.add_to_expression!(aff, new_coef, new_var)
end

# constraint macro
# utility
_build_set_with_call(::MOI.GreaterThan, call::Call) = GreaterThanCall(call)
_build_set_with_call(::MOI.LessThan, call::Call) = LessThanCall(call)
_build_set_with_call(::MOI.EqualTo, call::Call) = EqualToCall(call)

function JuMP.build_constraint(_error::Function, call::Call, set::MOI.AbstractScalarSet)
    expr = GenericAffExpr{Call,VariableRef}(call, OrderedDict{VariableRef,Call}())
    build_constraint(_error, expr, set)
end

function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,VariableRef}, set::MOI.AbstractScalarSet)
    call = Call(-, (expr.constant,))
    expr.constant = Call(0.0)
    new_set = _build_set_with_call(set, call)
    ScalarConstraint(expr, new_set)
end

function JuMP.add_constraint(
        model::Model, con::ScalarConstraint{GenericAffExpr{Call,VariableRef},S}, name::String=""
    ) where S
    realized_con = ScalarConstraint(realize(con.func), realize(con.set))
    con_ref = JuMP.add_constraint(model, realized_con, name)
    dynamic_terms = Dict(var => coeff for (var, coeff) in con.func.terms if is_dynamic(coeff))
    if !isempty(dynamic_terms)
        get!(model.ext, :dynamic_constraint_terms, Dict())[con_ref] = dynamic_terms
    end
    if is_dynamic(con.set.value)
        get!(model.ext, :dynamic_constraint_rhs, Dict())[con_ref] = con.set.value
    end
    con_ref
end

# update_dynamic_constraints!
function update_dynamic_constraints!(model::Model)
    for (con_ref, terms) in get(model.ext, :dynamic_constraint_terms, ())
        for (var, coeff) in terms
            set_normalized_coefficient(con_ref, var, realize(coeff))
        end
    end
    for (con_ref, rhs) in get(model.ext, :dynamic_constraint_rhs, ())  
        set_normalized_rhs(con_ref, realize(rhs))
    end
end

# operators
# strategy: Make operators between a `Call` and a `VariableRef` return a `GenericAffExpr`,
# and proceed from there.
# utility
function _build_aff_expr_with_calls(constant::Call, coef::Call, var::VariableRef)
    terms = OrderedDict{VariableRef,Call}()
    terms[var] = coef
    GenericAffExpr{Call,VariableRef}(constant, terms)
end

# Call--VariableRef
Base.:+(lhs::Call, rhs::VariableRef) = _build_aff_expr_with_calls(lhs, Call(1.0), rhs)
Base.:+(lhs::VariableRef, rhs::Call) = (+)(rhs, lhs)
Base.:-(lhs::Call, rhs::VariableRef) = _build_aff_expr_with_calls(lhs, Call(-1.0), rhs)
Base.:-(lhs::VariableRef, rhs::Call) = (+)(lhs, -rhs)
Base.:*(lhs::Call, rhs::VariableRef) = _build_aff_expr_with_calls(Call(0.0), lhs, rhs)
Base.:*(lhs::VariableRef, rhs::Call) = (*)(rhs, lhs)

# Call--GenericAffExpr
function Base.:+(lhs::Call, rhs::GenericAffExpr{C,VariableRef}) where C
    constant = lhs + rhs.constant
    terms = OrderedDict{VariableRef,Call}(var => Call(coeff) for (var, coeff) in rhs.terms)
    GenericAffExpr(constant, terms)
end
Base.:+(lhs::GenericAffExpr, rhs::Call) = (+)(rhs, lhs)
Base.:-(lhs::Call, rhs::GenericAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::GenericAffExpr, rhs::Call) = (+)(lhs, -rhs)
function Base.:*(lhs::Call, rhs::GenericAffExpr{C,VariableRef}) where C
    constant = lhs * rhs.constant
    terms = OrderedDict{VariableRef,Call}(var => lhs * coeff for (var, coeff) in rhs.terms)
    GenericAffExpr(constant, terms)
end
Base.:*(lhs::GenericAffExpr, rhs::Call) = (*)(rhs, lhs)
Base.:/(lhs::Call, rhs::GenericAffExpr) = (*)(lhs, 1.0 / rhs)
Base.:/(lhs::GenericAffExpr, rhs::Call) = (*)(lhs, 1.0 / rhs)

# GenericAffExpr--GenericAffExpr
function Base.:+(lhs::GenericAffExpr{Call,VariableRef}, rhs::GenericAffExpr{Call,VariableRef})
    JuMP.add_to_expression!(copy(lhs), rhs)
end
function Base.:+(lhs::GenericAffExpr{Call,VariableRef}, rhs::GenericAffExpr{C,VariableRef}) where C
    JuMP.add_to_expression!(copy(lhs), rhs)
end
Base.:+(lhs::GenericAffExpr{C,VariableRef}, rhs::GenericAffExpr{Call,VariableRef}) where C = (+)(rhs, lhs)
Base.:-(lhs::GenericAffExpr{Call,VariableRef}, rhs::GenericAffExpr{Call,VariableRef}) = (+)(lhs, -rhs)
Base.:-(lhs::GenericAffExpr{Call,VariableRef}, rhs::GenericAffExpr{C,VariableRef}) where C = (+)(lhs, -rhs)
Base.:-(lhs::GenericAffExpr{C,VariableRef}, rhs::GenericAffExpr{Call,VariableRef}) where C = (+)(lhs, -rhs)