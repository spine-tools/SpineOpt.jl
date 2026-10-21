#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    rename_storage_fixed_annual_cost(db_url, log_level; kwargs...)

Rename `node` parameter `storage_fixed_annual_cost` to `fixed_annual_cost`,
which is shared with the `connection` class.
"""
function rename_storage_fixed_annual_cost(db_url, log_level; kwargs...)
    @log log_level 0 "Renaming `storage_fixed_annual_cost` to `fixed_annual_cost`... "
    rename_parameter(db_url, "node", "storage_fixed_annual_cost", "fixed_annual_cost", "", log_level)
    true
end
