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
	rename_model_types(db_url)

Rename `spineopt_master` to `spineopt_benders_master`, and `spineopt_operations` to `spineopt_standard`
"""
function rename_model_types(db_url, log_level)
	@log log_level 0 string(
		"Renaming `spineopt_master` to `spineopt_benders_master`, and `spineopt_operations` to `spineopt_standard`"
	)
	data = run_request(db_url, "query", ("list_value_sq", "parameter_value_list_sq"))
	model_type_list_ids = [x["id"] for x in data["parameter_value_list_sq"] if x["name"] == "model_type_list"]
	isempty(model_type_list_ids) && return true
	model_type_list_id = first(model_type_list_ids)
	list_value_ids = Dict(
		parse_db_value(x["value"], nothing) => x["id"]
		for x in data["list_value_sq"]
		if x["parameter_value_list_id"] == model_type_list_id
	)
	spineopt_master_id = get(list_value_ids, "spineopt_master", nothing)
	spineopt_operations_id = get(list_value_ids, "spineopt_operations", nothing)
	new_list_vals = []
	if spineopt_master_id !== nothing
		push!(
			new_list_vals, Dict("id" => spineopt_master_id, "value" => unparse_db_value("spineopt_benders_master")[1])
		)
	end
	if spineopt_operations_id !== nothing
		push!(new_list_vals, Dict("id" => spineopt_operations_id, "value" => unparse_db_value("spineopt_standard")[1]))
	end
	isempty(new_list_vals) && return true
	run_request(db_url, "call_method", ("update_items", "list_value", new_list_vals...))
	true
end
