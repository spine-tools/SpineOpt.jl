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
    generate_time_slice_relationships(detailed_timeslicemap)

A tuple returned for a specific timeslice t', returning all timeslices t'' directly before t'.
"""
function generate_time_slice_relationships()
    list_t_before_t = []
    list_t_in_t = []
    list_t_in_t_excl = []
    list_t_overlaps_t = []
    list_t_overlaps_t_excl = []
    for (i_symbol, i_start, i_end) in time_slice_detail()
        for (j_symbol, j_start, j_end) in time_slice_detail()
            if i_end == j_start
                list_t_before_t = push!(list_t_before_t, Tuple([i_symbol, j_symbol]))
            end
            if j_start >= i_start && j_end <= i_end
                list_t_in_t = push!(list_t_in_t, Tuple([i_symbol, j_symbol]))
                list_t_overlaps_t = push!(list_t_overlaps_t, Tuple([i_symbol, j_symbol]))
                list_t_overlaps_t = push!(list_t_overlaps_t, Tuple([j_symbol, i_symbol]))
                if i_symbol != j_symbol
                    list_t_in_t_excl = push!(list_t_in_t_excl, Tuple([i_symbol, j_symbol]))
                    list_t_overlaps_t_excl = push!(list_t_overlaps_t_excl, Tuple([i_symbol, j_symbol]))
                    list_t_overlaps_t_excl = push!(list_t_overlaps_t_excl, Tuple([j_symbol, i_symbol]))
                end
            end
            if j_start >= i_start && j_end >= i_end && j_start < i_end
                list_t_overlaps_t = push!(list_t_overlaps_t, Tuple([i_symbol, j_symbol]))
                list_t_overlaps_t = push!(list_t_overlaps_t, Tuple([j_symbol, i_symbol]))
                if i_symbol != j_symbol
                    list_t_overlaps_t_excl = push!(list_t_overlaps_t_excl, Tuple([i_symbol, j_symbol]))
                    list_t_overlaps_t_excl = push!(list_t_overlaps_t_excl, Tuple([j_symbol, i_symbol]))
                end
            end
        end
    end
    unique!(list_t_overlaps_t)

    @suppress_err begin
        @eval begin
            function $(Symbol("t_before_t"))(;t_before=nothing, t_after=nothing)
                if t_before == t_after == nothing
                    $list_t_before_t
                elseif t_before != nothing && t_after == nothing
                    [t2 for (t1, t2) in $list_t_before_t if t1 == t_before]
                elseif t_before == nothing && t_after != nothing
                    [t1 for (t1, t2) in $list_t_before_t if t2 == t_after]
                else
                    error("please specify just one of t_before and t_after")
                end
            end
            function $(Symbol("t_in_t"))(;t_long=nothing, t_short=nothing)
                if t_long == t_short == nothing
                    $list_t_in_t
                elseif t_long != nothing && t_short == nothing
                    [t2 for (t1, t2) in $list_t_in_t if t1 == t_long]
                elseif t_long == nothing && t_short != nothing
                    [t1 for (t1, t2) in $list_t_in_t if t2 == t_short]
                else
                    error("please specify just one of t_long and t_short")
                end
            end
            function $(Symbol("t_in_t_excl"))(;t_long=nothing, t_short=nothing)
                if t_long == t_short == nothing
                    $list_t_in_t_excl
                elseif t_long != nothing && t_short == nothing
                    [t2 for (t1, t2) in $list_t_in_t_excl if t1 == t_long]
                elseif t_long == nothing && t_short != nothing
                    [t1 for (t1, t2) in $list_t_in_t_excl if t2 == t_short]
                else
                    error("please specify just one of t_long and t_short")
                end
            end
            function $(Symbol("t_overlaps_t"))(;t_overlap=nothing)
                if t_overlap == nothing
                    $list_t_overlaps_t
                else
                    [t2 for (t1, t2) in $list_t_overlaps_t if t1 == t_overlap]
                end
            end
            function $(Symbol("t_overlaps_t_excl"))(;t_overlap=nothing)
                if t_overlap == nothing
                    $list_t_overlaps_t
                else
                    [t2 for (t1, t2) in $list_t_overlaps_t_excl if t1 == t_overlap]
                end
            end
            export $(Symbol("t_before_t"))
            export $(Symbol("t_in_t"))
            export $(Symbol("t_in_t_excl"))
            export $(Symbol("t_overlaps_t"))
            export $(Symbol("t_overlaps_t_excl"))
        end
    end
end

#@Maren: can we add the t_overlaps_t
