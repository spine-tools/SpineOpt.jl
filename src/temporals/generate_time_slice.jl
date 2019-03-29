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
    @butcher list_time_slice = []
    list_duration = []
    list_time_slice_detail = []
    list_timesliceblock = Dict()
    for k in temporal_block()
        list_timesliceblock[k]=[]
        if time_slice_duration()[:temporal_block][k][2] == nothing
            for x in collect(start_date(k):Minute(time_slice_duration()[:temporal_block][k][1]):end_date(k)-Minute(time_slice_duration()[:temporal_block][k][1]))
                time_slice_symbol = Symbol("t_$(year(x))_$(month(x))_$(day(x))_$(hour(x))_$(minute(x))__$(year(x+Minute(time_slice_duration()[:temporal_block][k][1])))_$(month(x+Minute(time_slice_duration()[:temporal_block][k][1])))_$(day(x+Minute(time_slice_duration()[:temporal_block][k][1])))_$(hour(x+Minute(time_slice_duration()[:temporal_block][k][1])))_$(minute(x+Minute(time_slice_duration()[:temporal_block][k][1])))")
                list_time_slice = push!(list_time_slice,time_slice_symbol)
                list_timesliceblock[k] = push!(list_timesliceblock[k],time_slice_symbol)
                list_duration = push!(list_duration,Tuple([time_slice_symbol, (Minute(time_slice_duration()[:temporal_block][k][1]))]))
                list_time_slice_detail = push!(list_time_slice_detail,Tuple([time_slice_symbol,x,x+Minute(time_slice_duration()[:temporal_block][k][1])]))
            end
        else
            x = start_date(k)
            for j = 1:(length(time_slice_duration()[:temporal_block][k])-1)
                time_slice_symbol = Symbol("t_$(year(x))_$(month(x))_$(day(x))_$(hour(x))_$(minute(x))__$(year(x+Minute(time_slice_duration()[:temporal_block][k][j])))_$(month(x+Minute(time_slice_duration()[:temporal_block][k][j])))_$(day(x+Minute(time_slice_duration()[:temporal_block][k][j])))_$(hour(x+Minute(time_slice_duration()[:temporal_block][k][j])))_$(minute(x+Minute(time_slice_duration()[:temporal_block][k][j])))")
                list_time_slice = push!(list_time_slice,time_slice_symbol)
                list_timesliceblock[k] = push!(list_timesliceblock[k],time_slice_symbol)
                list_duration = push!(list_duration,Tuple([time_slice_symbol, (Minute(time_slice_duration()[:temporal_block][k][j]))]))
                list_time_slice_detail = push!(list_time_slice_detail,Tuple([time_slice_symbol,x,x+Minute(time_slice_duration()[:temporal_block][k][1])]))
                x = x+Minute(time_slice_duration()[:temporal_block][k][j])
            end
            if x != end_date(k)
                @warn "WARNING: Last timeslice of $k doesn't coinside with defined enddate for temporalblock $k"
            end
        end
    end
    # Remove possible duplicates of time slices defined in different temporal blocks
    unique!(list_time_slice)
    unique!(list_time_slice_detail)
    unique!(list_duration)

    # @Maren: The part about the argument that is passed. So can pass a temporal_block instead of a time_slice here? Something like ts = time_slice()[1] followed by time_slice(ts) does not work?
    # @Maren: So how does this work exactly? list_time_slice is not stored somewhere?
    function time_slice(;kwargs...) #propose to rename to time_slice
        if length(kwargs) == 0
            list_time_slice
        elseif length(kwargs) == 1
            key, value = iterate(kwargs)[1]
            if key == :temporal_block
                timeslicesblock = list_timesliceblock[value]
                timeslicesblock
            end
        end
    end

    # @Maren: So this is a shortway to define a function
    time_slice_detail() = list_time_slice_detail
    duration() = list_duration
    time_slice,time_slice_detail,duration
end

#@Maren: Other parameters of time slice are to be added I assume? (similar to duration?)
