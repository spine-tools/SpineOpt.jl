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
    add_variable_storages_mothballed_state_vintage!(m::Model)

Add `storages_mothballed_state_vintage` variables to model `m`.
"""
function add_variable_storages_mothballed_state_vintage!(m::Model)
    add_variable!(m, :storages_mothballed_state_vintage, storages_invested_available_vintage_indices; lb=x -> 0,vintage=true)
end
