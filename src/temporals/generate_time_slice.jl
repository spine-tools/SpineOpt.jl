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
            push!(list_time_slice, time_slice_symbol)
            push!(list_timesliceblock[k], time_slice_symbol)
            push!(list_duration, Tuple([time_slice_symbol, duration]))
            push!(list_time_slice_detail, Tuple([time_slice_symbol, current, next]))
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
        functionname_time_slice = "time_slice"
        functionname_time_slice_detail = "time_slice_detail"
        functionname_duration = "duration"

        @eval begin
            """
                $($functionname_time_slice)(;t_before=nothing, t_after=nothing)

            The tuples of the list '$($functionname_time_slice)'. Returns all timeslices.
            Argument 'temporal_block' can be used to return the list of all timeslices for that temporal_block

            # Examples
            ```julia
            julia> time_slice(temporal_block=Symbol("three-hours"))
            8-element Array{Any,1}:
             Symbol("2018-02-22T10:30:00__2018-02-22T13:30:00")
             Symbol("2018-02-22T13:30:00__2018-02-22T16:30:00")
             Symbol("2018-02-22T16:30:00__2018-02-22T19:30:00")
             ...
             ```
            """
            function $(Symbol(functionname_time_slice))(;temporal_block=nothing) # propose to rename to time_slice
                if temporal_block == nothing
                    $list_time_slice
                elseif haskey($list_timesliceblock, temporal_block)
                    $list_timesliceblock[temporal_block]
                else
                    error("temporal block '$temporal_block' not defined")
                end
            end
            """
                $($functionname_time_slice_detail)(;t_before=nothing, t_after=nothing)

            The tuples of the list '$($functionname_time_slice_detail)'. Returns all timeslices and their start & enddates.
            Argument 'time_slice' can be used to return start & enddate for specific timeslice.

            # Examples
            ```julia
            julia> time_slice_detail(time_slice=Symbol("2018-02-22T10:30:00__2018-02-23T10:30:00"))
            1-element Array{Tuple{DateTime,DateTime},1}:
             (2018-02-22T10:30:00, 2018-02-23T10:30:00)
             ```
            """
            function $(Symbol(functionname_time_slice_detail))(;time_slice=nothing)
                if  time_slice==nothing
                    $list_time_slice_detail
                else
                    [(t2,t3) for (t1,t2,t3) in $list_time_slice_detail if t1 == time_slice]
                end
            end
            """
                $($functionname_duration)(;t_before=nothing, t_after=nothing)

            The tuples of the list '$($functionname_duration)'. Returns all timeslices and their durations in Minutes.
            Argument 'time_slice' can be used to return the duration for specific timeslice.

            # Examples
            ```julia
            julia> duration(time_slice=Symbol("2018-02-22T10:30:00__2018-02-23T10:30:00"))
            1-element Array{Minute,1}:
             1440 minutes
             ```
            """
            function $(Symbol(functionname_duration))(;time_slice=nothing)
                if  time_slice==nothing
                    $list_duration
                else
                    [t2 for (t1, t2) in $list_duration if t1 == time_slice]
                end
            end
            export $(Symbol(functionname_time_slice_detail))
            export $(Symbol(functionname_duration))
            export $(Symbol(functionname_time_slice))
        end
    end
end

#@Maren: Other parameters of time slice are to be added I assume? (similar to duration?)
