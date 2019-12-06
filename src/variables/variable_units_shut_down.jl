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
    create_variable_units_shut_down!(m::Model)

"""
function create_variable_units_shut_down!(m::Model)
    m.ext[:variables][:units_shut_down] = Dict(
        (unit=u, t=t) => @variable(m, base_name="units_shut_down[$u, $(t.JuMP_name)]", integer=true, lower_bound=0)
        for (u, t) in units_on_indices()
    )
end
