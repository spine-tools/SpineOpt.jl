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
function set_objective!(m::Model)
    total_discounted_costs = total_costs(m, end_(last(time_slice(m))))
    if !iszero(total_discounted_costs)
        @objective(m, Min, total_discounted_costs)
    else
        @warn "zero objective"
    end
end
