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
# But more importantly, we save all varying constraints (involving `ParameterCall`s) in the `Model` object,
# so we're able to automatically update them later, in `update_varying_constraints!`.
# We follow the same strategy for the objective.

import DataStructures: OrderedDict
import JuMP: MOI, MOIU, linear_terms

struct GreaterThanCall <: MOI.AbstractScalarSet
    lower::Call
end

struct LessThanCall <: MOI.AbstractScalarSet
    upper::Call
end

struct EqualToCall <: MOI.AbstractScalarSet
    value::Call
end

MOI.constant(s::GreaterThanCall) = s.lower
MOI.constant(s::LessThanCall) = s.upper
MOI.constant(s::EqualToCall) = s.value

function Base.show(io::IO, e::GenericAffExpr{Call,V}) where V
    str = string(join([string(coef, " * ", var) for (coef, var) in linear_terms(e)], " + "), " + ", e.constant)
    print(io, str)
end

# realize
SpineInterface.realize(s::GreaterThanCall) = MOI.GreaterThan(realize(MOI.constant(s)))
SpineInterface.realize(s::LessThanCall) = MOI.LessThan(realize(MOI.constant(s)))
SpineInterface.realize(s::EqualToCall) = MOI.EqualTo(realize(MOI.constant(s)))

function SpineInterface.realize(e::GenericAffExpr{C,VariableRef}) where C
    constant = realize(e.constant)
    terms = OrderedDict{VariableRef,typeof(constant)}(var => realize(coef) for (coef, var) in linear_terms(e))
    GenericAffExpr(constant, terms)
end

# @constraint macro extension
# utility
MOIU.shift_constant(s::MOI.GreaterThan, call::Call) = GreaterThanCall(MOI.constant(s) + call)
MOIU.shift_constant(s::MOI.LessThan, call::Call) = LessThanCall(MOI.constant(s) + call)
MOIU.shift_constant(s::MOI.EqualTo, call::Call) = EqualToCall(MOI.constant(s) + call)

function JuMP.build_constraint(_error::Function, call::Call, set::MOI.AbstractScalarSet)
    expr = GenericAffExpr{Call,VariableRef}(call, OrderedDict{VariableRef,Call}())
    build_constraint(_error, expr, set)
end

function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,VariableRef}, set::MOI.AbstractScalarSet)
    call = expr.constant
    expr.constant = zero(Call)
    new_set = MOIU.shift_constant(set, -call)
    ScalarConstraint(expr, new_set)
end

function JuMP.add_constraint(
        model::Model, con::ScalarConstraint{GenericAffExpr{Call,VariableRef},S}, name::String=""
    ) where S
    realized_con = ScalarConstraint(realize(con.func), realize(con.set))
    con_ref = add_constraint(model, realized_con, name)
    # Register varying stuff in `model.ext` so we can do work in `update_varying_constraints!`. This is the entire trick.
    varying_terms = Dict(var => coef for (coef, var) in linear_terms(con.func) if is_varying(coef))
    if !isempty(varying_terms)
        get!(model.ext, :varying_constraint_terms, Dict())[con_ref] = varying_terms
    end
    if is_varying(MOI.constant(con.set))
        get!(model.ext, :varying_constraint_rhs, Dict())[con_ref] = MOI.constant(con.set)
    end
    con_ref
end

# update_varying_constraints!
function update_varying_constraints!(model::Model)
    for (con_ref, terms) in get(model.ext, :varying_constraint_terms, ())
        for (var, coef) in terms
            set_normalized_coefficient(con_ref, var, realize(coef))
        end
    end
    for (con_ref, rhs) in get(model.ext, :varying_constraint_rhs, ())  
        set_normalized_rhs(con_ref, realize(rhs))
    end
end

# operators
# strategy: Make operators between a `Call` and a `VariableRef` return a `GenericAffExpr`,
# and proceed from there.
# utility
function _build_aff_expr_with_calls(constant::Call, coef::Call, var::VariableRef)
    terms = OrderedDict{VariableRef,Call}(var => coef)
    GenericAffExpr{Call,VariableRef}(constant, terms)
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, call::Call)
    aff.constant += call
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
        aff.terms[new_var] = get(aff.terms, new_var, zero(Call)) + new_coef
    end
    aff
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, new_var::VariableRef, new_coef::Call)
    JuMP.add_to_expression!(aff, new_coef, new_var)
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
    terms = OrderedDict{VariableRef,Call}(var => Call(coef) for (coef, var) in linear_terms(rhs))
    GenericAffExpr(constant, terms)
end
Base.:+(lhs::GenericAffExpr, rhs::Call) = (+)(rhs, lhs)
Base.:-(lhs::Call, rhs::GenericAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::GenericAffExpr, rhs::Call) = (+)(lhs, -rhs)
function Base.:*(lhs::Call, rhs::GenericAffExpr{C,VariableRef}) where C
    constant = lhs * rhs.constant
    terms = OrderedDict{VariableRef,Call}(var => lhs * coef for (coef, var) in linear_terms(rhs))
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

# @objective extension
function JuMP.set_objective_function(model::Model, func::GenericAffExpr{Call,VariableRef})
    model.ext[:varying_objective_terms] = Dict(
        var => coef for (coef, var) in linear_terms(func) if is_varying(coef)
    )
    set_objective_function(model, realize(func))
end

function update_varying_objective!(model::Model)
    for (var, coef) in model.ext[:varying_objective_terms]
        set_objective_coefficient(model, var, realize(coef))
    end    
end