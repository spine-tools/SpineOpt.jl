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
	translate_use_economic_representation__use_milestone_years(db_url, log_level)

Shift the `use_economic_representation` and `use_milestone_years` parameters into `multiyear_economic_discounting`.
"""
function translate_use_economic_representation__use_milestone_years(db_url, log_level)
	@log log_level 0 "Replacing `use_economic_representation` and `use_milestone_years` 
	by `multiyear_economic_discounting`..."
	
	# import_data(db_url, SpineOpt.template(), "Update template")	# To obtain all new parameter definitions
	
	# Check if the new parameter value list already exists
	data = run_request(db_url, "query", ("parameter_value_list_sq",))
	if !any(x -> x["name"] == "multiyear_economic_discounting_value_list", data["parameter_value_list_sq"])
		@log log_level 0 "Creating new parameter value list `multiyear_economic_discounting_value_list`"
		## Add new parameter value list for defining the new parameter
		run_request(db_url, "call_method", ("add_parameter_value_list",), Dict(
			"name" => "multiyear_economic_discounting_value_list")
		)
		## Add list items for the new parameter value list
		for (index, item) in enumerate(["consecutive_years", "milestone_years"])
			val_input, typ = unparse_db_value(item)	# val_input in `bytes` format, typ="str"
			run_request(db_url, "call_method", ("add_list_value",), Dict(
				"parameter_value_list_name" => "multiyear_economic_discounting_value_list", 
				"value" => val_input, "type" => typ, "index" => index)
			)
		end
		## A lagecy alternative approach
		# import_data(
		# 	db_url,
		# 	"";  # Don't commit
		# 	parameter_value_lists=[
		# 		("multiyear_economic_discounting_value_list", "consecutive_years"),
		# 		("multiyear_economic_discounting_value_list", "milestone_years"),
		# 	],
		# )
	else
		@log log_level 0 "Parameter value list `multiyear_economic_discounting_value_list` already exists"
	end
	
	# Add basic definition of the new parameter if it doesn't exist yet
	run_request(db_url, "call_method", ("add_parameter_definition_item",), Dict(
		"entity_class_name" => "model", 
		"name" => "multiyear_economic_discounting", 
		"parameter_value_list_name" => "multiyear_economic_discounting_value_list")
	)

	# Migrate `use_economic_representation` and `use_milestone_years` parameter values if they are set
	## Get relevant values of the old `use_economic_representation` parameter
	val_input, typ = unparse_db_value(true)	# val_input in `bytes` format, typ="bool"
	pvals__use_economic_representation = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
		"entity_class_name" => "model", 
		"parameter_definition_name" => "use_economic_representation",
		"value" => val_input)	
		# Only the `true` value (of the field type `bytes`) enables the multiyear economic discounting
	)
	
	## Add the new `multiyear_economic_discounting` value w.r.t. the old settings
	for pval_e in pvals__use_economic_representation
		### Find the associated `use_milestone_years` parameter value if it exists
		pval_m = run_request(db_url, "call_method", ("get_parameter_value_item",), Dict(
			"entity_class_name" => pval_e["entity_class_name"], 
			"parameter_definition_name" => "use_milestone_years", 
			"entity_byname" => pval_e["entity_byname"], 
			"alternative_name" => pval_e["alternative_name"],)
		)
		
		### Initiate the value for the new `multiyear_economic_discounting` parameter
		_new_parameter_value = "milestone_years"
		parsed_pval_m_value = parse_db_value(pval_m["value"], pval_m["type"])
		### an empty `use_milestone_years` or a false value means discounting along consecutive years
		if isempty(pval_m) || isnothing(parsed_pval_m_value) || !parsed_pval_m_value
			_new_parameter_value = "consecutive_years"
		end
		
		### Add the new `multiyear_economic_discounting` parameter value
		val_input, typ = unparse_db_value(_new_parameter_value) # val_input in `bytes` format, typ="str"
		run_request(
			db_url, "call_method", ("add_update_parameter_value_item",), 
			Dict(
				"entity_class_name" => pval_e["entity_class_name"], 
				"parameter_definition_name" => "multiyear_economic_discounting", 
				"entity_byname" => pval_e["entity_byname"], 
				"alternative_name" => pval_e["alternative_name"], 
				"value" => val_input, "type" => typ,
			)
		)		
	end

	# Remove definitions and values of `use_economic_representation` and `use_milestone_years`
	for parameter in ["use_economic_representation", "use_milestone_years"]
		pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
			"entity_class_name" => "model", "name" => parameter)
		)
		if length(pdef) > 0
			run_request(db_url, "call_method", ("remove_parameter_definition_item", pdef["id"]))
		end
	end
	# Values are removed automatically when the parameter definition is removed

	return true
end

