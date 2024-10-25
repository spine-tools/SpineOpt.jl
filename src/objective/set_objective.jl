#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
    set_objective!(m::Model)

Minimize the total discounted costs, corresponding to the sum over all
cost terms.

Unless defined otherwise this expression executed until the last time_slice
"""
# TODO: Rethink this concept; Should we really evaluate until the very last time_slice,
# if multiple temporal_block end at different points in time
function set_objective!(m::Model; alternative_objective=m -> nothing)
    alt_obj = alternative_objective(m)
    if alt_obj == nothing
        create_objective_terms!(m)
        total_discounted_costs = sum(
            in_window + beyond_window
            for (in_window, beyond_window) in values(m.ext[:spineopt].objective_terms)
        )
        if !iszero(total_discounted_costs)
            @objective(m, Min, total_discounted_costs)
        else
            @warn "zero objective"
        end
    else
        alt_obj
    end
end

function create_objective_terms!(m)
    window_end = end_(current_window(m))
    window_very_end = end_(last(time_slice(m)))
    beyond_window = collect(to_time_slice(m; t=TimeSlice(window_end, window_very_end)))
    in_window = collect(to_time_slice(m; t=current_window(m)))
    filter!(t -> !(t in beyond_window), in_window)
    for term in objective_terms(m)
        func = eval(term)
        m.ext[:spineopt].objective_terms[term] = (func(m, in_window), func(m, beyond_window))
    end
end
