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

# Here we do everything related to migrations.
# To add a new version, just create a file in the versions folder with a descriptive name.
# In that file, define a function named after the file (let's use that convention) that does the work.
# Typically the above means calling `run_request` with the url and using the "call_method" request.
# Info about what methods are available should be found in spinedb_api's documentation.
# Then, `include` the file right here, and append the function name to `_upgrade_functions` below.
# Everything else should be automatically taken care of, I believe.
# And finally, modify the template - including the version information
# The important thing is to increase the default_value of the `version` parameter in the `settings` class.

include("versions/rename_unit_constraint_to_user_constraint.jl")
include("versions/move_connection_flow_cost.jl")
include("versions/rename_model_types.jl")
include("versions/add_min_unit_flow.jl")
include("versions/add_flow_non_anticipativity_time.jl")
include("versions/add_mga_weight_factors.jl")
include("versions/rename_benders_master_to_just_benders.jl")
include("versions/translate_ramp_parameters.jl")
include("versions/remove_model_tb_ss.jl")
include("versions/update_investment_variable_type.jl")
include("versions/add_model_algorithm.jl")
include("versions/rename_lifetime_to_tech_lifetime.jl")
include("versions/translate_heatrate_parameters.jl")
include("versions/translate_use_economic_representation__use_milestone_years.jl")

function add_units_out_of_service_and_min_capacity_margin(db_url, log_level)
	# No changes, just make sure we load the newest template
	return true
end

function add_stage_output(db_url, log_level)
	# No changes, just make sure we load the newest template
	return true
end

function add_node_availability_factor(db_url, log_level)
	# No changes, just make sure we load the newest template
	return true
end

function add_node_state_min_factor(db_url, log_level)
	# No changes, just make sure we load the newest template
	return true
end

function add_connection_min_factor(db_url, log_level)
	# No changes, just make sure we load the newest template
	return true
end

_upgrade_functions = [
	rename_unit_constraint_to_user_constraint,
	move_connection_flow_cost,
	rename_model_types,
	add_min_unit_flow,
	add_flow_non_anticipativity_time,
	add_mga_weight_factors,
	rename_benders_master_to_just_benders,
	translate_ramp_parameters,
	remove_model_tb_ss,
	add_units_out_of_service_and_min_capacity_margin,
	update_investment_variable_type,
	add_model_algorithm,
	rename_lifetime_to_tech_lifetime,
	translate_heatrate_parameters,
	add_stage_output,
	add_node_availability_factor,
	add_node_state_min_factor,
	add_connection_min_factor,
	translate_use_economic_representation__use_milestone_years,
]

"""
	current_version()

The current version of the db structure as an integer.
"""
current_version() = length(_upgrade_functions) + 1

"""
	run_migrations(url, version)

Run migrations on the given url starting from the given version.
"""
function run_migrations(url, version, log_level)
	without_filters(url) do clean_url
		while _run_migration(clean_url, version, log_level)
			version += 1
		end
		run_request(clean_url, "import_data", (SpineOpt.template(), "Upgrade data structure to version $(version - 1)"))
	end
end

function _run_migration(url, version, log_level)
	upgrade_fn = get(_upgrade_functions, version, nothing)
	upgrade_fn === nothing && return false
	upgrade_fn(url, log_level) || return false
	true
end

"""
	find_version(url)

The version of the data structure at the given url. Versions start at 1.
If the db doesn't have the `settings` object class or the `version` parameter definition,
create them, setting `version`'s default_value to 1.
"""
function find_version(url)
	obj_clss = run_request(url, "query", ("object_class_sq",))["object_class_sq"]
	i = findfirst(x -> x["name"] == "settings", obj_clss)
	if isnothing(i)
		settings_class = first([x for x in _template["object_classes"] if x[1] == "settings"])
		run_request(
			url,
			"import_data",
			(Dict("object_classes" => [settings_class]), "Add settings object class")
		)
		return find_version(url)
	end
	settings_class = obj_clss[i]
	pdefs = run_request(url, "query", ("parameter_definition_sq",))["parameter_definition_sq"]
	j = findfirst(x -> x["name"] == "version" && x["entity_class_id"] == settings_class["id"], pdefs)
	if isnothing(j)
		version_par_def = first([x for x in _template["object_parameters"] if x[1:2] == ["settings", "version"]])
		version_par_def[3] = 1  # position 3 is default_value
		run_request(
			url,
			"import_data",
			(Dict("object_parameters" => [version_par_def]), "Add version parameter definition")
		)
		return 1
	end
	version = parse_db_value(pdefs[j]["default_value"], pdefs[j]["default_type"])
	_parse_version(version)
end



_parse_version(version::String) = _parse_version(parse(Float64, version))
_parse_version(version::Float64) = _parse_version(round(Int, version))
_parse_version(version::Int) = version
