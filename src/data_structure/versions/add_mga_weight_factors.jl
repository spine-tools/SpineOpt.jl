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
	add_mga_weight_factors(db_url, log_level)

Add mga weight factors and use more sensible default parameters.
"""
function add_mga_weight_factors(db_url, log_level)
	@log log_level 0 "Adding `unit/connection_(intact_)flow_non_anticipativity_time`..."
	new_data = Dict()
	new_data[:object_parameters] = [
		x for x in template()["object_parameters"] if x[2] in (
			"units_invested_mga_weight",
			"connections_invested_mga_weight",
			"storages_invested_mga_weight",
			"units_invested_big_m_mga",
			"storages_invested_big_m_mga",
			"connections_invested_big_m_mga"
		)
	]
	# Add new data
	run_request(db_url, "import_data", (new_data, ""))
	true
end
