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
struct TimeSliceSet
    list::Array{TimeSlice,1}
    block_slice_list::Dict{Object,Array{TimeSlice,1}}
    block_slice_index::Dict{Object,Array{Int64,1}}
end

struct ToTimeSlice
    list::Array{TimeSlice,1}
    block_slice_list::Dict{Object,Array{TimeSlice,1}}
    block_slice_index::Dict{Object,Array{Int64,1}}
end

"""
    time_slice(;temporal_block=anything, t=anything)

An array of all time slices in the model.
If 'temporal_block' is not `nothing`, return only the time slices in that block.
If 't' is not `nothing`, return only the time slices from `t`.
"""
function (time_slice::TimeSliceSet)(;temporal_block=anything, t=anything)
    if temporal_block == anything
        if t == anything
            time_slice.list
        else
            [s for s in t if any(blk in keys(time_slice.block_slice_list) for blk in s.blocks)]
        end
    else
        if t == anything
            [s for tblk in Object.(temporal_block) for ts in time_slice.block_slice_list[tblk] for s in ts]
        else
            [s for s in t if any(blk in Object.(temporal_block) for blk in s.blocks)]
        end
    end
end

"""
    to_time_slice(t::TimeSlice...)

An array of time slices *in the model* that overlap `t`,
where `t` may not be in the model.
"""
function (to_time_slice::ToTimeSlice)(t::TimeSlice...)
    d = Dict{Object,Array{Int64,1}}()
    for (blk, index) in to_time_slice.block_slice_index
        temp_block_start = start_datetime(temporal_block=blk)
        temp_block_end = end_datetime(temporal_block=blk)
        ranges = []
        for s in t
            start = max(temp_block_start, s.start)
            end_ = min(temp_block_end, s.end_)
            end_ <= start && continue
            first_ind = index[Minute(start - temp_block_start).value + 1]
            last_ind = index[Minute(end_ - temp_block_start).value]
            push!(ranges, first_ind:last_ind)
        end
        isempty(ranges) && continue
        d[blk] = union(ranges...)
    end
    [t for (blk, xs) in d for t in to_time_slice.block_slice_list[blk][xs]]
end

"""
    to_time_slice(t::TimeSlice...)

An array of time slices *in the model* that overlap `t`.
"""
function (to_time_slice::ToTimeSlice)(t::DateTime...)
    d = Dict{Object,Array{Int64,1}}()
    for (blk, index) in to_time_slice.block_slice_index
        temp_block_start = start_datetime(temporal_block=blk)
        temp_block_end = end_datetime(temporal_block=blk)
        d[blk] = unique(
            index[Minute(s - temp_block_start).value + 1]
            for s in t if temp_block_start <= s < temp_block_end
        )
    end
    [t for (blk, xs) in d for t in to_time_slice.block_slice_list[blk][xs]]
end

"""
    generate_time_slice_set()

"""
function generate_time_slice()
    block_slice_list = Dict{Object,Array{TimeSlice,1}}()
    block_start_end_list = Dict{Object,Array{Tuple{DateTime,DateTime},1}}()
    block_slice_index = Dict{Object,Array{Int64,1}}()
    slice_blocks = Dict{Tuple{DateTime,DateTime},Array{Object,1}}()
    for blk in temporal_block()
        start_end_list = Array{Tuple{DateTime,DateTime},1}()
        temp_block_start = start_datetime(temporal_block=blk)  # DateTime value
        temp_block_end = end_datetime(temporal_block=blk)  # DateTime value
        temp_block_minutes = Minute(temp_block_end - temp_block_start).value
        time_slice_index = Array{Int64,1}(undef, temp_block_minutes)
        i = 1
        time_slice_start = temp_block_start
        while time_slice_start < temp_block_end
            duration = time_slice_duration(temporal_block=blk, i=i)
            time_slice_end = time_slice_start + duration
            if time_slice_end > temp_block_end
                time_slice_end = temp_block_end
                @warn(
                    "the duration of the last time slice of temporal block $blk has been reduced "
                    * "to respect the specified end time"
                )
            end
            # NOTE: Letting the time slice be named automatically makes them unique across blocks!
            start_end = (time_slice_start, time_slice_end)
            push!(get!(slice_blocks, start_end, Array{Object,1}()), blk)
            push!(start_end_list, start_end)
            # Index new_time_slice
            for x in time_slice_start:Minute(1):time_slice_end - Minute(1)
                time_slice_index[Minute(x - temp_block_start).value + 1] = i
            end
            # Prepare for next iter
            time_slice_start = time_slice_end
            i += 1
        end
        block_start_end_list[blk] = start_end_list
        block_slice_index[blk] = time_slice_index
    end
    for (blk, start_end_list) in block_start_end_list
        time_slice_list = Array{TimeSlice,1}()
        for start_end in start_end_list
            time_slice_start, time_slice_end = start_end
            blocks = slice_blocks[start_end]
            push!(time_slice_list, TimeSlice(time_slice_start, time_slice_end, blocks...))
        end
        block_slice_list[blk] = time_slice_list
    end
    time_slice_list = unique(t for v in values(block_slice_list) for t in v)
    # Create and export the function like object
    time_slice = TimeSliceSet(time_slice_list, block_slice_list, block_slice_index)
    to_time_slice = ToTimeSlice(time_slice_list, block_slice_list, block_slice_index)
    @eval begin
        time_slice = $time_slice
        to_time_slice = $to_time_slice
        export time_slice
        export to_time_slice
    end
end
