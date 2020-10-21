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
Add SpineOpt Master Problem variables to the given model.
"""
function add_mp_variables!(m; log_level=3)
    @timelog level3 "- [variable_mp_objective_lowerbound]" add_variable_mp_objective_lowerbound!(m)
    @timelog level3 "- [variable_mp_units_invested]" add_variable_mp_units_invested!(m)
    @timelog level3 "- [variable_mp_units_invested_available]" add_variable_mp_units_invested_available!(m)
    @timelog level3 "- [variable_mp_units_mothballed]" add_variable_mp_units_mothballed!(m)
end





