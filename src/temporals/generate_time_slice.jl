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
    temporal_block_list::Dict{Object,Array{TimeSlice,1}}
end

"""
    time_slice(;temporal_block=nothing)

Return all time slices in the model.
If 'temporal_block' is not `nothing`, return only the time slices in that block.
"""
function (time_slice::TimeSliceObjectClass)(;temporal_block=nothing, t_overlap=nothing)
    if temporal_block == nothing
        time_slice.list
    else
        [t for tblk in Object.(temporal_block) for ts in time_slice.temporal_block_list[tblk] for t in ts]
    end
end

"""
    generate_time_slice()

"""
function generate_time_slice()
    # NOTE: not checking if the timeslice exists makes it 15 times faster
    time_slice_temporal_block_list = Dict{Object,Array{TimeSlice,1}}()
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
            new_time_slice = TimeSlice(time_slice_start, time_slice_end, "$(blk)__t$(i)")
            push!(time_slice_list, new_time_slice)
            # Prepare for next iter
            time_slice_start = time_slice_end
            i += 1
        end
        time_slice_temporal_block_list[blk] = time_slice_list
    end
    time_slice_list = unique(t for v in values(time_slice_temporal_block_list) for t in v)
    # Create and export the function like object
    time_slice = TimeSliceObjectClass(time_slice_list, time_slice_temporal_block_list)
    @eval begin
        time_slice = $time_slice
        export time_slice
    end
end
