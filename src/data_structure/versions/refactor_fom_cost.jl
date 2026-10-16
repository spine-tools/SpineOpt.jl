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

Refactor `unit` parameter `fom_cost` to `fixed_annual_cost`,
including renaming the parameter and scaling up the old values into annual values.

The old values are given per `duration_unit` of the `model`, i.e. its explicit value, or the default value of
the parameter definition for models without one (or if there are no models at all).
If all models in the database use the same duration unit, the values are multiplied by the number of hours (8760)
or minutes (525600) in a year accordingly, and this is logged as info.
If the models use different duration units, the values are converted per hour and a warning is logged.
Unknown duration units (not `hour` or `minute`, or a needed default value that is missing) are taken as `hour`,
as in SpineOpt, and a warning is logged.
"""
function refactor_fom_cost(db_url, log_level; kwargs...)
    @log log_level 0 "Converting `fom_cost` of `unit` to `fixed_annual_cost`"
    # NOTE: `scale_parameter_value`, `annual_scaling_factor` and `rename_parameter` are defined in `major_upgrade_1.jl`
    # Scaling happens before renaming so that only the migrated values are scaled,
    # not any values of an already existing (e.g. hand-made) new parameter.
    @log log_level 0 "- Scaling parameter values..."
    scale_parameter_value(db_url, "unit", "fom_cost", annual_scaling_factor, log_level)
    @log log_level 0 "- Renaming `fom_cost` to `fixed_annual_cost`... "
    rename_parameter(db_url, "unit", "fom_cost", "fixed_annual_cost", "", log_level)
    true
end
