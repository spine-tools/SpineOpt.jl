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

function add_variable_units_invested!(m::Model)
    add_variable!(m, :units_invested, units_invested_available_indices; lb=x -> 0, int=units_invested_available_int)
end

function add_variable_mp_units_invested!(m::Model)
    add_variable!(m, :mp_units_invested, mp_units_invested_available_indices; lb=x -> 0, int=units_invested_available_int)
end