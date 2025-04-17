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
	add_min_unit_flow(db_url, log_level)

Add min_unit_flow parameter.
"""
function add_min_unit_flow(db_url, log_level)
	@log log_level 0 "Adding `min_unit_flow` to `unit__from_node` and `unit__to_node`... "
	new_data = Dict()
	new_data[:relationship_parameters] = [
		x for x in template()["relationship_parameters"] if x[2] == "min_unit_flow"
	]
	# Add new data
	run_request(db_url, "import_data", (new_data, ""))
	true
end