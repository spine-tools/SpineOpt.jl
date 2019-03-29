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
function generate_time_slice_relationships(time_slicemap_detail)
    @butcher list_t_before_t = []
    list_t_in_t = []
    list_t_in_t_excl = []
    for i in time_slicemap_detail()
        for j in time_slicemap_detail()
            if i[3] == j[2]
                list_t_before_t = push!(list_t_before_t,Tuple([i[1], j[1]]))
            end
            if j[2] >= i[2] && j[3] <= i[3]
                list_t_in_t = push!(list_t_in_t,Tuple([i[1], j[1]]))
                    if i[1] != j[1]
                        list_t_in_t_excl = push!(list_t_in_t_excl,Tuple([i[1], j[1]]))
                    end
            end
        end
    end

    function t_before_t(;kwargs...)
        if length(kwargs) == 0
            list_t_before_t
        elseif length(kwargs) == 1
            key, value = iterate(kwargs)[1]
            if key == :t_before
                t_after_tuple = filter(x -> x[1]== value , list_t_before_t)
                t_after = last.(t_after_tuple)
            elseif key == :t_after
                t_before_tuple = filter(x -> x[2]== value , list_t_before_t)
                t_before = first.(t_before_tuple)
            end
        end
    end

    function t_in_t(;kwargs...)
        if length(kwargs) == 0
            list_t_in_t
        elseif length(kwargs) == 1
            key, value = iterate(kwargs)[1]
            if key == :t_long
                t_short_tuple = filter(x -> x[1]== value , list_t_in_t)
                t_short = last.(t_short_tuple)
                t_short
            elseif key == :t_short
                t_long_tuple = filter(x -> x[2]== value , list_t_in_t)
                t_long = first.(t_long_tuple)
                t_long
            end
        end
    end

    function t_in_t_excl(;kwargs...)
        if length(kwargs) == 0
            list_t_in_t_excl
        elseif length(kwargs) == 1
            key, value = iterate(kwargs)[1]
            if key == :t_long
                t_short_tuple = filter(x -> x[1]== value , list_t_in_t_excl)
                t_short = last.(t_short_tuple)
                t_short
            elseif key == :t_short
                t_long_tuple = filter(x -> x[2]== value , list_t_in_t_excl)
                t_long = first.(t_long_tuple)
                t_long
            end
        end
    end
    t_before_t,t_in_t,t_in_t_excl
end

#@Maren: can we add the t_overlaps_t
