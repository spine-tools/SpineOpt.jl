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
##TODO:
# have an eye on where unique! is necessary for speedup

"""
    generate_time_slice_relationships(detailed_timeslicemap)

A tuple returned for a specific timeslice t', returning all timeslices t'' directly before t'.
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

            The tuples of the list '$($functionname_t_succeeds_t)'. Return all time_slices which coincide in there start-
            and enddate, respectively.
            The argument `t_before` or `t_after` can be used, e.g., to return the corresponding timeslices which
            are directly after or before, respective to the entered timeslice

            # Examples
            ```julia
            julia> t_succeeds_t(t_before = Symbol("2018-02-23T09:00:00__2018-02-23T09:30:00"))
            1-element Array{Symbol,1}:
             Symbol("2018-02-23T09:30:00__2018-02-23T10:00:00")
             ```
            """
            function $(Symbol(functionname_t_succeeds_t))(;t_before=nothing, t_after=nothing)
                if t_before == t_after == nothing
                    $list_t_succeeds_t
                elseif t_before != nothing && t_after == nothing
                    unique!([t2 for (t1, t2) in $list_t_succeeds_t if t1 in t_before])
                elseif t_before == nothing && t_after != nothing
                    unique!([t1 for (t1, t2) in $list_t_succeeds_t if t2 in t_after])
                else
                    error("please specify just one of t_before and t_after")
                end
            end
            """
                $($functionname_t_in_t)(;t_long=nothing, t_short=nothing)

            The tuples of the list '$($functionname_t_in_t)'. Return all time_slices which are either fully
            above or fully within another timeslice.
            The argument `t_long` or `t_short` can be used, e.g., to return the corresponding timeslices which
            are directly below or above, respective to the entered timeslice

            # Examples
            ```julia
            julia> t_in_t(t_short=Symbol("2018-02-22T11:00:00__2018-02-22T11:30:00"))
            3-element Array{Symbol,1}:
             Symbol("2018-02-22T11:00:00__2018-02-22T11:30:00")
             Symbol("2018-02-22T10:30:00__2018-02-22T13:30:00")
             Symbol("2018-02-22T10:30:00__2018-02-23T10:30:00")
             ```
            """
            function $(Symbol(functionname_t_in_t))(;t_long=nothing, t_short=nothing)
                if t_long == t_short == nothing
                    $list_t_in_t
                elseif t_long != nothing && t_short == nothing
                    unique!([t2 for (t1, t2) in $list_t_in_t if t1 in t_long])
                elseif t_long == nothing && t_short != nothing
                    unique!([t1 for (t1, t2) in $list_t_in_t if t2 in t_short])
                else
                    error("please specify just one of t_long and t_short")
                end
            end
            """
                $($functionname_t_in_t_excl)(;t_long=nothing, t_short=nothing)

            The tuples of the list '$($functionname_t_in_t_excl)'. See '$($functionname_t_in_t)'.
            Difference: Excludes the timeslice itself

            # Examples
            ```julia
            julia> t_in_t_excl(t_short=Symbol("2018-02-22T11:00:00__2018-02-22T11:30:00"))
            2-element Array{Symbol,1}:
             Symbol("2018-02-22T10:30:00__2018-02-22T13:30:00")
             Symbol("2018-02-22T10:30:00__2018-02-23T10:30:00")
             ```
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

            Tuples of the list '$($functionname_t_overlaps_t). Return all timeslice tuples, which
            have some time in common.
            The argument `t_overlap` can be used, e.g., to return the corresponding timeslices which
            are overlapping the entered timeslice.

            # Examples
            ```julia
            julia> t_overlaps_t()
            21-element Array{Any,1}:
             (2018-02-22T10:30:00...2018-02-22T11:00:00 (tb1__t1), 2018-02-22T10:30:00...2018-02-22T11:00:00 (tb1__t1))
             (2018-02-22T10:30:00...2018-02-22T11:00:00 (tb1__t1), 2018-02-22T10:30:00...2018-02-22T11:30:00 (tb2__t1))
             (2018-02-22T11:00:00...2018-02-22T11:30:00 (tb1__t2), 2018-02-22T11:00:00...2018-02-22T11:30:00 (tb1__t2))
             ....
             ```
            """
            function $(Symbol(functionname_t_overlaps_t))()
                    $list_t_overlaps_t
            end
            """
                $($functionname_t_overlaps_t)(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})

            Tuples of the list '$($functionname_t_overlaps_t). Return all timeslice tuples, which
            have some time in common.
            The argument can be used, e.g., to return the corresponding timeslices which
            are overlapping the entered timeslice(s).

            # Examples
            ```julia
            julia> t_overlaps_t(time_slice()[1])
            2-element Array{SpineModel.TimeSlice,1}:
             2018-02-22T10:30:00...2018-02-22T11:00:00 (tb1__t1)
             2018-02-22T10:30:00...2018-02-22T11:30:00 (tb2__t1)
             ```
            """
            function $(Symbol(functionname_t_overlaps_t))(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})
                    t_overlap isa Array || (t_overlap = [t_overlap])
                    unique!([t2 for (t1, t2) in $list_t_overlaps_t if t1 in t_overlap])
            end
            """
                $($functionname_t_overlaps_t)(t_overlap1::Union{TimeSlice,Array{TimeSlice,1}}, t_overlap2::Union{TimeSlice,Array{TimeSlice,1}})

            Tuples of the list '$($functionname_t_overlaps_t). Return all timeslice tuples, which
            have some time in common.
            The arguments can be used, e.g., to return the corresponding timeslices which
            are overlapping from both lists of timeslices.

            # Examples
            ```julia
            julia> t_overlaps_t(time_slice()[1],time_slice()[7])
            2-element Array{SpineModel.TimeSlice,1}:
             2018-02-22T10:30:00...2018-02-22T11:00:00 (tb1__t1)
             2018-02-22T10:30:00...2018-02-22T11:30:00 (tb2__t1)
             ```
            """
            function $(Symbol(functionname_t_overlaps_t))(t_overlap1::Union{TimeSlice,Array{TimeSlice,1}}, t_overlap2::Union{TimeSlice,Array{TimeSlice,1}})
                    t_overlap1 isa Array || (t_overlap1 = [t_overlap1])
                    t_overlap2 isa Array || (t_overlap2 = [t_overlap2])
                    overlap_list = [(t1, t2) for (t1, t2) in $list_t_overlaps_t if t1 in t_overlap1 && t2 in t_overlap2]
                    t_list = vcat(first.(overlap_list),last.(overlap_list))
                    unique!(t_list)
            end

            """
                $($functionname_t_overlaps_t_excl)'(;t_overlap=nothing)

            The tuples of the list '$($functionname_t_overlaps_t_excl)'. See '$($functionname_t_overlaps_t)'.
            Difference: Excludes the timeslice itself

            # Examples
            ```julia
            julia> t_overlaps_t_excl(t_overlap=Symbol("2018-02-22T10:30:00__2018-02-22T11:00:00"))
            2-element Array{Symbol,1}:
             Symbol("2018-02-22T10:30:00__2018-02-22T13:30:00")
             Symbol("2018-02-22T10:30:00__2018-02-23T10:30:00")
             ```
            """
            function $(Symbol(functionname_t_overlaps_t_excl))()
                    $list_t_overlaps_t_excl
            end
            """
                $($functionname_t_overlaps_t_excl)'(;t_overlap=nothing)

            The tuples of the list '$($functionname_t_overlaps_t_excl)'. See '$($functionname_t_overlaps_t)'.
            Difference: Excludes the timeslice itself
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(t_overlap::Union{TimeSlice,Array{TimeSlice,1}})
                    t_overlap isa Array || (t_overlap = [t_overlap])
                    unique!([t2 for (t1, t2) in $list_t_overlaps_t_excl if t1 in t_overlap])
            end
            """
                $($functionname_t_overlaps_t_excl)'(;t_overlap=nothing)

            The tuples of the list '$($functionname_t_overlaps_t_excl)'. See '$($functionname_t_overlaps_t)'.
            Difference: Excludes the timeslice itself
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(t_overlap1::Union{TimeSlice,Array{TimeSlice,1}}, t_overlap2::Union{TimeSlice,Array{TimeSlice,1}})
                    t_overlap1 isa Array || (t_overlap1 = [t_overlap1])
                    t_overlap2 isa Array || (t_overlap2 = [t_overlap2])
                    overlap_list = [(t1, t2) for (t1, t2) in $list_t_overlaps_t_excl if t1 in t_overlap1 && t2 in t_overlap2]
                    t_list = vcat(first.(overlap_list),last.(overlap_list))
                    unique!(t_list)
            end



            """
                $($functionname_t_overlaps_t_excl)'(;t_overlap=nothing)

            The tuples of the list '$($functionname_t_overlaps_t_excl)'. See '$($functionname_t_overlaps_t)'.
            Difference: Excludes the timeslice itself
            """
            function $(Symbol(functionname_t_overlaps_t_excl))(;t_overlap=nothing)
                if t_overlap == nothing
                    $list_t_overlaps_t_excl
                else
                    unique!([t2 for (t1, t2) in $list_t_overlaps_t_excl if t1 in t_overlap])
                end
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
