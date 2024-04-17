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
)
    t_start_time_slice = start(first(time_slice(m)))
    dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
    if isnothing(required_history_period)
        history_period = TimeSlice(t_start_time_slice - dur_unit(1), t_start_time_slice)
    else
        history_period = TimeSlice(t_start_time_slice - required_history_period, t_start_time_slice)
    end
    required_history = [t for t in history_time_slice(m) if overlaps(history_period, t)]
    m.ext[:spineopt].variables_definition[name] = Dict{Symbol,Union{Function,Parameter,Vector{TimeSlice},Nothing}}(
        :indices => indices,
        :bin => bin,
        :int => int,
        :non_anticipativity_time => non_anticipativity_time,
        :non_anticipativity_margin => non_anticipativity_margin,
        :required_history => required_history
    )
    lb = _nothing_if_empty(lb)
    ub = _nothing_if_empty(ub)
    initial_value = _nothing_if_empty(initial_value)
    fix_value = _nothing_if_empty(fix_value)
    internal_fix_value = _nothing_if_empty(internal_fix_value)
    var = m.ext[:spineopt].variables[name] = Dict(
        ind => _variable(
            m,
            name,
            ind,
            bin,
            int,
            lb,
            ub,
            fix_value,
            internal_fix_value,
            replacement_value
        )
        for ind in indices(m; t=vcat(required_history, time_slice(m)))
    )
    # Apply initial value, but make sure it updates itself by using a TimeSeries Call
    if initial_value !== nothing
        last_history_t = last(history_time_slice(m))
        t0 = model_start(model=m.ext[:spineopt].instance)
        for (ind, v) in var
            overlaps(ind.t, last_history_t) || continue
            val = initial_value(; ind..., _strict=false)
            val === nothing && continue
            initial_value_ts = parameter_value(TimeSeries([t0 - dur_unit(1), t0], [val, NaN]))
            fix(v, Call(initial_value_ts, (t=ind.t,), (Symbol(:initial_, name), ind)))
        end
    end
    isempty(SpineInterface.indices(representative_periods_mapping)) || merge!(
        var, _representative_periods_mapping(m, var, indices)
    )
    var
end

_nothing_if_empty(p::Parameter) = isempty(indices(p)) ? nothing : p
_nothing_if_empty(x) = x

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
function _representative_periods_mapping(m::Model, var::Dict, indices::Function)
    # By default, `indices` skips represented time slices for operational variables other than node_state,
    # as well as for investment variables. This is done by setting the default value of the `temporal_block` argument
    # to `temporal_block(representative_periods_mapping=nothing)` - so any blocks that define a mapping are ignored.
    # To include represented time slices, we need to specify `temporal_block=anything`.
    # Note that for node_state and investment variables, `represented_indices`, below, will be empty.
    representative_indices = indices(m)
    all_indices = indices(m, temporal_block=anything)
    represented_indices = setdiff(all_indices, representative_indices)
    Dict(ind => var[_representative_index(m, ind, indices)] for ind in represented_indices)
end

_base_name(name, ind) = string(name, "[", join(ind, ", "), "]")

function _variable(m, name, ind, bin, int, lb, ub, fix_value, internal_fix_value, replacement_value)
    ind_ = (analysis_time=_analysis_time(m), ind...)
    if replacement_value !== nothing
        value = replacement_value(ind_)
        if value !== nothing
            return value
        end
    end
    var = @variable(m, base_name = _base_name(name, ind))
    if haskey(ind, :t)
        add_roll_hook!(ind.t, (; var=var, name=name, ind=ind) -> set_name(var, _base_name(name, ind)))
    end
    bin !== nothing && bin(ind_) && set_binary(var)
    int !== nothing && int(ind_) && set_integer(var)
    lb === nothing || _do_set_lower_bound(var, lb(m; ind_..., _strict=false))
    ub === nothing || _do_set_upper_bound(var, ub(m; ind_..., _strict=false))
    fix_value === nothing || _do_fix(var, fix_value(m; ind_..., _strict=false); force=true)
    internal_fix_value === nothing || _do_fix(var, internal_fix_value(m; ind_..., _strict=false); force=true)
    var
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
    _get_max_duration(m::Model, lookback_params::Vector{Parameter})

A function to get the maximum duration from a list of parameters.
"""
function _get_max_duration(m::Model, lookback_params::Vector{Parameter})
    max_vals = (maximum_parameter_value(p) for p in lookback_params)
    dur_unit = _model_duration_unit(m.ext[:spineopt].instance)
    reduce(max, (val for val in max_vals if val !== nothing); init=dur_unit(1))
end
