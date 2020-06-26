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

# Here we extend `JuMP.@constraint` so we're able to build constraints involving `Call` objects.
# In `JuMP.add_constraint`, we `realize` all `Call`s to compute a constraint that can be added to the model.
# But more importantly, we save all varying constraints (involving `ParameterCall`s) in the `Model` object
# so we're able to automatically update them later, in `update_varying_constraints!`.
# We extend @objective in a similar way.

import DataStructures: OrderedDict
import LinearAlgebra: UniformScaling
import JuMP: MOI, MOIU

_Constant = Union{Number,UniformScaling}

abstract type CallSet <: MOI.AbstractScalarSet end

struct GreaterThanCall <: CallSet
    lower::Call
end

struct LessThanCall <: CallSet
    upper::Call
end

struct EqualToCall <: CallSet
    value::Call
end

MOI.constant(s::GreaterThanCall) = s.lower
MOI.constant(s::LessThanCall) = s.upper
MOI.constant(s::EqualToCall) = s.value

function Base.convert(::Type{GenericAffExpr{Call,VariableRef}}, expr::GenericAffExpr{C,VariableRef}) where C
    constant = Call(expr.constant)
    terms = OrderedDict{VariableRef,Call}(var => Call(coef) for (var, coef) in expr.terms)
    GenericAffExpr{Call,VariableRef}(constant, terms)
end


# TODO: try to get rid of this in favor of JuMP's generic implementation
function Base.show(io::IO, e::GenericAffExpr{Call,VariableRef})
    str = string(join([string(coef, " * ", var) for (var, coef) in e.terms], " + "), " + ", e.constant)
    print(io, str)
end

# realize
SpineInterface.realize(s::GreaterThanCall) = MOI.GreaterThan(realize(MOI.constant(s)))
SpineInterface.realize(s::LessThanCall) = MOI.LessThan(realize(MOI.constant(s)))
SpineInterface.realize(s::EqualToCall) = MOI.EqualTo(realize(MOI.constant(s)))

function SpineInterface.realize(e::GenericAffExpr{C,VariableRef}) where C
    constant = realize(e.constant)
    terms = OrderedDict{VariableRef,typeof(constant)}(var => realize(coef) for (var, coef) in e.terms)
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
    constant = expr.constant
    expr.constant = zero(Call)
    new_set = MOIU.shift_constant(set, -constant)
    ScalarConstraint(expr, new_set)
end

function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,VariableRef}, lb::Real, ub::Real)
    build_constraint(_error, expr, Call(lb), Call(ub))
end

function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,VariableRef}, lb::Real, ub::Call)
    build_constraint(_error, expr, Call(lb), ub)
end

function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,VariableRef}, lb::Call, ub::Real)
    build_constraint(_error, expr, lb, Call(ub))
end

function JuMP.build_constraint(_error::Function, expr::GenericAffExpr{Call,VariableRef}, lb::Call, ub::Call)
    constant = expr.constant
    if any(is_varying(x) for x in (lb, ub, constant))
        _error("Range constraint with time-varying bounds or free-term is not supported at the moment.")
    else
        set = MOI.Interval(realize(lb), realize(ub))
        new_set = MOIU.shift_constant(set, -realize(constant))
        ScalarConstraint(expr, new_set)
    end
end

function JuMP.add_constraint(
        model::Model, con::ScalarConstraint{GenericAffExpr{Call,VariableRef},S}, name::String=""
    ) where S <: CallSet
    realized_con = ScalarConstraint(realize(con.func), realize(con.set))
    con_ref = add_constraint(model, realized_con, name)
    # Register varying stuff in `model.ext` so we can do work in `update_varying_constraints!`. This is the entire trick.
    varying_terms = Dict(var => coef for (var, coef) in con.func.terms if is_varying(coef))
    if !isempty(varying_terms)
        get!(model.ext, :varying_constraint_terms, Dict())[con_ref] = varying_terms
    end
    if is_varying(MOI.constant(con.set))
        get!(model.ext, :varying_constraint_rhs, Dict())[con_ref] = MOI.constant(con.set)
    end
    con_ref
end

