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
	rename_benders_master_to_just_benders(db_url)

Rename `spineopt_benders_master` to `spineopt_benders`.
"""
function rename_benders_master_to_just_benders(db_url, log_level)
	@log log_level 0 "Renaming `spineopt_benders_master` to `spineopt_benders`"
	data = run_request(db_url, "query", ("list_value_sq", "parameter_value_list_sq"))
	model_type_list_ids = [x["id"] for x in data["parameter_value_list_sq"] if x["name"] == "model_type_list"]
	length(model_type_list_ids) == 1 || return true
	model_type_list_id = only(model_type_list_ids)
	benders_master_ids = [
		x["id"]
		for x in data["list_value_sq"]
		if x["parameter_value_list_id"] == model_type_list_id
		&& parse_db_value(x["value"], nothing) == "spineopt_benders_master"
	]
	length(benders_master_ids) == 1 || return true
	benders_master_id = only(benders_master_ids)
	new_list_val = Dict("id" => benders_master_id, "value" => unparse_db_value("spineopt_benders")[1])
	run_request(db_url, "call_method", ("update_items", "list_value", new_list_val))
	true
end
