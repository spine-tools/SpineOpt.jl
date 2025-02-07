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
	major_upgrade_to_15(db_url, log_level)

Run several migrations to update the class structure and to rename, modify and move parameters.
"""
function major_upgrade_to_16(db_url, log_level)
	@log log_level 0 string(
		"Running several migrations to update the class structure and to rename, modify and move parameters..."
	)
    # (original class, new class, dimensions, mapping of dimensions)
    classes_to_be_updated = [
        ("unit__from_node", "node__to_unit", ["node", "unit"], [2, 1]),
        ("unit__from_node__investment_group", "unit_flow__investment_group", ["node", "unit", "investment_group"], [2, 1, 3]),
        ("unit__from_node__user_constraint", "unit_flow__user_constraint", ["node", "unit", "user_constraint"], [2, 1, 3]),
        ("unit__to_node__investment_group", "unit_flow__investment_group", ["unit", "node", "investment_group"], [1, 2, 3]),
        ("unit__to_node__user_constraint", "unit_flow__user_constraint", ["unit", "node", "user_constraint"], [1, 2, 3]),
    ]
    # (original class, original parameter name), new parameter name, merge method("sum")
    parameters_to_be_renamed = [
        # unit
        (("unit", "number_of_units"), "existing_units", ""),
		# unit availability and outages
    	(("unit", "fix_units_out_of_service"), "out_of_service_count_fix", ""),
		(("unit", "initial_units_out_of_service"), "out_of_service_count_initial", ""),
		(("unit", "scheduled_outage_duration"), "outage_scheduled_duration", ""),
		(("unit", "unit_availability_factor"), "availability_factor", ""),
		(("unit", "units_unavailable"), "out_of_service_count_fix", "sum"),
		# unit online
		(("unit", "fix_units_on"), "online_count_fix", ""),
		(("unit", "initial_units_on"), "online_count_initial", ""),
		# unit installing and decommissioning
		(("unit", "unit_decommissioning_time"), "decommissioning_time", ""),
		(("unit", "unit_discount_rate_technology_specific"), "discount_rate_technology_specific", ""),
		(("unit", "unit_investment_econ_lifetime"), "lifetime_economic", ""),
		(("unit", "unit_investment_tech_lifetime"), "lifetime_technical", ""),
		(("unit", "unit_investment_lifetime_sense"), "lifetime_constraint_sense", ""),
		(("unit", "unit_investment_variable_type"), "investment_variable_type", ""),
		(("unit", "unit_lead_time"), "lead_time", ""),
		# unit investment limits
		(("unit", "candidate_units"), "investment_count_max_cumulative", ""),
		(("unit", "fix_units_invested"), "investment_count_fix_new", ""),
		(("unit", "fix_units_invested_available"), "investment_count_fix_cumulative", ""),
		(("unit", "initial_units_invested"), "investment_count_initial_new", ""),
		(("unit", "initial_units_invested_available"), "investment_count_initial_cumulative", ""),
		# unit mga
		(("unit", "units_invested_big_m_mga"), "mga_investment_big_m", ""),
		(("unit", "units_invested_mga"), "mga_investment_activate", ""),

		# node
		(("node", "balance_type"), "node_type", ""),
    ]
    #@log log_level 0 string("Creating superclasses...")
    #@log log_level 0 string("Note: Check entity alternatives in classes related to the unit_flow superclass...")
    #create_superclasses_and_subclasses(db_url, log_level)
    @log log_level 0 string("Merging has_state and balance_type...")
    merge_has_state_and_balance_type_parameters(db_url, log_level)
    #@log log_level 0 string("Update ordering of multidimensional classes...")
    #update_ordering_of_multidimensional_classes(db_url, classes_to_be_updated, log_level)
    @log log_level 0 string("Renaming parameters...")
    rename_parameters(db_url, parameters_to_be_renamed, log_level)
    true
end

# Always check the last item
function check_run_request_return_value(value_to_be_checked, print_value=true)
	if value_to_be_checked[end] != nothing && value_to_be_checked[end] != ""
		if print_value
            #@log log_level 0 string(value_to_be_checked[end])
		end
		throw(error())
	end
end

# Add parameter values from a parameter value item list to a dictionary
function create_dict_from_parameter_value_items(db_url, pvals)
	existing_values = Dict{Any, Vector{Tuple{Any, Any}}}()
	for pval in pvals
		entity = pval["entity_byname"]
		if pval["type"] == "list_value_ref"
			list_value = run_request(db_url, "call_method", ("get_list_value_item",), Dict(
				"id" => pval["list_value_id"])
			)
			parsed_value = parse_db_value(list_value["value"], list_value["type"])
		else
			parsed_value = parse_db_value(pval["value"], pval["type"])
		end
		if !haskey(existing_values, entity)
			existing_values[entity] = [(pval["alternative_name"], parsed_value)]
		else
			push!(existing_values[entity], (pval["alternative_name"], parsed_value))
		end
	end
	return existing_values
end

# For each alternative, find the first value of related entities' specific set of parameters
# (take the multiplicative inverse)
function find_multiplier_first(db_url, entity_item, multiplier_items, vals)
	multipliers = Dict()
	added_alternatives = Array{String}(undef, 0)
	# For each class in multiplier_items, find the items where entity_item is in the correct position	
	for multiplier_item in multiplier_items
		related_entities = find_related_entities(db_url, multiplier_item[1], entity_item, multiplier_item[3])
		# Go through the items, check if they have the correct parameter
		for related_entity in related_entities
			if haskey(vals, related_entity["element_name_list"])
				val_list = vals[related_entity["element_name_list"]]
				# Go through the parameter alternatives and add to multipliers if the same alternative is not yet there
				for (alternative_name, val) in val_list
					if !(alternative_name in added_alternatives)
						if !haskey(multipliers, (multiplier_item[1], related_entity))
							multipliers[(multiplier_item[1], related_entity)] = [(alternative_name, 1 / val)]
						else
							push!(multipliers[(multiplier_item[1], related_entity)], (alternative_name, 1 / val))
						end
						push!(added_alternatives, alternative_name)
					end
				end
			end
		end
	end
	return multipliers
end

# Find entities in class_name which have entity_item in the linking_dimension dimension
function find_related_entities(db_url, class_name, entity_item, linking_dimension)
	related_entities = Array{Any}(undef, 0)
	entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict(
		"entity_class_name" => class_name)
	)
	for entity in entity_items
		if entity["element_name_list"][linking_dimension] == entity_item[1]
			push!(related_entities, entity)
		end
	end
	return related_entities
end

# Check if alternatives are the same and add a combination to the database if not. 
# Return the updated alternative and boolean describing if original alternatives were the same.
function add_merged_alternative(db_url, alternative_name_1, alternative_name_2, log_level)
	alternatives_the_same = false
	if alternative_name_1 == alternative_name_2
		alternative_updated = alternative_name_1
		alternatives_the_same = true
	else
		# Create a new alternative based on the two and add
		alternative_updated = string(alternative_name_1, "__", alternative_name_2)
		try
			@log log_level 0 string("Warning: Creating a new alternative $alternative_updated, add manually to \
				the scenarios.")
			check_run_request_return_value(run_request(
				db_url, "call_method", ("add_alternative_item",), Dict(
					"name" => alternative_updated)
				)
			)
		catch
			@log log_level 0 string("Warning: Could not create alternative $alternative_updated.")
		end
	end
	return alternative_updated, alternatives_the_same
end


# Create specific new classes as superclasses and subclasses
function create_superclasses_and_subclasses(db_url, log_level)
	# Add new classes
	try
		check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
			"name" => "node__to_unit", "dimension_name_list" => ["node", "unit"]))
		)
 		check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
			"name" => "unit_flow", "dimension_name_list" => ["unit", "node"]))
		)
		check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
			"name" => "unit_flow__unit_flow", "dimension_name_list" => ["unit_flow", "unit_flow"]))
		)
		check_run_request_return_value(run_request(db_url, "call_method", ("add_superclass_subclass_item",), Dict(
			"superclass_name" => "unit_flow", "subclass_name" => "node__to_unit"))
		)
		check_run_request_return_value(run_request(db_url, "call_method", ("add_superclass_subclass_item",), Dict(
			"superclass_name" => "unit_flow", "subclass_name" => "unit__to_node"))
		)
	catch
		@log log_level 0 string("Could not add superclasses and subclasses.")
	end
end

# A specific function for merging has_state and balance_type parameters
function merge_has_state_and_balance_type_parameters(db_url, log_level)
	# Create mapping from old parameter value list item names to new ones
	name_mapping = Dict(
		"balance_type_none" => "no_balance", "balance_type_node" => "balance_node", 
		"balance_type_group" => "balance_group"
	)
	# Update parameter value list item names based on the mapping
	list_value_items = run_request(db_url, "call_method", ("get_list_value_items",), Dict(
		"parameter_value_list_name" => "balance_type_list")
	)
	for list_value_item in list_value_items
		old_name = parse_db_value(list_value_item["value"], list_value_item["type"])
		new_name_value, new_name_type = unparse_db_value(name_mapping[old_name])
		check_run_request_return_value(run_request(
			db_url, "call_method", ("update_list_value_item",), Dict(
				"id" => list_value_item["id"], "value" => new_name_value, "type" => new_name_type))
		)
	end
	# Add new items to the same parameter value list items
	for (list_value_name, list_index) in [("storage_node", 3), ("storage_group", 4)]
		new_name_value, new_name_type = unparse_db_value(list_value_name)
		check_run_request_return_value(run_request(
			db_url, "call_method", ("add_list_value_item",), Dict(
				"parameter_value_list_name" => "balance_type_list", "value" => new_name_value, "type" => new_name_type,
				"index" => list_index))
		)
	end
	# Rename the parameter value list
	pval_list_item = run_request(db_url, "call_method", ("get_parameter_value_list_item",), Dict(
		"name" => "balance_type_list")
	)
	check_run_request_return_value(run_request(
		db_url, "call_method", ("update_parameter_value_list_item",), Dict(
			"id" => pval_list_item["id"], "name" => "node_type_list"))
	)
	# Prepare dictionaries from has_state and balance_type parameters
	pvals_state = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
		"entity_class_name" => "node", "parameter_definition_name" => "has_state")
	)
	vals_state = create_dict_from_parameter_value_items(db_url, pvals_state)
	pvals_type = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
		"entity_class_name" => "node", "parameter_definition_name" => "balance_type")
	)
	vals_type = create_dict_from_parameter_value_items(db_url, pvals_type)
	# Include has_state info in balance_type parameter
	for (entity, val_state_list) in vals_state
		if haskey(vals_type, entity)
			val_type_list = vals_type[entity]
			for (alternative, val_state) in val_state_list
				if val_state == true
					base_alternative_added = false
					for (alternative2, val_type) in val_type_list
						alternative_updated, base_alternative_added = add_merged_alternative(
							db_url, alternative, alternative2, log_level
						)
						if val_type == "balance_group"
							new_type = "storage_group"
						elseif val_type == "no_balance"
							new_type = "no_balance"
						else
							new_type = "storage_node"
						end
						# Convert the object into a DB representation
						db_value, db_type = unparse_db_value(new_type)
						# Add the new parameter value into the database
						check_run_request_return_value(run_request(
							db_url, "call_method", ("add_update_parameter_value_item",), Dict(
								"entity_class_name" => "node", 
								"parameter_definition_name" => "balance_type", 
								"entity_byname" => entity, 
								"alternative_name" => alternative_updated, 
								"value" => db_value,
								"type" => db_type)
							)
						)
					end
					if !base_alternative_added
						new_type = "storage_node"
						# Convert the object into a DB representation
						db_value, db_type = unparse_db_value(new_type)
						# Add the new parameter value into the database
						check_run_request_return_value(run_request(
							db_url, "call_method", ("add_update_parameter_value_item",), Dict(
								"entity_class_name" => "node", 
								"parameter_definition_name" => "balance_type", 
								"entity_byname" => entity, 
								"alternative_name" => alternative, 
								"value" => db_value,
								"type" => db_type)
							)
						)
					end
				end
			end
		end
	end
	# Remove old parameter definition
	pdef = run_request(db_url, "call_method", ("get_parameter_definition_item",), Dict(
		"entity_class_name" => "node", "name" => "has_state")
	)
	if length(pdef) > 0
		check_run_request_return_value(run_request(
			db_url, "call_method", ("remove_parameter_definition_item", pdef["id"]))
		)
	end
end

# Go through the classes, update ordering of their dimensions and commit session
function update_ordering_of_multidimensional_classes(db_url, classes_to_be_updated, log_level)
	for (old_class, new_class, dimensions, mapping) in classes_to_be_updated
		update_ordering_of_multidimensional_class(db_url, old_class, new_class, dimensions, mapping, log_level)
		# Remove old class
        @log log_level 0 string(old_class)
		class_item = run_request(db_url, "call_method", ("get_entity_class_item",), Dict("name" => old_class))
		check_run_request_return_value(run_request(
			db_url, "call_method", ("remove_entity_class_item", class_item["id"]))
		)
	end
end

# Update ordering of class dimensions, add as a new class
function update_ordering_of_multidimensional_class(db_url, old_class, new_class, dimensions, mapping, log_level)
	try
		# Create new class
		check_run_request_return_value(run_request(db_url, "call_method", ("add_entity_class_item",), Dict(
			"name" => new_class, "dimension_name_list" => dimensions))
		)
	catch
	end
	# Add parameter definitions
	pdefs = run_request(db_url, "call_method", ("get_parameter_definition_items",), Dict(
		"entity_class_name" => old_class)
	)
	for pdef in pdefs
		try
			check_run_request_return_value(run_request(db_url, "call_method", ("add_parameter_definition_item",), Dict(
				"entity_class_name" => new_class,
				"name" => pdef["name"],
				"default_value" => pdef["default_value"],
				"default_type" => pdef["default_type"],
				"parameter_value_list_name" => pdef["parameter_value_list_name"],
				"description" => pdef["description"]))
			)
		catch
		end
	end
	try
		# Add the entity into the database if it is not there already
		entity_items = run_request(db_url, "call_method", ("get_entity_items",), Dict(
			"entity_class_name" => old_class)
		)
		entities = Dict()
		for entity_item in entity_items
			new_element_name_list = [entity_item["element_name_list"][i] for i in mapping]
			check_run_request_return_value(run_request(
				db_url, "call_method", ("add_entity_item",), Dict(
					"entity_class_name" => new_class, 
					"entity_byname" => new_element_name_list,
					"description" => entity_item["description"])
			))
			entities[entity_item["element_name_list"]] = entity_item
		end
		for pdef in pdefs
			# Find old parameters in all entities and alternatives
			pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
				"entity_class_name" => old_class, "parameter_definition_name" => pdef["name"])
			)
			vals = create_dict_from_parameter_value_items(db_url, pvals)
			for (old_entity, val_list) in vals
				# Determine element name list
				new_element_name_list = [old_entity[i] for i in mapping]
				for (alternative, val) in val_list
					db_value, db_type = unparse_db_value(val)
					check_run_request_return_value(run_request(
						db_url, "call_method", ("add_parameter_value_item",), Dict(
						"entity_class_name" => new_class,
						"entity_byname" => new_element_name_list,
						"alternative_name" => alternative,
						"parameter_definition_name" => pdef["name"],
						"value" => db_value,
						"type" => db_type))
					)
				end
			end
		end
	catch
		@log log_level 0 string("Could not update ordering of a multidimensional class.")
	end
end

# Go through the parameters, rename them and commit session
function rename_parameters(db_url, parameters_to_be_renamed, log_level)
	for (old_par_def, new_par_name, merge_method) in parameters_to_be_renamed
		rename_parameter(db_url, old_par_def[1], old_par_def[2], new_par_name, merge_method, log_level)
	end
end

# Find the parameter id and rename the parameter
function rename_parameter(db_url, class_name, old_par_name, new_par_name, merge_method, log_level)
	pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
		"entity_class_name" => class_name, "name" => old_par_name)
	)
	if length(pdef) > 0
		try
			check_run_request_return_value(run_request(db_url, "call_method", ("update_item", "parameter_definition"), Dict(
				"id" => pdef["id"], "name" => new_par_name))
			)
		catch
			if merge_method == "sum"
				sum_to_existing_parameter(db_url, class_name, old_par_name, new_par_name, log_level)
			end
			# Remove old parameter definition
			check_run_request_return_value(run_request(
				db_url, "call_method", ("remove_parameter_definition_item", pdef["id"]))
			)
		end
	end
end

# Sum old_par_name values to new_par_name values
function sum_to_existing_parameter(db_url, class_name, old_par_name, new_par_name, log_level)
	# Find old parameters in all entities and alternatives
	pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
		"entity_class_name" => class_name, "parameter_definition_name" => old_par_name)
	)
	vals = create_dict_from_parameter_value_items(db_url, pvals)
	# Find existing parameters in all entities and alternatives
	pvals_existing = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
		"entity_class_name" => class_name, "parameter_definition_name" => new_par_name)
	)
	existing_values = create_dict_from_parameter_value_items(db_url, pvals_existing)
	for (entity, val_list) in vals
		for (alternative, val) in val_list
			base_alternative_added = false
			# Find if entity in existing_values
			if haskey(existing_values, entity)
				summed_parsed_pval = val
				# Loop over alternatives in existing_values[entity]
				for existing_value in existing_values[entity]
					alternative_updated, base_alternative_added = add_merged_alternative(
						db_url, alternative, existing_value[1], log_level
					)
					summed_parsed_pval += existing_value[2]
					summed_pval_value, summed_pval_type = unparse_db_value(summed_parsed_pval)
					# Add the new parameter value into the database
					check_run_request_return_value(run_request(
						db_url, "call_method", ("add_update_parameter_value_item",), Dict(
							"entity_class_name" => class_name, "parameter_definition_name" => new_par_name, 
							"entity_byname" => entity, 
							"alternative_name" => alternative_updated, 	
							"value" => summed_pval_value, "type" => summed_pval_type)
						)
					)
				end
			end
			pval_value, pval_type = unparse_db_value(val)
			if !base_alternative_added
				# Add the new parameter value into the database
				check_run_request_return_value(run_request(
					db_url, "call_method", ("add_update_parameter_value_item",), Dict(
						"entity_class_name" => class_name, "parameter_definition_name" => new_par_name, 
						"entity_byname" => entity, "alternative_name" => alternative, 
						"value" => pval_value, "type" => pval_type)
					)
				)
			end						
		end
	end
end