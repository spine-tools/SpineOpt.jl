#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
using Random

function _rand_time(mean_time; resolution)
    mean_time = round(mean_time, resolution(1))
    resolution(ceil(rand(Exponential(mean_time.value))))
end

function _forced_outages(t_start, t_end, mttf, mttr; resolution)
    times = []
    t = t_start
    while t < t_end
        failure_time = t + _rand_time(mttf; resolution)
        repair_time = failure_time + _rand_time(mttr; resolution)
        push!(times, (failure_time, repair_time))
        t = repair_time
    end
    times
end
_forced_outages(t_start, t_end, ::Nothing, mttr; resolution) = []  # never fails
_forced_outages(t_start, t_end, ::Nothing, ::Nothing; resolution) = []  # never fails
_forced_outages(t_start, t_end, mttf, ::Nothing; resolution) = [(t_start + _rand_time(mttf; resolution), t_end)]

function forced_outage_time_series(t_start, t_end, mttf, mttr, nb_of_units; seed=nothing, resolution=Hour)
    indices = [t_start]
    values = [0.0]
    if nb_of_units > 0
        seed === nothing || Random.seed!(seed)
        for (failure_time, repair_time) in _forced_outages(t_start, t_end, mttf, mttr; resolution)
            append!(indices, [failure_time, repair_time])
            append!(values, [nb_of_units, 0.0])
        end
    end
    if last(indices) < t_end
        push!(indices, t_end)
        push!(values, 0.0)
    end
    TimeSeries(indices, values)
end

"""
    generate_forced_outages(url_in, url_out; <keyword arguments>)

Generate forced outages from the contents of `url_in` and write them to `url_out`.
At least `url_in` must point to a valid Spine database.
A new Spine database is created at `url_out` if one doesn't exist.

To generate forced outages for a unit, specify `mean_time_to_failure` and optionally
`mean_time_to_repair` for that unit as a duration in the input DB.

Parameter `units_unavailable` will be written for those units in the output DB holding a time series.

# Arguments

- `alternative::String=""`: if non empty, write results to the given alternative in the output DB.

- `filters::Dict{String,String}=Dict("tool" => "object_activity_control")`: a dictionary to specify filters.
  Possible keys are "tool" and "scenario". Values should be a tool or scenario name in the input DB.

# Example

    using SpineOpt
    m = generate_forced_outages(
        raw"sqlite:///C:\\path\\to\\your\\input_db.sqlite", 
        raw"sqlite:///C:\\path\\to\\your\\output_db.sqlite"
    )

"""
function generate_forced_outages(url_in, url_out=url_in; alternative="Base")
    using_spinedb(url_in, @__MODULE__)
    m_start = minimum(model_start(model=m) for m in model())
    m_end = maximum(model_end(model=m) for m in model())
    forced_outage_ts = Dict(
        u => forced_outage_time_series(
            m_start,
            m_end,
            mean_time_to_failure(unit=u, _strict=false),
            mean_time_to_repair(unit=u, _strict=false),
            number_of_units(unit=u, _default=_default_nb_of_units(u)),
        )
        for u in indices(mean_time_to_failure)
    )
    if !isempty(forced_outage_ts)
        write_parameters(
            Dict(:units_unavailable => forced_outage_ts), url_out; alternative=alternative
        )
    end
end