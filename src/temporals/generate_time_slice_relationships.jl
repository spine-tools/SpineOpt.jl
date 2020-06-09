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

struct TOverlapsT
    list::Array{Tuple{TimeSlice,TimeSlice},1}
end

"""
    t_overlaps_t()

A list of tuples `(t1, t2)` where `t1` and `t2` have some time in common.
"""
function (h::TOverlapsT)()
    h.list
end

"""
    t_overlaps_t(t_overlap)

A list of time slices that have some time in common with `t_overlap`
(or some time in common with any element in `t_overlap` if it's a list).
"""
function (h::TOverlapsT)(t_overlap)
    unique(t2 for (t1, t2) in h.list if t1 in tuple(t_overlap...))
end

"""
    t_overlaps_t(t1, t2)

A list of time slices which are in `t1` and have some time in common
with any of the time slices in `t2` and vice versa.
"""
function (h::TOverlapsT)(t1, t2)
    unique(Iterators.flatten(filter(t -> t[1] in tuple(t1...) && t[2] in tuple(t2...), h.list)))
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
    # NOTE: splitting the loop into two loops as below makes it ~2 times faster
    for (i, t_i) in enumerate(all_time_slices)
        found = false
        for t_j in all_time_slices[i:end]
            if before(t_i, t_j)
                found = true
                push!(t_before_t_list, (t_before=t_i, t_after=t_j))
            elseif found
                break
            end
        end
    end
    for t_i in all_time_slices
        found_in = false
        break_in = false
        found_overlaps = false
        break_overlaps = false
        for t_j in all_time_slices
            if iscontained(t_i, t_j)
                found_in = true
                push!(t_in_t_list, (t_short=t_i, t_long=t_j))
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
#                break
            end
        end
    end
    unique!(t_in_t_list)
    unique!(t_overlaps_t_list)
    t_in_t_excl_list = [(t_short=t1, t_long=t2) for (t1, t2) in t_in_t_list if t1 != t2]
    t_overlaps_t_excl_list = [(t1, t2) for (t1, t2) in t_overlaps_t_list if t1 != t2]
    # Create function-like objects
    t_before_t = RelationshipClass(:t_before_t, [:t_before, :t_after], t_before_t_list)
    t_in_t = RelationshipClass(:t_in_t, [:t_short, :t_long], t_in_t_list)
    t_in_t_excl = RelationshipClass(:t_in_t_excl, [:t_short, :t_long], t_in_t_excl_list)
    t_overlaps_t = TOverlapsT(t_overlaps_t_list)
    t_overlaps_t_excl = TOverlapsT(t_overlaps_t_excl_list)
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
