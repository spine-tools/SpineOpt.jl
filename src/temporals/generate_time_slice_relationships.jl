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
    list_t_succeeds_t = []
    list_t_in_t = []
    list_t_in_t_excl = []
    list_t_overlaps_t = []
    list_t_overlaps_t_excl = []
    top_list = []
    for i in time_slice()
        for j in time_slice()
            if before(i, j)
                push!(list_t_succeeds_t, tuple(i, j))
            end
            if in(j, i)
                push!(list_t_in_t, tuple(i, j))
                if i != j
                    push!(list_t_in_t_excl, tuple(i, j))
                end
            end
            if overlaps(i, j)
                push!(list_t_overlaps_t, tuple(i, j))
                if i != j
                    push!(list_t_overlaps_t_excl, tuple(i, j))
                end
            end
        end
    end
    # TODO: instead of unique -> check beforehand whether timeslice tuple is already added
    # Is `unique!()` slow? I fear the above check can be a bit slow.
    # An alternative is to use `Set()` instead of `[]` to warranty uniqueness,
    # but then we lose the order - do we care about order?
    unique!(list_t_in_t)
    unique!(list_t_in_t_excl)
    unique!(list_t_overlaps_t)
    unique!(list_t_overlaps_t_excl)

    @suppress_err begin
        functionname_t_succeeds_t = "t_succeeds_t"
        functionname_t_in_t = "t_in_t"
        functionname_t_in_t_excl = "t_in_t_excl"
        functionname_t_overlaps_t = "t_overlaps_t"
        functionname_t_overlaps_t_excl = "t_overlaps_t_excl"
        functionname_t_top_level = "t_top_level"

        @eval begin
            """
                $($functionname_t_succeeds_t)(;t_before=nothing, t_after=nothing)

            Return the list of tuples `(t1, t2)` where `t2` *succeeds* `t1` in the sense that it
            starts right after `t1` ends, i.e. `t2.start == t1.end_`.
            If `t_before` is not `nothing`, return the list of time slices that succeed `t_before`
            (or any element in `t_before` if it's a list).
            If `t_after` is not `nothing`, return the list of time slices that are succeeded by `t_after`
            (or any element in `t_after` if it's a list).
            Only one of `t_before` and `t_after` can be not `nothing` at a time.
            """
            function $(Symbol(functionname_t_succeeds_t))(;t_before=nothing, t_after=nothing)
                if t_before == t_after == nothing
                    $list_t_succeeds_t
                elseif t_before != nothing && t_after == nothing
                    unique!([t2 for (t1, t2) in $list_t_succeeds_t if t1 in t_before])
                elseif t_before == nothing && t_after != nothing
                    unique!([t1 for (t1, t2) in $list_t_succeeds_t if t2 in t_after])
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
                    unique!([t2 for (t1, t2) in $list_t_in_t if t1 in t_long])
                elseif t_long == nothing && t_short != nothing
                    unique!([t1 for (t1, t2) in $list_t_in_t if t2 in t_short])
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
            function $(Symbol(functionname_t_in_t_excl))(;t_long=nothing, t_short=nothing)
                if t_long == t_short == nothing
                    $list_t_in_t_excl
                elseif t_long != nothing && t_short == nothing
                    unique!([t2 for (t1, t2) in $list_t_in_t_excl if t1 in t_long])
                elseif t_long == nothing && t_short != nothing
                    unique!([t1 for (t1, t2) in $list_t_in_t_excl if t2 in t_short])
                else
                    error("please specify just one of t_long and t_short")
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

            Return the list of time slices that have some time in common with `t_overlap`.
             ```
            """
            function $(Symbol(functionname_t_overlaps_t))(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})
                unique!([t2 for (t1, t2) in $list_t_overlaps_t if t1 in t_overlap])
            end
            """
                $($functionname_t_overlaps_t)(t_overlap1::Union{TimeSlice,Array{TimeSlice,1}}, t_overlap2::Union{TimeSlice,Array{TimeSlice,1}})

            Return the lisf of time slices in `t_overlap1` and `t_overlap2`.
            """
            function $(Symbol(functionname_t_overlaps_t))(
                    t_overlap1::Union{TimeSlice,Array{TimeSlice,1}},
                    t_overlap2::Union{TimeSlice,Array{TimeSlice,1}}
                )
                overlap_list = [(t1, t2) for (t1, t2) in $list_t_overlaps_t if t1 in t_overlap1 && t2 in t_overlap2]
                t_list = vcat(first.(overlap_list),last.(overlap_list))
                unique!(t_list)
            end

            """
                $($functionname_t_overlaps_t_excl)'()

            Return the list of tuples `(t1, t2)` where `t1` and `t2` are different and have some time in common.
             ```
            """
            function $(Symbol(functionname_t_overlaps_t_excl))()
                $list_t_overlaps_t_excl
            end

            """
                $($functionname_t_overlaps_t_excl)'(t_overlap)

            Return the list of time slices that have some time in common with `t_overlap` excluding `t_overlap` itself.
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})
                unique!([t2 for (t1, t2) in $list_t_overlaps_t_excl if t1 in t_overlap])
            end

            """
                $($functionname_t_overlaps_t_excl)'(t_overlap1, t_overlap2)

            The tuples of the list '$($functionname_t_overlaps_t_excl)'. See '$($functionname_t_overlaps_t)'.
            Difference: Excludes the timeslice itself
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(
                    t_overlap1::Union{TimeSlice,Array{TimeSlice,1}},
                    t_overlap2::Union{TimeSlice,Array{TimeSlice,1}})
                overlap_list = [(t1, t2) for (t1, t2) in $list_t_overlaps_t_excl if t1 in t_overlap1 && t2 in t_overlap2]
                t_list = vcat(first.(overlap_list), last.(overlap_list))
                unique!(t_list)
            end

            """
                $($functionname_t_top_level)'(t_list::Union{TimeSlice,Array{TimeSlice,1}})

            For a set of overlapping timeslices, the top most timeslices are returned.

            # Examples
            ```julia
            julia> t_top_level(time_slice())
            3-element Array{Any,1}:
             (start: 2018-02-22T10:30:00, end: 2018-02-22T11:30:00) (JuMP_name: tb2__t1)
             (start: 2018-02-22T11:30:00, end: 2018-02-22T12:30:00) (JuMP_name: tb2__t2)
             (start: 2018-02-22T12:30:00, end: 2018-02-22T13:30:00) (JuMP_name: tb2__t3)
             ```
            """
            function $(Symbol(functionname_t_top_level))(t_list::Union{TimeSlice,Array{TimeSlice,1}})
                t_list isa Array || (t_list = [t_list])
                    sort!(t_list)
                    i=1
                    j=1
                    while i < length(t_list)
                        while j <= length(t_list) && (t_list[i].start == t_list[j].start || t_list[i].end_ >= t_list[j].end_) ##NOTE: sufficient?
                            if t_list[i].end_ < t_list[j].end_
                                i = j
                                j +=1
                            else #go to next [j]
                                j += 1
                            end
                        end
                        push!($top_list, t_list[i])
                        i = j
                    end
                    unique!($top_list)
                    $top_list
            end
            export $(Symbol(functionname_t_succeeds_t))
            export $(Symbol(functionname_t_in_t))
            export $(Symbol(functionname_t_in_t_excl))
            export $(Symbol(functionname_t_overlaps_t))
            export $(Symbol(functionname_t_overlaps_t_excl))
            export $(Symbol(functionname_t_top_level))
        end
    end
end

#@Maren: can we add the t_overlaps_t