function JuMP.add_constraint(
        model::Model, con::ScalarConstraint{GenericAffExpr{Call,VariableRef},MOI.Interval{T}}, name::String=""
    ) where T
    realized_con = ScalarConstraint(realize(con.func), con.set)
    add_constraint(model, realized_con, name)
end

# add_to_expression!
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

# TODO: Try to find out why we need this one
function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, new_coef::Call, new_coef_::Call)
    add_to_expression!(aff, new_coef * new_coef_)
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, new_coef::Call, new_var::VariableRef)
    if !iszero(new_coef)
        aff.terms[new_var] = get(aff.terms, new_var, zero(Call)) + new_coef
    end
    aff
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, new_var::VariableRef, new_coef::Call)
    add_to_expression!(aff, new_coef, new_var)
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, coef::_Constant, other::Call)
    add_to_expression!(aff, coef * other)
end

function JuMP.add_to_expression!(aff::GenericAffExpr{Call,VariableRef}, other::Call, coef::_Constant)
    add_to_expression!(aff, coef, other)
end

function JuMP.add_to_expression!(
        aff::GenericAffExpr{Call,VariableRef}, coef::_Constant, other::GenericAffExpr{Call,VariableRef}
    )
    add_to_expression!(aff, coef * other)
end

function JuMP.add_to_expression!(
        aff::GenericAffExpr{Call,VariableRef}, other::GenericAffExpr{Call,VariableRef}, coef::_Constant
    )
    add_to_expression!(aff, coef, other)
end

function JuMP.add_to_expression!(
        aff::GenericAffExpr{Call,VariableRef}, coef::_Constant, other::GenericAffExpr{C,VariableRef}
    ) where C
    add_to_expression!(aff, coef, convert(GenericAffExpr{Call,VariableRef}, other))
end

function JuMP.add_to_expression!(
        aff::GenericAffExpr{Call,VariableRef}, other::GenericAffExpr{C,VariableRef}, coef::_Constant
    ) where C
    add_to_expression!(aff, coef, other)
end

# operators
# strategy: Make operators between a `Call` and a `VariableRef` return a `GenericAffExpr`,
# and proceed from there.
# utility
function _build_aff_expr_with_calls(constant::Call, coef::Call, var::VariableRef)
    terms = OrderedDict{VariableRef,Call}(var => coef)
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
    terms = OrderedDict{VariableRef,Call}(var => Call(coef) for (var, coef) in rhs.terms)
    GenericAffExpr(constant, terms)
end
Base.:+(lhs::GenericAffExpr, rhs::Call) = (+)(rhs, lhs)
Base.:-(lhs::Call, rhs::GenericAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::GenericAffExpr, rhs::Call) = (+)(lhs, -rhs)
function Base.:*(lhs::Call, rhs::GenericAffExpr{C,VariableRef}) where C
    constant = lhs * rhs.constant
    terms = OrderedDict{VariableRef,Call}(var => lhs * coef for (var, coef) in rhs.terms)
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
        var => coef for (var, coef) in func.terms if is_varying(coef)
    )
    set_objective_function(model, realize(func))
end

function update_varying_objective!(model::Model)
    for (var, coef) in model.ext[:varying_objective_terms]
        set_objective_coefficient(model, var, realize(coef))
    end    
end

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

function update_variable!(m::Model, name::Symbol, indices::Function)
    var = m.ext[:variables][name]
    val = m.ext[:values][name]
    lb = m.ext[:variables_definition][name][:lb]
    ub = m.ext[:variables_definition][name][:ub]
    for ind in indices()
        set_name(var[ind], _base_name(name, ind))
        if is_fixed(var[ind])
            unfix(var[ind])
            lb != nothing && set_lower_bound(var[ind], lb(ind))
            ub != nothing && set_upper_bound(var[ind], ub(ind))
        end
        end_(ind.t) <= end_(current_window) || continue
        for history_ind in indices(; ind..., stochastic_scenario=anything, t=t_history_t[ind.t])
            set_name(var[history_ind], _base_name(name, history_ind))
            fix(var[history_ind], val[ind]; force=true)
        end
    end
end

function update_variables!(m::Model)
    for (name, definition) in m.ext[:variables_definition]
        update_variable!(m, name, definition[:indices])
    end
end