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
    refactor_fom_cost(db_url, log_level; kwargs...)

Refactor `fom_cost` parameter to `fixed_annual_cost`, 
including renaming the parameter and scaling up the old values into annual value by multiplying 8760.
"""
function refactor_fom_cost(db_url, log_level; kwargs...)
	@log log_level 0 "Converting `fom_cost` of `unit` to `fixed_annual_cost`"

    # the functions `scale_parameter_value` and `rename_parameter` are defined in `major_upgrade_1.jl`

    # ((class, parameter name before renaming), multiplication factor)
    # Scaling happens before renaming so that only the migrated values are scaled,
    # not any values of an already existing (e.g. hand-made) new parameter.
    @log log_level 0 "- Scaling parameter values..."
    scale_parameter_value(db_url, "unit", "fom_cost", 8760, log_level)    

    @log log_level 0 "- Renaming `fom_cost` to `fixed_annual_cost`... "
    rename_parameter(db_url, "unit", "fom_cost", "fixed_annual_cost", "", log_level)
    
    true
end
