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
# TODO: have an eye on where unique! is necessary for speedup
# TODO: add examples to all docstrings when all this begins to converge

"""
    generate_time_slice_relationships()

Create and export convenience functions to access time slice relationships:
`t_in_t`, `t_preceeds_t`, `t_overlaps_t`...
"""
function generate_time_slice_relationships()
    list_t_before_t = []
    list_t_in_t = []
    list_t_overlaps_t = []
    for i in time_slice()
        for j in time_slice()
            if succeeds(j, i)
                push!(list_t_before_t, tuple(i, j))
            end
            if in(i, j)
                push!(list_t_in_t, tuple(i, j))
            end
            if overlaps(i, j)
                push!(list_t_overlaps_t, tuple(i, j))
            end
        end
    end
    # TODO: instead of unique -> check beforehand whether timeslice tuple is already added
    # Is `unique!()` slow? I fear the above check can be a bit slow.
    # An alternative is to use `Set()` instead of `[]` to warranty uniqueness,
    # but then we lose the order - do we care about order?
    unique!(list_t_in_t)
    unique!(list_t_overlaps_t)
    list_t_in_t_excl = [(t1, t2) for (t1, t2) in list_t_in_t if t1 != t2]
    list_t_overlaps_t_excl = [(t1, t2) for (t1, t2) in list_t_overlaps_t if t1 != t2]

    @suppress_err begin
        # NOTE: Not sure why this is needed? -Manuel
        # functionname_t_before_t = "t_before_t"
        # functionname_t_in_t = "t_in_t"
        # functionname_t_in_t_excl = "t_in_t_excl"
        # functionname_t_overlaps_t = "t_overlaps_t"
        # functionname_t_overlaps_t_excl = "t_overlaps_t_excl"
        # functionname_t_lowest_resolution = "t_lowest_resolution"
        # functionname_t_highest_resolution = "t_highest_resolution"

        @eval begin
            """
                t_before_t(;t_before=nothing, t_after=nothing, t_list=nothing)

            Return the list of tuples `(t1, t2)` where `t2` *succeeds* `t1` in the sense that it
            starts right after `t1` ends, i.e. `t2.start == t1.end_`.
            If `t_before` is not `nothing`, return the list of time slices that succeed `t_before`
            (or any element in `t_before` if it's a list).
            If `t_after` is not `nothing`, return the list of time slices that are succeeded by `t_after`
            (or any element in `t_after` if it's a list).
            If `t_list` is specified, only return tuples of time slices or time slices that appear in `t_list`.
            """
            function t_before_t(;t_before=nothing, t_after=nothing, t_list=nothing)
                result = $list_t_before_t
                if t_before != nothing
                    result = [(t1, t2) for (t1, t2) in result if t1 in tuple(t_before...)]
                end
                if t_after != nothing
                    result = [(t1, t2) for (t1, t2) in result if t2 in tuple(t_after...)]
                end
                if t_list != nothing
                    result = [(t1, t2) for (t1, t2) in result if t1 in tuple(t_list...) && t2 in tuple(t_list...)]
                end
                if t_before != nothing && t_after == nothing
                    [t2 for (t1, t2) in result]
                elseif t_before == nothing && t_after != nothing
                    [t1 for (t1, t2) in result]
                else
                    result
                end
            end

            """
                t_in_t(;t_short=nothing, t_long=nothing, t_list=nothing)

            Return the list of tuples `(t1, t2)`, where `t2` is contained in `t1`.
            If `t_long` is not `nothing`, return the list of time slices contained in `t_long`
            (or any element in `t_long` if it's a list).
            If `t_short` is not `nothing`, return the list of time slices that contain `t_short`
            (or any element in `t_short` if it's a list).
            If `t_list` is specified, only return tuples of time slices or time slices that appear in `t_list`.
            """
            function t_in_t(;t_short=nothing, t_long=nothing, t_list=nothing)
                result = $list_t_in_t
                if t_short != nothing
                    result = [(t1, t2) for (t1, t2) in result if t1 in tuple(t_short...)]
                end
                if t_long != nothing
                    result = [(t1, t2) for (t1, t2) in result if t2 in tuple(t_long...)]
                end
                if t_list != nothing
                    result = [(t1, t2) for (t1, t2) in result if t1 in tuple(t_list...) && t2 in tuple(t_list...)]
                end
                if t_short != nothing && t_long == nothing
                    [t2 for (t1, t2) in result]
                elseif t_short == nothing && t_long != nothing
                    [t1 for (t1, t2) in result]
                else
                    result
                end
            end

            """
                t_in_t_excl(;t_short=nothing, t_long=nothing, t_list=nothing)

            Return the list of tuples `(t1, t2)`, where `t1` contains `t2` and `t1` is different from `t2`.
            See [`t_in_t(;t_long=nothing, t_short=nothing; t_list=nothing)`](@ref)
            for details about keyword arguments `t_long`, `t_short` and `t_list`.
            """
            function t_in_t_excl(;t_short=nothing, t_long=nothing, t_list=nothing)
                result = $list_t_in_t_excl
                if t_short != nothing
                    result = [(t1, t2) for (t1, t2) in result if t1 in tuple(t_short...)]
                end
                if t_long != nothing
                    result = [(t1, t2) for (t1, t2) in result if t2 in tuple(t_long...)]
                end
                if t_list != nothing
                    result = [(t1, t2) for (t1, t2) in result if t1 in tuple(t_list...) && t2 in tuple(t_list...)]
                end
                if t_short != nothing && t_long == nothing
                    [t2 for (t1, t2) in result]
                elseif t_short == nothing && t_long != nothing
                    [t1 for (t1, t2) in result]
                else
                    result
                end
            end
            """
                t_overlaps_t(;t_list=nothing)

            Return the list of tuples `(t1, t2)` where `t1` and `t2` have some time in common.
            If `t_list` is specified, only return tuples of time slices that appear in `t_list`.
            """
            function t_overlaps_t(;t_list=nothing)
                result = $list_t_overlaps_t
                if t_list == nothing
                    result
                else
                    [(t1, t2) for (t1, t2) in result if t1 in tuple(t_list...) && t2 in tuple(t_list...)]
                end
            end
            """
                t_overlaps_t(t_overlap::Union{TimeSlice,Array{TimeSlice,1}}; t_list=nothing)

            Return the list of time slices that have some time in common with `t_overlap`
            (or some time in common with any element in `t_overlap` if it's a list).
            If `t_list` is specified, only return time slices that appear in `t_list`.
             ```
            """
            function t_overlaps_t(t_overlap::Union{TimeSlice,Array{TimeSlice,1}}; t_list=nothing)
                result = unique(t2 for (t1, t2) in $list_t_overlaps_t if t1 in tuple(t_overlap...))
                if t_list == nothing
                    result
                else
                    [t for t in result if t in tuple(t_list...)]
                end
            end
            """
                t_overlaps_t(t_list1, t_list2, t_list=nothing)

            Return a list of time slices which are in `t_list1` and have some time in common
            with any of the time slices in `t_list2` and vice versa.
            If `t_list` is specified, only return time slices that appear in `t_list`.
            """
            function t_overlaps_t(
                    t_list1::Union{TimeSlice,Array{TimeSlice,1}},
                    t_list2::Union{TimeSlice,Array{TimeSlice,1}},
                    t_list=nothing
                )
                orig_list = $list_t_overlaps_t
                overlap_list = [
                    (t1, t2) for (t1, t2) in orig_list if t1 in tuple(t_list1...) && t2 in tuple(t_list2...)
                ]
                result = vcat(first.(overlap_list), last.(overlap_list))
                unique!(result)
                if t_list == nothing
                    result
                else
                    [t for t in result if t in tuple(t_list...)]
                end
            end


            """
                t_overlaps_t_excl(;t_list=nothing)

            Return the list of tuples `(t1, t2)` where `t1` and `t2` have some time in common
            and `t1` is not equal to `t2`.
            If `t_list` is specified, only returns tuples of time slices that appear in `t_list`.
            """
            function t_overlaps_t_excl(;t_list=nothing)
                result = $list_t_overlaps_t_excl
                if t_list == nothing
                    result
                else
                    [(t1, t2) for (t1, t2) in result if t1 in tuple(t_list...) && t2 in tuple(t_list...)]
                end
            end
            """
                t_overlaps_t_excl(t_overlap::Union{TimeSlice,Array{TimeSlice,1}}; t_list=nothing)

            Return the list of time slices that have some time in common with `t_overlap`
            (or some time in common with any element in `t_overlap` if it's a list) and `t1` is not equal to `t2`.
            If `t_list` is specified, only returns time slices that appear in `t_list`.
             ```
            """
            function t_overlaps_t_excl(t_overlap::Union{TimeSlice,Array{TimeSlice,1}}; t_list=nothing)
                result = unique(t2 for (t1, t2) in $list_t_overlaps_t_excl if t1 in tuple(t_overlap...))
                if t_list == nothing
                    result
                else
                    [t for t in result if t in tuple(t_list...)]
                end
            end
            """
                t_overlaps_t_excl(t_list1, t_list2, t_list=nothing)

            Return a list of time slices which are in `t_list1` and have some time in common
            with any of the time slices in `t_list2` (unless they are the same time slice) and vice versa.
            If `t_list` is specified, only returns time slices that appear in `t_list`.
            """
            function t_overlaps_t_excl(
                    t_list1::Union{TimeSlice,Array{TimeSlice,1}},
                    t_list2::Union{TimeSlice,Array{TimeSlice,1}},
                    t_list=nothing
                )
                orig_list = $list_t_overlaps_t_excl
                overlap_list = [
                    (t1, t2) for (t1, t2) in orig_list if t1 in tuple(t_list1...) && t2 in tuple(t_list2...)
                ]
                result = vcat(first.(overlap_list), last.(overlap_list))
                unique!(result)
                if t_list == nothing
                    result
                else
                    [t for t in result if t in tuple(t_list...)]
                end
            end

            """
                t_lowest_resolution(t_list::Union{TimeSlice,Array{TimeSlice,1}})

            Return the list of the lowest resolution time slices within `t_list`
            (those that aren't contained in any other).
            """
            function t_lowest_resolution(t_list::Array{TimeSlice,1})
                # [t for t in t_list if isempty(t_in_t_excl(t_short=t, t_list=t_list))] # Nice, but ~20 times slower
                sort!(t_list)
                result::Array{TimeSlice,1} = [t_list[1]]
                for t in t_list[2:end]
                    if result[end] in t
                        result[end] = t
                    elseif !(t in result[end])
                        push!(result, t)
                    end
                end
                result
            end


            """
                t_highest_resolution(t_list::Union{TimeSlice,Array{TimeSlice,1}})

            Return the list of the highest resolution time slices from `t_list`
            (those that don't contain any other).
            """
            function t_highest_resolution(t_list::Array{TimeSlice,1})
                # [t for t in t_list if isempty(t_in_t_excl(t_long=t, t_list=t_list))] # Nice, but ~20 times slower
                sort!(t_list)
                result::Array{TimeSlice,1} = [t_list[1]]
                for t in t_list[2:end]
                    result[end] in t || push!(result, t)
                end
                result
            # sort!(t_list)  # e.g.: [(1, 2), (1, 3), (1, 4), (2, 4), (5, 6), (5, 7), ...]
            # result = []
            # i = 1
            # push!(result,t_list[i])
            # while i < length(t_list)
            #     if i != length(t_list) && t_list[i].start == t_list[i + 1].start
            #         # Keep going, we haven't reached lowest res
            #         i += 1
            #     else
            #         # Lowest res reached: either we're at the end, or the next item has a different start
            #         push!(result, t_list[i+1])
            #         # Advance i to the beginning of the next 'section'
            #         i += 1
            #     end
            # end
            # unique(result)
            end

            export t_before_t
            export t_in_t
            export t_in_t_excl
            export t_overlaps_t
            export t_overlaps_t_excl
            export t_lowest_resolution
            export t_highest_resolution
        end
    end
end
#@Maren: can we add the t_overlaps_t
