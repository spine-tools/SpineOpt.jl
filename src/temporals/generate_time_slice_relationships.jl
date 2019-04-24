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
            if suceeds(j, i)
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
        functionname_t_before_t = "t_before_t"
        functionname_t_in_t = "t_in_t"
        functionname_t_in_t_excl = "t_in_t_excl"
        functionname_t_overlaps_t = "t_overlaps_t"
        functionname_t_overlaps_t_excl = "t_overlaps_t_excl"
        functionname_t_lowest_resolution = "t_lowest_resolution"
        functionname_t_highest_resolution = "t_highest_resolution"

        @eval begin
            """
                $($functionname_t_before_t)(;t_before=nothing, t_after=nothing)

            Return the list of tuples `(t1, t2)` where `t2` *succeeds* `t1` in the sense that it
            starts right after `t1` ends, i.e. `t2.start == t1.end_`.
            If `t_before` is not `nothing`, return the list of time slices that succeed `t_before`
            (or any element in `t_before` if it's a list).
            If `t_after` is not `nothing`, return the list of time slices that are succeeded by `t_after`
            (or any element in `t_after` if it's a list).
            Only one of `t_before` and `t_after` can be not `nothing` at a time.
            """
            function $(Symbol(functionname_t_before_t))(;t_before=nothing, t_after=nothing)
                if t_before == t_after == nothing
                    $list_t_before_t
                elseif t_before != nothing && t_after == nothing
                    unique(t2 for (t1, t2) in $list_t_before_t if t1 in tuple(t_before...))
                elseif t_before == nothing && t_after != nothing
                    unique(t1 for (t1, t2) in $list_t_before_t if t2 in tuple(t_after...))
                else
                    error("please specify just one of `t_before` and `t_after`")
                end
            end
            """
                $($functionname_t_in_t)(;t_long=nothing, t_short=nothing)

            Return the list of tuples `(t1, t2)`, where `t2` is contained in `t1`.
            If `t_long` is not `nothing`, return the list of time slices contained in `t_long`
            (or any element in `t_long` if it's a list).
            If `t_short` is not `nothing`, return the list of time slices that contain `t_short`
            (or any element in `t_short` if it's a list).
            Only one of `t_long` and `t_short` can be not `nothing` at a time.
            """
            function $(Symbol(functionname_t_in_t))(;t_long=nothing, t_short=nothing)
                if t_long == t_short == nothing
                    $list_t_in_t
                elseif t_long != nothing && t_short == nothing
                    unique(t1 for (t1, t2) in $list_t_in_t if t2 in tuple(t_long...))
                elseif t_long == nothing && t_short != nothing
                    unique(t2 for (t1, t2) in $list_t_in_t if t1 in tuple(t_short...))
                elseif t_long != nothing && t_short != nothing
                    unique(t2 for (t1, t2) in $list_t_in_t if t1 in tuple(t_short...) && t2 in tuple(t_long...))
                else
                    error("please specify just one of `t_long` and `t_short`")
                end
            end
            """
                $($functionname_t_in_t_excl)(;t_long=nothing, t_short=nothing)

            Return the list of tuples `(t1, t2)`, where `t1` contains `t2` and `t1` is different from `t2`.
            See [`$($functionname_t_in_t)(;t_long=nothing, t_short=nothing)`](@ref)
            for details about keyword arguments `t_long` and `t_short`.
            """
            function $(Symbol(functionname_t_in_t_excl))(;t_long=nothing, t_short=nothing, t_list=nothing)
                if t_long == t_short == nothing
                    if t_list == nothing
                        $list_t_in_t_excl
                    else
                        ((t1,t2) for (t1,t2) in $list_t_in_t_excl if t1 in tuple(t_list...) && t2 in tuple(t_list...))
                    end
                elseif t_long != nothing && t_short == nothing
                    if t_list == nothing
                        unique(t1 for (t1, t2) in $list_t_in_t_excl if t2 in tuple(t_long...))
                    else
                        unique(t1 for (t1, t2) in $list_t_in_t_excl if t2 in tuple(t_long...) && t1 in tuple(t_list...))
                    end
                elseif t_long == nothing && t_short != nothing
                    if t_list == nothing
                        unique(t2 for (t1, t2) in $list_t_in_t_excl if t1 in tuple(t_short...))
                    else
                        unique(t2 for (t1, t2) in $list_t_in_t_excl if t1 in tuple(t_short...) && t2 in tuple(t_list...))
                    end
                elseif t_long != nothing && t_short != nothing
                    if t_list == nothing
                        unique((t1,t2) for (t1, t2) in $list_t_in_t_excl if t1 in tuple(t_short...) && t2 in tuple(t_long...))
                    else
                        unique((t1,t2) for (t1, t2) in $list_t_in_t_excl if t1 in tuple(t_short...) && t2 in tuple(t_long...) && t1 in tuple(t_list...) && t2 in tuple(t_list...))
                    end
                else
                    error("invalid arguments")
                end
            end
            """
                $($functionname_t_overlaps_t)()

            Return the list of tuples `(t1, t2)` where `t1` and `t2` have some time in common.
            """
            function $(Symbol(functionname_t_overlaps_t))()
                $list_t_overlaps_t
            end
            """
                $($functionname_t_overlaps_t)(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})

            Return the list of time slices that have some time in common with `t_overlap`
            (or any element in `t_overlap` if it's a list).
             ```
            """
            function $(Symbol(functionname_t_overlaps_t))(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})
                unique(t2 for (t1, t2) in $list_t_overlaps_t if t1 in tuple(t_overlap...))
            end
            """
                $($functionname_t_overlaps_t)(t_list1::Union{TimeSlice,Array{TimeSlice,1}}, t_list2::Union{TimeSlice,Array{TimeSlice,1}})

            Return a single lisf including all time slices from `t_list1` that overlap with any time slice in `t_list2`,
            and all time slices from `t_list2` that overlap with any time slice in `t_list1`.
            """
            function $(Symbol(functionname_t_overlaps_t))(
                    t_list1::Union{TimeSlice,Array{TimeSlice,1}},
                    t_list2::Union{TimeSlice,Array{TimeSlice,1}}
                )
                overlap_list = [
                    (t1, t2) for (t1, t2) in $list_t_overlaps_t if t1 in tuple(t_list1...) && t2 in tuple(t_list2...)
                ]
                t_list = vcat(first.(overlap_list), last.(overlap_list))
                unique(t_list)
            end

            """
                $($functionname_t_overlaps_t_excl)()

            Return the list of tuples `(t1, t2)` where `t1` and `t2` are different and have some time in common.
             ```
            """
            function $(Symbol(functionname_t_overlaps_t_excl))()
                $list_t_overlaps_t_excl
            end

            """
                $($functionname_t_overlaps_t_excl)(t_overlap)

            Return the list of time slices that have some time in common with `t_overlap` excluding `t_overlap` itself.
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})
                unique(t2 for (t1, t2) in $list_t_overlaps_t_excl if t1 in tuple(t_overlap...))
            end

            """
                $($functionname_t_overlaps_t_excl)(t_list1, t_list2)

            Return a single list including all time slices from `t_list1` that overlap with
            (but are different from) any time slice in `t_list2`,
            and all time slices from `t_list2` that overlap with
            (but are different from) any time slice in `t_list1`.
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(
                    t_list1::Union{TimeSlice,Array{TimeSlice,1}},
                    t_list2::Union{TimeSlice,Array{TimeSlice,1}})
                overlap_list = [
                    (t1, t2)
                    for (t1, t2) in $list_t_overlaps_t_excl if t1 in tuple(t_list1...) && t2 in tuple(t_list2...)
                ]
                t_list = vcat(first.(overlap_list), last.(overlap_list))
                unique(t_list)
            end

            """
                $($functionname_t_lowest_resolution)(t_list::Union{TimeSlice,Array{TimeSlice,1}})

            Return the list of the highest resolution time slices within `t_list` (those that aren't contained in any other).
            """
            function $(Symbol(functionname_t_lowest_resolution))(t_list::Array{TimeSlice,1})
                # [t for t in t_list if isempty(t_in_t_excl(t_short=t, t_list = t_list))]
                # More verbose older version:
                # NOTE: the older version is about 10 times faster!
                # # NOTE: sorting enables looking for top-level items by comparing the start of succesive items
                sort!(t_list)  # e.g.: [(1, 2), (1, 3), (1, 4), (2, 4), (5, 6), (5, 7), ...]
                top_list = []
                i = 1
                while i <= length(t_list)
                    if i != length(t_list) && t_list[i].start == t_list[i + 1].start
                        # Keep going, we haven't reached top-level
                        i += 1
                    else
                        # Top-level reached: either we're at the end, or the next item has a different start
                        push!(top_list, t_list[i])
                        # Advance i to the beginning of the next 'section'
                        end_ = t_list[i].end_  # This marks the end of the current section
                        i += 1
                        while i <= length(t_list) && t_list[i].start < end_
                            i += 1
                        end
                    end
                end
                unique(top_list)
            end


            """
                $($functionname_t_highest_resolution)(t_list::Union{TimeSlice,Array{TimeSlice,1}})

            Return the list of the highest resolution time slices from `t_list` (those that don't contain any other).
            """
            function $(Symbol(functionname_t_highest_resolution))(t_list::Array{TimeSlice,1})
                [t for t in t_list if isempty(t_in_t_excl(t_long=t, t_list = t_list))]
            end

            export $(Symbol(functionname_t_before_t))
            export $(Symbol(functionname_t_in_t))
            export $(Symbol(functionname_t_in_t_excl))
            export $(Symbol(functionname_t_overlaps_t))
            export $(Symbol(functionname_t_overlaps_t_excl))
            export $(Symbol(functionname_t_lowest_resolution))
            export $(Symbol(functionname_t_highest_resolution))
        end
    end
end

#@Maren: can we add the t_overlaps_t
