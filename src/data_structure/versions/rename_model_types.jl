#############################################################################
# Copyright (C) 2017 - 2021  Spine Project
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

Renaming `spineopt_master` to `spineopt_benders_master`, and `spineopt_operations` to `spineopt_standard`
"""

function rename_model_types(db_url, log_level)
	@log log_level 0 "Renaming `spineopt_master` to `spineopt_benders_master`, and `spineopt_operations` to `spineopt_standard`"
	data = run_request(
		db_url, "query", ("object_parameter_value_sq", "parameter_value_list_sq")
	)
	# Find conn_flow_cost_vals
	pvals = data["object_parameter_value_sq"]
	pvals_2 = data["parameter_value_list_sq"]
	model_type_vals = [x for x in pvals if x["parameter_name"] == "model_type"]
	model_type_list = [x for x in pvals_2 if x["name"] == "model_type_list"]
	# Prepare new_data
	new_data = Dict()
	#find object parameter definition according to template
	new_data[:object_parameters] = [
		x for x in template()["object_parameters"] if x[2] == "model_type"
	]
	# Compute new_pvals (i.e. replace values)

	new_data[:object_parameter_values] = new_pvals = []
	new_data[:parameter_value_lists] = new_pval_list = []
	for pval in model_type_vals
		model_id = pval["object_id"]
		if pval["value"] == "spineopt_master"
			# run_request(db_url, "call_method", ("cascade_remove_items",), Dict(:parameter_definition => [model_id]))
			value = parse_db_value(pval["value"]) #we replace the value here
			new_pval = ["model", pval["object_name"], "model_type", "spineopt_benders_master"]
			push!(new_pvals, new_pval)
		elseif pval["value"] == "spineopt_operations"
			value = parse_db_value(pval["value"]) #we replace the value here
			new_pval = ["model", pval["object_name"], "model_type", "spineopt_standard"]
			push!(new_pvals, new_pval)
		end
	end
	data = [
		["model_type_list", "spineopt_benders_master"], ["model_type_list", "spineopt_standard"],
		["model_type_list", "spineopt_mga"],
	]
	new_pval = data
	run_request(db_url, "import_data", (new_data, ""))
	true
end
