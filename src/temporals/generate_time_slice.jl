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
    list_time_slice = Array{TimeSlice,1}()
    list_time_slice_temporal_block = Dict()
    for (k, blk) in enumerate(temporal_block())
        list_time_slice_temporal_block[blk] = Array{TimeSlice,1}()
        temp_block_start = start_datetime(temporal_block=blk)  # DateTime value
        temp_block_end = end_datetime(temporal_block=blk)  # DateTime value
        time_slice_start = temp_block_start
        i = 1
        while time_slice_start < temp_block_end
            duration = time_slice_duration(temporal_block=blk)(i=i)
            time_slice_end = time_slice_start + duration
            if time_slice_end > temp_block_end
                time_slice_end = temp_block_end
                @warn(
                    "the duration of the last time slice of temporal block $blk has been reduced "
                    * "to respect the specified end time"
                )
            end
            index = findfirst(
                x -> tuple(x.start, x.end_) == tuple(time_slice_start, time_slice_end),
                list_time_slice
            )
            if index != nothing
                existing_time_slice = list_time_slice[index]
                push!(list_time_slice_temporal_block[blk], existing_time_slice)
            else
                JuMP_name = "tb$(k)__t$(i)"
                new_time_slice = TimeSlice(time_slice_start, time_slice_end, JuMP_name)
                push!(list_time_slice, new_time_slice)
                push!(list_time_slice_temporal_block[blk], new_time_slice)
            end
            # Prepare for next iter
            time_slice_start = time_slice_end
            i += 1
        end
    end
    # TODO: Check if unique is actually needed here
    unique!(list_time_slice)

    # @Maren: The part about the argument that is passed. So can pass a temporal_block instead of a time_slice here?
    # Something like ts = time_slice()[1] followed by time_slice(ts) does not work?
    # @Maren: So how does this work exactly? list_time_slice is not stored somewhere?
    @suppress_err begin
        functionname_time_slice = "time_slice"

        @eval begin
            # Documentation needs to be updated
            """
                $($functionname_time_slice)(;temporal_block=nothing)

            Return all time slices in the model.
            If 'temporal_block' is not `nothing`, return only the time slices in that block.
            """
            function $(Symbol(functionname_time_slice))(;temporal_block=nothing) # propose to rename to time_slice
                if temporal_block == nothing
                    $list_time_slice
                elseif haskey($list_time_slice_temporal_block, temporal_block)
                    $list_time_slice_temporal_block[temporal_block]
                else
                    error("temporal block '$temporal_block' not defined")
                end
            end
            export $(Symbol(functionname_time_slice))
        end
    end
end
