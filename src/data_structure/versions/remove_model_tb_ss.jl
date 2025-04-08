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
	remove_model_tb_ss(db_url)

Get rid of model__temporal_block and model__stochastic_structure.
"""
function remove_model_tb_ss(db_url, log_level)
	to_rm_ec_names = ("model__temporal_block", "model__stochastic_structure")
	to_rm_str = join(("`$x`" for x in to_rm_ec_names), " and ")
	@log log_level 0 "Removing $to_rm_str"
	ecs = run_request(db_url, "query", ("entity_class_sq",))["entity_class_sq"]
	ec_id_by_name = Dict(x["name"] => x["id"] for x in ecs)
	to_rm_ec_ids = unique(ec_id_by_name[name] for name in intersect(to_rm_ec_names, keys(ec_id_by_name)))
	if !isempty(to_rm_ec_ids)
		run_request(db_url, "call_method", ("remove_items", "entity_class", to_rm_ec_ids...))
	end
	true
end