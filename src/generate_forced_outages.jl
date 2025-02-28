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
using Random

function _rand_time(mean_time, u; resolution)
    mean_time = (typeof(mean_time) == Float64 ? Day(mean_time) : mean_time)
    mean_time = round(mean_time, resolution(1))
    resolution(round(Int, rand(Exponential(iszero(mean_time.value) ? 1e-6 : mean_time.value))))
end

function _forced_outages(t_start, t_end, mttf, mttr, u; resolution)
    times = []
    t = t_start
    while t < t_end
        failure_time = t + _rand_time(mttf(unit=u, t=t,_strict=false),u; resolution)
        test_mttr = _rand_time(mttr(unit=u, t=t,_strict=false),u; resolution)
        repair_time = failure_time + test_mttr 
        push!(times, (failure_time, repair_time))
        t = repair_time
    end
    times
end
_forced_outages(t_start, t_end, ::Nothing, mttr, u; resolution) = []  # never fails
_forced_outages(t_start, t_end, ::Nothing, ::Nothing, u; resolution) = []  # never fails
_forced_outages(t_start, t_end, mttf, ::Nothing, u; resolution) = [(t_start + _rand_time(mttf; resolution), t_end)] #TODO: fix me too

function forced_outage_time_series(t_start, t_end, mttf, mttr, u; seed=nothing, resolution=Hour)
    seed === nothing || Random.seed!(seed)
    indices = [t_start]
    values = [0] # TODO: why is first one fixed to 0? I think this should be arbitrary - seems to be for initialization purposes alright, but could be revisited in the future
    for (failure_time, repair_time) in _forced_outages(t_start, t_end, mttf, mttr, u; resolution)
        append!(indices, [failure_time, repair_time]) 
        append!(values, [1, 0])
    end
    # push!(indices, t_end) 
    # push!(values, 0)
    # TODO: please advise:
    # I have uncommented above as I think it'd be better if the timeseries reflects the "true" status (e.g., 1 or 0) 
    # at the end of the model horizon (especially if timeseries is to be used again for other purpose later on)
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
        raw"sqlite:///C:\\path\\to\\your\\output_db.sqlite", 
        on_conflict="replace")

"""
function generate_forced_outages(url_in, url_out=url_in; alternative="Base", on_conflict="replace")
    #Added the "on_conflict = replace" argument: In most cases, I believe we'd want to overwrite outages rahter than append
    # e.g. I could see running this script twixe would add overproportional amount of outages to the timeseries
    using_spinedb(url_in)
    m_start = minimum(model_start(model=m) for m in model())
    m_end = maximum(model_end(model=m) for m in model())
    forced_outage_ts = Dict(
        (unit = u,) => forced_outage_time_series(
            m_start, #model start
            m_end, #model end
            mean_time_to_failure,#(unit=u, _strict=false),
            mean_time_to_repair,#(unit=u, _strict=false)
            u,
        )
        for u in indices(mean_time_to_failure)
    )
    if !isempty(forced_outage_ts)
        write_parameters(
            Dict(:units_unavailable => forced_outage_ts), url_out; alternative=alternative, on_conflict=on_conflict
        )
    end
end