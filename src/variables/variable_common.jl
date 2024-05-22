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
  - `non_anticipativity_time::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity time or nothing
  - `non_anticipativity_margin::Union{Function,Nothing}=nothing`: given an index, return the non-anticipatity margin or nothing
  - `required_history_period::Union{Period,Nothing}=nothing`: given an index, return the required history period or nothing
"""
function add_variable!(
    m::Model,
    name::Symbol,
    indices::Function;
    bin::Union{Function,Nothing}=nothing,
    int::Union{Function,Nothing}=nothing,
    lb::Union{FlexParameter,Parameter,Nothing}=nothing,
    ub::Union{FlexParameter,Parameter,Nothing}=nothing,
    initial_value::Union{Parameter,Nothing}=nothing,
    fix_value::Union{Parameter,Nothing}=nothing,
    internal_fix_value::Union{Parameter,Nothing}=nothing,
    replacement_value::Union{Function,Nothing}=nothing,
    non_anticipativity_time::Union{Parameter,Nothing}=nothing,
    non_anticipativity_margin::Union{Parameter,Nothing}=nothing,
    required_history_period::Union{Period,Nothing}=nothing,
    ind_map=Dict(),
)
    if required_history_period === nothing
        required_history_period = _model_duration_unit(m.ext[:spineopt].instance)(1)
    end
    t_start = start(first(time_slice(m)))
    t_history = TimeSlice(t_start - required_history_period, t_start)
    history_time_slices = [t for t in history_time_slice(m) if overlaps(t_history, t)]
    m.ext[:spineopt].variables_definition[name] = Dict{Symbol,Union{Function,Parameter,Vector{TimeSlice},Nothing}}(
        :indices => indices,
        :bin => bin,
        :int => int,
        :non_anticipativity_time => non_anticipativity_time,
        :non_anticipativity_margin => non_anticipativity_margin,
        :history_time_slices => history_time_slices,
    )
    lb = _nothing_if_empty(lb)
    ub = _nothing_if_empty(ub)
    initial_value = _nothing_if_empty(initial_value)
    fix_value = _nothing_if_empty(fix_value)
    internal_fix_value = _nothing_if_empty(internal_fix_value)
    t = vcat(history_time_slices, time_slice(m))
    first_ind = iterate(indices(m; t=t))
    K = first_ind === nothing ? Any : typeof(first_ind[1])
    # Some indices functions may use as default the temporal_blocks that exclude the history_time_slices.
    # This could cause trouble for variables in some constraints (e.g. units_on in constraint_unit_state_transition) 
    # when using representiative temporal structure.
    _iter_indices = Iterators.flatten((indices(m; t=t), indices(m; temporal_block=anything, t=history_time_slices)))
    vars = m.ext[:spineopt].variables[name] = Dict{K,Union{VariableRef,AffExpr,Call}}(
        ind => _add_variable!(m, name, ind, replacement_value) for ind in Set(_iter_indices) if !haskey(ind_map, ind)
    )
    inverse_ind_map = Dict(ref_ind => (ind, 1 / coeff) for (ind, (ref_ind, coeff)) in ind_map)
    Threads.@threads for ind in collect(keys(vars))
        # Resolve bin, int, lb, ub, fix_value and internal_fix_value for ind.
        # If we have an ind_map, then we need to combine any values given for the ind and its referrer.
        # For example, for the lower bound we need to take the maximum between the lower bound for ind,
        # and the lower bound for the referrer scaled by the appropriate factor.
        other_ind_and_factor = get(inverse_ind_map, ind, ())
        res_bin = _resolve(bin, ind, other_ind_and_factor...; default=false, reducer=any)
        res_int = _resolve(int, ind, other_ind_and_factor...; default=false, reducer=any)
        res_lb = _resolve(lb, m, ind, other_ind_and_factor...; reducer=max)
        res_ub = _resolve(ub, m, ind, other_ind_and_factor...; reducer=min)
        res_fix_value = _resolve(fix_value, m, ind, other_ind_and_factor...; reducer=_check_unique)
        res_internal_fix_value = _resolve(internal_fix_value, m, ind, other_ind_and_factor...; reducer=_check_unique)
        _finalize_variable!(vars[ind], res_bin, res_int, res_lb, res_ub, res_fix_value, res_internal_fix_value)
    end
    # A ref_ind may not be covered by keys(vars) unless 
    # the ind_map is carefully designed in specific variable adding functions.
    filtered_ind_map = Dict(ind => (ref_ind, coeff) for (ind, (ref_ind, coeff)) in ind_map if haskey(vars, ref_ind))
    merge!(vars, Dict(ind => coeff * vars[ref_ind] for (ind, (ref_ind, coeff)) in filtered_ind_map))
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
        # When a representative termporal structure is used, the syntax will generate representative periods mapping
        # only for the given indices, excluding the internally generated history_time_slice.
        vars, _representative_periods_mapping(m, vars, indices)
    )
    vars
end

_nothing_if_empty(p::Parameter) = isempty(indices(p)) ? nothing : p
_nothing_if_empty(x) = x

_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

function _add_variable!(m, name, ind, replacement_value)
    if replacement_value !== nothing
        ind_ = (analysis_time=_analysis_time(m), ind...)
        value = replacement_value(ind_)
        if value !== nothing
            return value
        end
    end
    @variable(m, base_name=_base_name(name, ind))
end

_check_unique(x, y) = x == y ? x : error("$x != $y")

_resolve(::Nothing, args...; default=nothing, kwargs...) = default
_resolve(f, ind; kwargs...) = f(ind)
_resolve(f, m, ind; kwargs...) = f(m; ind..., analysis_time=_analysis_time(m))
_resolve(f, ind, other_ind, _factor; reducer, kwargs...) = _apply(reducer, f(ind), f(other_ind))
function _resolve(f, m, ind, other_ind, factor; reducer, kwargs...)
    t0 = _analysis_time(m)
    _apply(reducer, f(m; ind..., analysis_time=t0), _mul(factor, f(m; other_ind..., analysis_time=t0)))
end

_mul(_factor, ::Nothing) = nothing
_mul(factor, x) = factor * x

_apply(reducer, x, ::Nothing) = x
_apply(reducer, ::Nothing, y) = y
_apply(reducer, ::Nothing, ::Nothing) = nothing
function _apply(reducer, x::Number, y::Number)
    if isnan(x)
        y
    elseif isnan(y)
        x
    else
        reducer(x, y)
    end
end
_apply(reducer, x::Call, y::Call) = Call(_apply, [reducer, x, y])

_finalize_variable!(x, args...) = nothing
function _finalize_variable!(var::VariableRef, bin, int, lb, ub, fix_value, internal_fix_value)
    m = owner_model(var)
    bin && set_binary(var)
    int && set_integer(var)
    _do_set_lower_bound(var, lb)
    _do_set_upper_bound(var, ub)
    _do_fix(var, fix_value; force=true)
    _do_fix(var, internal_fix_value; force=true)
end

_do_set_lower_bound(_var, ::Nothing) = nothing
_do_set_lower_bound(var, bound::Call) = set_lower_bound(var, bound)
_do_set_lower_bound(var, bound::Number) = isnan(bound) || set_lower_bound(var, bound)

_do_set_upper_bound(_var, ::Nothing) = nothing
_do_set_upper_bound(var, bound::Call) = set_upper_bound(var, bound)
_do_set_upper_bound(var, bound::Number) = isnan(bound) || set_upper_bound(var, bound)

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
