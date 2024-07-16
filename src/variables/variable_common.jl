#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
  - `fix_value::Union{Function,Nothing}=nothing`: given an index, return a fix value for the variable or nothing
  - `non_anticipativity_time::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity time
    or nothing
  - `non_anticipativity_margin::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity margin
    or nothing
  - `required_history_period::Union{Period,Nothing}=nothing`: given an index, return the required history period
    or nothing
  - `replacement_expressions::Dict=Dict()`: mapping some of the indices returned by the given `indices` function,
    to another Dict with a recipe to build an expression to use instead of the variable.
    The recipe Dict maps variable names to a tuple of index and coefficient.
    The expression is built as the sum of the coefficient and the variable for that index over the entire Dict.
"""
function add_variable!(
    m::Model,
    name::Symbol,
    indices::Function;
    bin::Union{Function,Nothing}=nothing,
    int::Union{Function,Nothing}=nothing,
    lb::Union{Parameter,Function,Nothing}=nothing,
    ub::Union{Parameter,Function,Nothing}=nothing,
    initial_value::Union{Parameter,Nothing}=nothing,
    fix_value::Union{Parameter,Nothing}=nothing,
    internal_fix_value::Union{Parameter,Nothing}=nothing,
    non_anticipativity_time::Union{Parameter,Nothing}=nothing,
    non_anticipativity_margin::Union{Parameter,Nothing}=nothing,
    required_history_period::Union{Period,Nothing}=nothing,
    replacement_expressions=Dict(),
)
    if required_history_period === nothing
        required_history_period = _model_duration_unit(m.ext[:spineopt].instance)(1)
    end
    t_start = start(first(time_slice(m)))
    t_history = TimeSlice(t_start - required_history_period, t_start)
    history_time_slices = [t for t in history_time_slice(m) if overlaps(t_history, t)]
    m.ext[:spineopt].variables_definition[name] = Dict(
        :indices => indices,
        :bin => bin,
        :int => int,
        :non_anticipativity_time => non_anticipativity_time,
        :non_anticipativity_margin => non_anticipativity_margin,
        :history_time_slices => history_time_slices,
        :replacement_expressions => replacement_expressions,
    )
    lb = _nothing_if_empty(lb)
    ub = _nothing_if_empty(ub)
    initial_value = _nothing_if_empty(initial_value)
    fix_value = _nothing_if_empty(fix_value)
    internal_fix_value = _nothing_if_empty(internal_fix_value)
    t = vcat(history_time_slices, time_slice(m))
    first_ind = iterate(indices(m; t=t))
    K = first_ind === nothing ? Any : typeof(first_ind[1])
    V = Union{VariableRef,GenericAffExpr{T,VariableRef} where T<:Union{Number,Call}}
    vars = m.ext[:spineopt].variables[name] = Dict{K,V}(
        ind => _add_variable!(m, name, ind) for ind in indices(m; t=t) if !haskey(replacement_expressions, ind)
    )
    inverse_replacement_expressions = Dict(
        ref_ind => (ind, 1 / coeff)
        for (ind, (ref_ind, coeff)) in ((ind, ref[name]) for (ind, ref) in replacement_expressions)
    )
    Threads.@threads for ind in collect(keys(vars))
        # Resolve bin, int, lb, ub, fix_value and internal_fix_value for ind.
        # If we have an replacement_expressions, then we need to combine any values given for the ind and its referrer.
        # For example, for the lower bound we need to take the maximum between the lower bound for ind,
        # and the lower bound for the referrer scaled by the appropriate factor.
        expression = get(inverse_replacement_expressions, ind, ())
        res_bin = _any(bin, ind, expression...)
        res_int = _any(int, ind, expression...)
        res_lb = _reduce(lb, m, ind, expression..., max)
        res_ub = _reduce(ub, m, ind, expression..., min)
        res_fix_value = _reduce(fix_value, m, ind, expression..., _check_unique)
        res_internal_fix_value = _reduce(internal_fix_value, m, ind, expression..., _check_unique)
        _finalize_variable!(vars[ind], res_bin, res_int, res_lb, res_ub, res_fix_value, res_internal_fix_value)
    end
    # Apply initial value, but make sure it updates itself by using a TimeSeries Call
    if initial_value !== nothing
        last_history_t = last(history_time_slice(m))
        t0 = model_start(model=m.ext[:spineopt].instance)
        dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
        for (ind, var) in vars
            overlaps(ind.t, last_history_t) || continue
            val = initial_value(; ind..., _strict=false)
            val === nothing && continue
            initial_value_ts = parameter_value(TimeSeries([t0 - dur_unit(1), t0], [val, NaN]))
            fix(var, Call(initial_value_ts, (t=ind.t,), (Symbol(:initial_, name), ind)))
        end
    end
    isempty(SpineInterface.indices(representative_periods_mapping)) || merge!(
        vars, _representative_periods_mapping(m, vars, indices)
    )
    vars
end

_nothing_if_empty(p::Parameter) = isempty(indices(p)) ? nothing : p
_nothing_if_empty(x) = x

_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

function _add_variable!(m, name, ind)
    @variable(m, base_name=_base_name(name, ind))
end

_check_unique(x, y) = x == y ? x : error("$x != $y")

_any(::Nothing, args...) = false
_any(f, ind) = f(ind)
_any(f, ind, other_ind, _factor) = _apply(any, f(ind), f(other_ind))

_reduce(::Nothing, args...) = nothing
_reduce(f, m, ind, _reducer) = f(m; ind...)
function _reduce(f, m, ind, other_ind, factor, reducer)
    _apply(reducer, f(m; ind...), _mul(factor, f(m; other_ind...)))
end

_mul(_factor, ::Nothing) = nothing
_mul(factor, x) = factor * x
_mul(factor::Call, x) = Call(_mul, [factor, x])
_mul(factor, x::Call) = Call(_mul, [factor, x])
_mul(factor::Call, x::Call) = Call(_mul, [factor, x])

_apply(reducer, x, ::Nothing) = x
_apply(reducer, ::Nothing, y) = y
_apply(reducer, ::Nothing, ::Nothing) = nothing
_apply(reducer, x::Call, y) = Call(_apply, [reducer, x, y])
_apply(reducer, x, y::Call) = Call(_apply, [reducer, x, y])
_apply(reducer, x::Call, y::Call) = Call(_apply, [reducer, x, y])
function _apply(reducer, x::Number, y::Number)
    if isnan(x)
        y
    elseif isnan(y)
        x
    else
        reducer(x, y)
    end
end

_finalize_variable!(x, args...) = nothing
function _finalize_variable!(var::VariableRef, bin, int, lb, ub, fix_value, internal_fix_value)
    bin && set_binary(var)
    int && set_integer(var)
    _do_set_lower_bound(var, lb)
    _do_set_upper_bound(var, ub)
    _do_fix(var, internal_fix_value; force=true)
    _do_fix(var, fix_value; force=true)
end

_do_set_lower_bound(_var, ::Nothing) = nothing
_do_set_lower_bound(var, bound::Call) = set_lower_bound(var, bound)
_do_set_lower_bound(var, bound::Number) = isfinite(bound) && set_lower_bound(var, bound)

_do_set_upper_bound(_var, ::Nothing) = nothing
_do_set_upper_bound(var, bound::Call) = set_upper_bound(var, bound)
_do_set_upper_bound(var, bound::Number) = isfinite(bound) && set_upper_bound(var, bound)

_do_fix(_var, ::Nothing; kwargs...) = nothing
_do_fix(var, x::Call; kwargs...) = fix(var, x)
function _do_fix(var, x::Number; kwargs...)
    if !isnan(x)
        fix(var, x; kwargs...)
    elseif is_fixed(var)
        unfix(var)
    end
end

"""
    _representative_index(ind)

