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
using Distributions

function _rand_time(mean_time)
    mean_time = round(mean_time, Minute(1))
    Minute(round(Int, rand(Exponential(iszero(mean_time.value) ? 1e-6 : mean_time.value))))
end

function _forced_outages(t_start, t_end, mttf, mttr)
    times = []
    t = t_start
    while t < t_end
        failure_time = t + _rand_time(mttf)
        repair_time = failure_time + _rand_time(mttr)
        push!(times, (failure_time, repair_time))
        t = repair_time
    end
    times
end
_forced_outages(t_start, t_end, ::Nothing, mttr) = []  # never fails
_forced_outages(t_start, t_end, ::Nothing, ::Nothing) = []  # never fails
_forced_outages(t_start, t_end, mttf, ::Nothing) = [(t_start + _rand_time(mttf), t_end)]  # fails once, never repairs

function forced_availability_factor_time_series(t_start, t_end, mttf, mttr, failure_availability_factor=0)
    indices = [t_start]
    values = [1.0]
    for (failure_time, repair_time) in _forced_outages(t_start, t_end, mttf, mttr)
        append!(indices, [failure_time, repair_time])
        append!(values, [failure_availability_factor, 1])
    end
    push!(indices, t_end)
    push!(values, 1)
    TimeSeries(indices, values, false, false)
end

"""
    generate_forced_availability_factor(url_in, url_out; <keyword arguments>)

Generate forced availability factors (due to outages) from the contents of `url_in` and write them to `url_out`.
At least `url_in` must point to a valid Spine database.
A new Spine database is created at `url_out` if one doesn't exist.

To generate forced availability factors for an entity, specify `mean_time_to_failure` and optionally
`mean_time_to_repair` for that entity as a duration in the input DB.

Parameter `forced_availability_factor` will be written for those entites in the output DB, holding a time series
with the availability factor due to forced outages.

# Arguments

- `alternative::String=""`: if non empty, write results to the given alternative in the output DB.

- `filters::Dict{String,String}=Dict("tool" => "object_activity_control")`: a dictionary to specify filters.
  Possible keys are "tool" and "scenario". Values should be a tool or scenario name in the input DB.

# Example

    using SpineOpt
    m = generate_forced_availability_factor(
        raw"sqlite:///C:\\path\\to\\your\\inputputdb.sqlite", 
        raw"sqlite:///C:\\path\\to\\your\\outputdb.sqlite"
    )

"""
function generate_forced_availability_factor(url_in, url_out=url_in; filters=Dict(), alternative="Base")
    using_spinedb(url_in, @__MODULE__; filters=filters)
    m_start = minimum(model_start(model=m) for m in model())
    m_end = maximum(model_end(model=m) for m in model())
    forced_availability_factor = Dict(
        entity => forced_availability_factor_time_series(
            m_start,
            m_end,
            mean_time_to_failure(; entity..., _strict=false),
            mean_time_to_repair(; entity..., _strict=false)
        )
        for entity in indices_as_tuples(mean_time_to_failure)
    )
    if !isempty(forced_availability_factor)
        write_parameters(
            Dict(:forced_availability_factor => forced_availability_factor), url_out; alternative=alternative
        )
    end
end