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
	translate_heatrate_parameters(db_url, log_level)

Replace unit_idle_heat_rate by fix_units_on_coefficient_in_out and unit_incremental_heat_rate by 
fix_ratio_in_out_unit_flow.
"""
function translate_heatrate_parameters(db_url, log_level)
	@log log_level 0 string(
		"Replacing `unit_idle_heat_rate` by `fix_units_on_coefficient_in_out`, and `unit_incremental_heat_rate` by 
		`fix_ratio_in_out_unit_flow`..."
	)
	# Add new parameter definition items if they don't already exist
	run_request(db_url, "call_method", ("add_parameter_definition_item",), Dict(
		"entity_class_name" => "unit__node__node", "name" => "fix_units_on_coefficient_in_out")
	)
	run_request(db_url, "call_method", ("add_parameter_definition_item",), Dict(
		"entity_class_name" => "unit__node__node", "name" => "fix_ratio_in_out_unit_flow")
	)
	# Get entities in the class and get all alternatives
	entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict(
		"entity_class_name" => "unit__node__node")
	)
	alternative_items = run_request(db_url, "call_method", ("get_alternative_items",))
	for entity in entity_items
		for alternative in alternative_items
			# Get the value of the old unit_idle_heat_rate parameter
			pval = run_request(db_url, "call_method", ("get_parameter_value_item",), Dict(
				"entity_class_name" => "unit__node__node", 
				"parameter_definition_name" => "unit_idle_heat_rate", 
				"entity_byname" => (entity["element_name_list"]), 
				"alternative_name" => alternative["name"])
			)
			if length(pval) > 0
				# Add the value as fix_units_on_coefficient_in_out into the database
				run_request(
					db_url, "call_method", ("add_update_parameter_value_item",), Dict(
						"entity_class_name" => "unit__node__node", 
						"parameter_definition_name" => "fix_units_on_coefficient_in_out", 
						"entity_byname" => (entity["element_name_list"]), 
						"alternative_name" => alternative["name"], 
						"value" => pval["value"], 
						"type" => pval["type"])
				)
			end
			# Get the value of the old unit_incremental_heat_rate parameter
			pval = run_request(db_url, "call_method", ("get_parameter_value_item",), Dict(
				"entity_class_name" => "unit__node__node", 
				"parameter_definition_name" => "unit_incremental_heat_rate", 
				"entity_byname" => (entity["element_name_list"]), 
				"alternative_name" => alternative["name"])
			)
			if length(pval) > 0
				# Add the value as fix_ratio_in_out_unit_flow into the database
				run_request(
					db_url, "call_method", ("add_update_parameter_value_item",), Dict(
						"entity_class_name" => "unit__node__node", 
						"parameter_definition_name" => "fix_ratio_in_out_unit_flow", 
						"entity_byname" => (entity["element_name_list"]), 
						"alternative_name" => alternative["name"], 
						"value" => pval["value"], 
						"type" => pval["type"])
				)
			end
		end
	end
	# Remove old parameter definition
	pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
		"entity_class_name" => "unit__node__node", "name" => "unit_idle_heat_rate")
	)
	if length(pdef) > 0
		run_request(db_url, "call_method", ("remove_parameter_definition_item", pdef["id"]))
	end
	pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
		"entity_class_name" => "unit__node__node", "name" => "unit_incremental_heat_rate")
	)
	if length(pdef) > 0
		run_request(db_url, "call_method", ("remove_parameter_definition_item", pdef["id"]))
	end

	true
end