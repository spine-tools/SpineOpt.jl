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
  - `replacement_expressions::Dict=Dict()`: mapping some of the indices of the variable - as returned by the given
    `indices` function - to another Dict that defines an expression to use instead of the variable for that index.
    The expression Dict simply maps variable names to a tuple of reference index and coefficient.
    The expression is then built as the sum of the coefficient and the variable for the reference index,
    over the entire Dict.
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
    lb = _nothing_if_empty(lb)
    ub = _nothing_if_empty(ub)
    initial_value = _nothing_if_empty(initial_value)
    fix_value = _nothing_if_empty(fix_value)
    internal_fix_value = _nothing_if_empty(internal_fix_value)
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
        :lb => lb,
        :ub => ub,
        :fix_value => fix_value,
        :internal_fix_value => internal_fix_value,
        :non_anticipativity_time => non_anticipativity_time,
        :non_anticipativity_margin => non_anticipativity_margin,
        :history_time_slices => history_time_slices,
        :replacement_expressions => replacement_expressions,
    )
    t = vcat(history_time_slices, time_slice(m))
    first_ind = iterate(indices(m; t=t))
    K = first_ind === nothing ? Any : typeof(first_ind[1])
    V = Union{VariableRef,GenericAffExpr{T,VariableRef} where T<:Union{Number,Call}}
    vars = m.ext[:spineopt].variables[name] = Dict{K,V}(
        ind => _add_variable!(m, name, ind) for ind in indices(m; t=t) if !haskey(replacement_expressions, ind)
    )
    _finalize_variables!(m, vars, bin, int, lb, ub, fix_value, internal_fix_value)
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

_add_variable!(m, name, ind) = @variable(m, base_name=_base_name(name, ind))

_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

function _expand_replacement_expressions!(m)
    for (name, def) in m.ext[:spineopt].variables_definition
        replacement_expressions = def[:replacement_expressions]
        isempty(replacement_expressions) && continue
        vars = m.ext[:spineopt].variables[name]
        exprs = Dict()
        for (ind, formula) in replacement_expressions
            vars[ind] = exprs[ind] = sum(
                coeff * _get_var_with_replacement(m, ref_name, ref_ind) for (ref_name, (ref_ind, coeff)) in formula
            )
        end
        @fetch bin, int, lb, ub, fix_value, internal_fix_value = def
        _finalize_expressions!(m, name, exprs, bin, int, lb, ub, fix_value, internal_fix_value)
    end
end

function _get_var_with_replacement(m, var_name, ind)
    get(m.ext[:spineopt].variables[var_name], ind) do
        get_var_by_name = Dict(
            :units_on => _get_units_on,
            :units_out_of_service => _get_units_out_of_service,
            :units_started_up => _get_units_started_up,
        )
        get_var = get(get_var_by_name, var_name, nothing)
        isnothing(get_var) && throw(KeyError(ind))
        get_var(m, ind...)
    end
end

function _finalize_variables!(args...)
    inds, vars, bins, ints, lbs, ubs, internal_fix_values, fix_values = _collect_info(args...)
    _set_binary.(vars, bins)
    _set_integer.(vars, ints)
    _set_lower_bound.(vars, lbs)
    _set_upper_bound.(vars, ubs)
    _fix.(vars, internal_fix_values)
    _fix.(vars, fix_values)
end

function _finalize_expressions!(m, name, args...)
    inds, exprs, bins, ints, lbs, ubs, internal_fix_values, fix_values = _collect_info(m, args...)
    _set_binary.(exprs, bins)
    _set_integer.(exprs, ints)
    m.ext[:spineopt].constraints[Symbol(name, :_lb)] = Dict(zip(inds, set_expr_bound.(exprs, >=, lbs)))
    m.ext[:spineopt].constraints[Symbol(name, :_ub)] = Dict(zip(inds, set_expr_bound.(exprs, <=, ubs)))
    m.ext[:spineopt].constraints[Symbol(name, :_internal_fix)] = Dict(
        zip(inds, set_expr_bound.(exprs, ==, internal_fix_values))
    )
    m.ext[:spineopt].constraints[Symbol(name, :_fix)] = Dict(zip(inds, set_expr_bound.(exprs, ==, fix_values)))
end

function _collect_info(m, d, bin, int, lb, ub, fix_value, internal_fix_value)
    inds = collect(keys(d))
    vars_or_exprs = collect(values(d))
    bins = Any[nothing for i in eachindex(inds)]
    ints = Any[nothing for i in eachindex(inds)]
    lbs = Any[nothing for i in eachindex(inds)]
    ubs = Any[nothing for i in eachindex(inds)]
    internal_fix_values = Any[nothing for i in eachindex(inds)]
    fix_values = Any[nothing for i in eachindex(inds)]
    Threads.@threads for i in eachindex(inds)
        ind = inds[i]
        bins[i] = _resolve(bin, ind)
        ints[i] = _resolve(int, ind)
        lbs[i] = _resolve(lb, m, ind)
        ubs[i] = _resolve(ub, m, ind)
        fix_values[i] = _resolve(fix_value, m, ind)
        internal_fix_values[i] = _resolve(internal_fix_value, m, ind)
    end
    inds, vars_or_exprs, bins, ints, lbs, ubs, internal_fix_values, fix_values
end

_resolve(::Nothing, _ind) = false
_resolve(f, ind) = f(ind)
_resolve(::Nothing, _m, _ind) = nothing
_resolve(f, m, ind) = f(m; ind...)

_set_binary(var::VariableRef, bin) = bin && set_binary(var)
_set_binary(expr::GenericAffExpr, bin) = bin && set_binary.(keys(expr.terms))

_set_integer(var::VariableRef, int) = int && set_integer(var)
_set_integer(expr::GenericAffExpr, int) = int && set_integer.(keys(expr.terms))

_set_lower_bound(_var, ::Nothing) = nothing
_set_lower_bound(var::VariableRef, bound::Call) = set_lower_bound(var, bound)
_set_lower_bound(var::VariableRef, bound::Number) = isfinite(bound) && set_lower_bound(var, bound)

_set_upper_bound(_var, ::Nothing) = nothing
_set_upper_bound(var::VariableRef, bound::Call) = set_upper_bound(var, bound)
_set_upper_bound(var::VariableRef, bound::Number) = isfinite(bound) && set_upper_bound(var, bound)

_fix(_var, ::Nothing) = nothing
_fix(var::VariableRef, value::Call) = fix(var, value)
function _fix(var::VariableRef, value::Number)
    if !isnan(value)
        fix(var, value; force=true)
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
