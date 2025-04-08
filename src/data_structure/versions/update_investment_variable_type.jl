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
	update_investment_variable_type(db_url)

Update parameter value lists and default values for connection_investment_variable_type and
storage_investment_variable_type.
"""
function update_investment_variable_type(db_url, log_level)
	new_value_by_old_value_by_pname = Dict(
		"connection_investment_variable_type" => Dict(
			"variable_type_continuous" => "connection_investment_variable_type_continuous",
			"variable_type_integer" => "connection_investment_variable_type_integer",
		),
		"storage_investment_variable_type" => Dict(
			"variable_type_continuous" => "storage_investment_variable_type_continuous",
			"variable_type_integer" => "storage_investment_variable_type_integer",
		),
	)
	@log log_level 0 "Updating $(join(("`$k`" for k in keys(new_value_by_old_value_by_pname)), " and "))"
	data = run_request(db_url, "query", ("parameter_definition_sq", "parameter_value_sq",))
	pdef_name_by_id = Dict(x["id"] => x["name"] for x in data["parameter_definition_sq"])
	pvals_to_add = []
	for pval in data["parameter_value_sq"]
		pname = pdef_name_by_id[pval["parameter_definition_id"]]
		new_value_by_old_value = get(new_value_by_old_value_by_pname, pname, nothing)
		if new_value_by_old_value !== nothing
			value = parse_db_value(pval["value"], pval["type"])
			new_value = new_value_by_old_value[value]
			new_pval = merge(pval, Dict(zip(("value", "type"), unparse_db_value(new_value))))
			push!(pvals_to_add, new_pval)
		end
	end
	if !isempty(pvals_to_add)
		# Remove pvals before updating value list in pdef, otherwise it complains
		pval_ids_to_rm = [x["id"] for x in pvals_to_add]
		run_request(db_url, "call_method", ("remove_items", "parameter_value", pval_ids_to_rm...))
		# Commit session to confirm the removal. Otherwise the item will stay in the db. This is necessary 
		# because the next "add_item" request will add the same parameter_value item with different value.
		run_request(db_url, "call_method", ("commit_session", "remove_outdated_parameter_values"))
	end
	import_data(
		db_url,
		"";  # Don't commit
		parameter_value_lists=[
			("storage_investment_variable_type_list", "storage_investment_variable_type_continuous"),
			("storage_investment_variable_type_list", "storage_investment_variable_type_integer"),
		],
		object_parameters=[
			(
				"connection",
				"connection_investment_variable_type",
				"connection_investment_variable_type_integer",
				"connection_investment_variable_type_list",
			),
			(
				"node",
				"storage_investment_variable_type",
				"storage_investment_variable_type_integer",
				"storage_investment_variable_type_list",
			),
		],
	)
	if !isempty(pvals_to_add)
		run_request(db_url, "call_method", ("add_items", "parameter_value", pvals_to_add...))
	end
	true
end