The representative index corresponding to the given one.
"""
function _representative_index(m, ind, indices)
    representative_t = representative_time_slice(m, ind.t)
    representative_inds = indices(m; ind..., t=representative_t)
    if isempty(representative_inds)
        representative_blocks = unique(
            blk
            for t in representative_t
            for blk in blocks(t)
            if representative_periods_mapping(temporal_block=blk) === nothing
        )
        node_or_unit = hasproperty(ind, :node) ? "node '$(ind.node)'" : "unit '$(ind.unit)'"
        error(
            "can't find a representative index for $ind -",
            " this is probably because ",
            node_or_unit,
            " is not associated to any of the representative temporal_blocks ",
            join(("'$blk'" for blk in representative_blocks), ", "),
        )
    end
    first(representative_inds)
end

"""
    _representative_periods_mapping(v::Dict{VariableRef}, indices::Function)

A `Dict` mapping non representative indices to the variable for the representative index.
"""
function _representative_periods_mapping(m::Model, vars::Dict, indices::Function)
    # By default, `indices` skips represented time slices for operational variables other than node_state,
    # as well as for investment variables. This is done by setting the default value of the `temporal_block` argument
    # to `temporal_block(representative_periods_mapping=nothing)` - so any blocks that define a mapping are ignored.
    # To include represented time slices, we need to specify `temporal_block=anything`.
    # Note that for node_state and investment variables, `represented_indices`, below, will be empty.
    representative_indices = indices(m)
    all_indices = indices(m, temporal_block=anything)
    represented_indices = setdiff(all_indices, representative_indices)
    Dict(ind => vars[_representative_index(m, ind, indices)] for ind in represented_indices)
end
