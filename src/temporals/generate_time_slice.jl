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
struct TimeSliceObjectClass
    list::Array{TimeSlice,1}
    block_slice_list::Dict{Object,Array{TimeSlice,1}}
    block_slice_index::Dict{Object,Array{Int64,1}}
end

"""
    time_slice(;temporal_block=nothing)

Return all time slices in the model.
If 'temporal_block' is not `nothing`, return only the time slices in that block.
"""
function (time_slice::TimeSliceObjectClass)(;temporal_block=anything, t=anything)
    if temporal_block == anything
        if t == anything
            time_slice.list
        else
            t
        end
    else
        if t == anything
            [s for tblk in Object.(temporal_block) for ts in time_slice.block_slice_list[tblk] for s in ts]
        else
            [s for tblk in Object.(temporal_block) for ts in time_slice.block_slice_list[tblk] for s in ts if s in t]
        end
    end
end


function overlap(time_slice::TimeSliceObjectClass, t::TimeSlice)
    d = Dict{Object,Array{Int64,1}}()
    for (blk, index) in time_slice.block_slice_index
        temp_block_start = start_datetime(temporal_block=blk)
        temp_block_end = end_datetime(temporal_block=blk)
        start = max(temp_block_start, t.start)
        end_ = min(temp_block_end, t.end_)
        end_ <= start && continue
        first_pos = index[Minute(start - temp_block_start).value + 1]
        last_pos = index[Minute(end_ - temp_block_start).value]
        d[blk] = first_pos:last_pos
    end
    [t for (blk, xs) in d for t in time_slice.block_slice_list[blk][xs]]
end

"""
    generate_time_slice()

"""
function old_generate_time_slice()
    # NOTE: not checking if the timeslice exists makes it 15 times faster
    block_slice_list = Dict{Object,Array{TimeSlice,1}}()
    slice_block_list = Dict{TimeSlice,Array{Object,1}}()
    for (k, blk) in enumerate(temporal_block())
        time_slice_list = Array{TimeSlice,1}()
        temp_block_start = start_datetime(temporal_block=blk)  # DateTime value
        temp_block_end = end_datetime(temporal_block=blk)  # DateTime value
        time_slice_start = temp_block_start
        i = 1
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
            new_time_slice = TimeSlice(time_slice_start, time_slice_end)
            push!(time_slice_list, new_time_slice)
            push!(get!(slice_block_list, new_time_slice, []), blk)
            # Prepare for next iter
            time_slice_start = time_slice_end
            i += 1
        end
        block_slice_list[blk] = time_slice_list
    end
    time_slice_list = unique(t for v in values(block_slice_list) for t in v)
    # Create and export the function like object
    time_slice = TimeSliceObjectClass(time_slice_list, block_slice_list, slice_block_list)
    @eval begin
        time_slice = $time_slice
        export time_slice
    end
end


function generate_time_slice()
    # NOTE: not checking if the timeslice exists makes it 15 times faster
    block_slice_list = Dict{Object,Array{TimeSlice,1}}()
    block_slice_index = Dict{Object,Array{Int64,1}}()
    for blk in temporal_block()
        time_slice_list = Array{TimeSlice,1}()
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
            new_time_slice = TimeSlice(time_slice_start, time_slice_end)
            push!(time_slice_list, new_time_slice)
            for x in time_slice_start:Minute(1):time_slice_end - Minute(1)
                time_slice_index[Minute(x - temp_block_start).value + 1] = i
            end
            # Prepare for next iter
            time_slice_start = time_slice_end
            i += 1
        end
        block_slice_list[blk] = time_slice_list
        block_slice_index[blk] = time_slice_index
    end
    time_slice_list = unique_sorted(sort([t for v in values(block_slice_list) for t in v]))
    # Create and export the function like object
    time_slice = TimeSliceObjectClass(time_slice_list, block_slice_list, block_slice_index)
    @eval begin
        time_slice = $time_slice
        export time_slice
    end
end
