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

struct TOverlapsTRelationshipClass
    list::Array{Tuple{TimeSlice,TimeSlice},1}
end

struct TOverlapsTExclRelationshipClass
    list::Array{Tuple{TimeSlice,TimeSlice},1}
end

"""
    t_overlaps_t()

Return the list of tuples `(t1, t2)` where `t1` and `t2` have some time in common.
"""
function (t_overlaps_t::TOverlapsTRelationshipClass)()
    t_overlaps_t.list
end

"""
    t_overlaps_t(t_overlap)

Return the list of time slices that have some time in common with `t_overlap`
(or some time in common with any element in `t_overlap` if it's a list).
"""
function (t_overlaps_t::TOverlapsTRelationshipClass)(t_overlap)
    unique(t2 for (t1, t2) in t_overlaps_t.list if t1 in tuple(t_overlap...))
end

"""
    t_overlaps_t(t_list1, t_list2)

Return a list of time slices which are in `t_list1` and have some time in common
with any of the time slices in `t_list2` and vice versa.
"""
function (t_overlaps_t::TOverlapsTRelationshipClass)(t_list1, t_list2)
    orig_list = t_overlaps_t.list
    overlap_list = [
        (t1, t2) for (t1, t2) in orig_list if t1 in tuple(t_list1...) && t2 in tuple(t_list2...)
    ]
    unique(vcat(first.(overlap_list), last.(overlap_list)))
end

"""
    t_overlaps_t_excl()

Return the list of tuples `(t1, t2)` where `t1` and `t2` have some time in common
and `t1` is not equal to `t2`.
"""
function (t_overlaps_t_excl::TOverlapsTExclRelationshipClass)()
    t_overlaps_t_excl.list
end


"""
    t_overlaps_t_excl(t_overlap)

Return the list of time slices that have some time in common with `t_overlap`
(or some time in common with any element in `t_overlap` if it's a list) and `t1` is not equal to `t2`.
"""
function (t_overlaps_t_excl::TOverlapsTExclRelationshipClass)(t_overlap)
    unique(t2 for (t1, t2) in t_overlaps_t_excl.list if t1 in tuple(t_overlap...))
end
"""
    t_overlaps_t_excl(t_list1, t_list2)

Return a list of time slices which are in `t_list1` and have some time in common
with any of the time slices in `t_list2` (unless they are the same time slice) and vice versa.
"""
function (t_overlaps_t_excl::TOverlapsTExclRelationshipClass)(t_list1, t_list2)
    orig_list = t_overlaps_t_excl.list
    overlap_list = [
        (t1, t2) for (t1, t2) in orig_list if t1 in tuple(t_list1...) && t2 in tuple(t_list2...)
    ]
    unique(vcat(first.(overlap_list), last.(overlap_list)))
end

"""
    generate_time_slice_relationships()

Create and export convenience functions to access time slice relationships:
`t_in_t`, `t_preceeds_t`, `t_overlaps_t`...
"""
function generate_time_slice_relationships()
    t_before_t_list = []
    t_in_t_list = []
    t_overlaps_t_list = []
    time_slice_list = time_slice()
    sort!(time_slice_list)
    # NOTE: splitting the loop into two loops as below makes it ~2 times faster
    for (i, t_i) in enumerate(time_slice_list)
        found = false
        for t_j in time_slice_list[i:end]
            if before(t_i, t_j)
                found = true
                push!(t_before_t_list, tuple(t_i, t_j))
            elseif found
                break
            end
        end
    end
    for t_i in time_slice_list
        found_in = false
        break_in = false
        found_overlaps = false
        break_overlaps = false
        for t_j in time_slice_list
            if iscontained(t_i, t_j)
                found_in = true
                push!(t_in_t_list, tuple(t_i, t_j))
            elseif found_in
                break_in = true
            end
            if overlaps(t_i, t_j)
                found_overlaps = true
                push!(t_overlaps_t_list, tuple(t_i, t_j))
            elseif found_overlaps
                break_overlaps = true
            end
            if break_in && break_overlaps
                break
            end
        end
    end
    unique!(t_in_t_list)
    unique!(t_overlaps_t_list)
    t_in_t_excl_list = [(t1, t2) for (t1, t2) in t_in_t_list if t1 != t2]
    t_overlaps_t_excl_list = [(t1, t2) for (t1, t2) in t_overlaps_t_list if t1 != t2]
    # Create function-like objects
    t_before_t = RelationshipClass(
        :t_before_t,
        NamedTuple(),
        (:t_before, :t_after),
        [(NamedTuple{(:t_before, :t_after)}(x), NamedTuple()) for x in t_before_t_list]
    )
    t_in_t = RelationshipClass(
        :t_in_t,
        NamedTuple(),
        (:t_short, :t_long),
        [(NamedTuple{(:t_short, :t_long)}(x), NamedTuple()) for x in t_in_t_list]
    )
    t_in_t_excl = RelationshipClass(
        :t_in_t_excl,
        NamedTuple(),
        (:t_short, :t_long),
        [(NamedTuple{(:t_short, :t_long)}(x), NamedTuple()) for x in t_in_t_excl_list]
    )
    t_overlaps_t = TOverlapsTRelationshipClass(t_overlaps_t_list)
    t_overlaps_t_excl = TOverlapsTExclRelationshipClass(t_overlaps_t_excl_list)
    # Export the function-like objects
    @eval begin
        t_before_t = $t_before_t
        t_in_t = $t_in_t
        t_in_t_excl = $t_in_t_excl
        t_overlaps_t = $t_overlaps_t
        t_overlaps_t_excl = $t_overlaps_t_excl
        export t_before_t
        export t_in_t
        export t_in_t_excl
        export t_overlaps_t
        export t_overlaps_t_excl
    end
end
