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


"""
    generate_time_slice()

"""
function generate_time_slice()
    # TODO: make @butcher work here
    list_time_slice = []
    list_duration = []
    list_time_slice_detail = []
    list_timesliceblock = Dict()
    for k in temporal_block()
        list_timesliceblock[k] = []
        start = start_datetime(temporal_block=k)  # DateTime value
        stop = end_datetime(temporal_block=k)  # DateTime value
        current = start
        i = 1
        while true
            duration = Minute(time_slice_duration(temporal_block=k, t=i))
            next = current + duration
            if next > stop
                current == stop || @warn(
                    "last timeslice of $k doesn't match with defined end date."
                )
                break
            end
            time_slice_symbol = Symbol(current, "__", next)
            list_time_slice = push!(list_time_slice, time_slice_symbol)
            list_timesliceblock[k] = push!(list_timesliceblock[k], time_slice_symbol)
            list_duration = push!(list_duration, Tuple([time_slice_symbol, duration]))
            list_time_slice_detail = push!(list_time_slice_detail, Tuple([time_slice_symbol, current, next]))
            # Prepare for next iter
            current = next
            i += 1
        end
    end
    # Remove possible duplicates of time slices defined in different temporal blocks
    unique!(list_time_slice)
    unique!(list_time_slice_detail)
    unique!(list_duration)

    # @Maren: The part about the argument that is passed. So can pass a temporal_block instead of a time_slice here? Something like ts = time_slice()[1] followed by time_slice(ts) does not work?
    # @Maren: So how does this work exactly? list_time_slice is not stored somewhere?
    @suppress_err begin
        @eval begin
            function $(Symbol("time_slice"))(;temporal_block=nothing) # propose to rename to time_slice
                if temporal_block == nothing
                    $list_time_slice
                elseif haskey($list_timesliceblock, temporal_block)
                    $list_timesliceblock[temporal_block]
                else
                    error("temporal block '$temporal_block' not defined")
                end
            end
            function $(Symbol("time_slice_detail"))(;time_slice=nothing)
                if  time_slice==nothing
                    $list_time_slice_detail
                else
                    [t2 for (t1, t2) in $list_time_slice_detail if t1 == time_slice]
                end
            end
            function $(Symbol("duration"))(;time_slice=nothing)
                if  time_slice==nothing
                    $list_duration
                else
                    [t2 for (t1, t2) in $list_duration if t1 == time_slice]
                end
            end
            export $(Symbol("time_slice_detail"))
            export $(Symbol("duration"))
            export $(Symbol("time_slice"))
        end
    end
end

#@Maren: Other parameters of time slice are to be added I assume? (similar to duration?)
