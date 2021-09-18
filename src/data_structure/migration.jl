#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
# Finally, `include` the file right here,
# and append the function name to `_upgrade_functions` below.
# Everything else should be automatically taken care of, I believe.
# And truly finally, modify the template!
# Including the version information!
# The important thing is to increase the default_value of the `version` parameter in the `settings` class.

include("versions/rename_unit_constraint_to_user_constraint.jl")

_upgrade_functions = [rename_unit_constraint_to_user_constraint]

"""
	current_version()

The current version of the db structure as an integer.
"""
current_version() = length(_upgrade_functions) + 1

"""
	run_migrations(url, version)

Run migrations on the given url starting from the given version.
"""
function run_migrations(url, version)
	run_request(url, "open_connection")
	try
		while _run_migration(url, version)
			version = find_version(url)
		end
	finally
		run_request(url, "close_connection")
	end
end

function _run_migration(url, version)
	upgrade_fn = get(_upgrade_functions, version, nothing)
	upgrade_fn === nothing && return false
	upgrade_fn(url)
	run_request(
		url,
		"import_data", 
		Dict("object_parameters" => [("settings", "version", version + 1)]),
		"Update SpineOpt data structure to $(version + 1)"
	)
	true
end

"""
	find_version(url)

The version of the data structure at the given url. Versions start at 1.
If the db doesn't have the `settings` object class or the `version` parameter definition,
create them, setting `version`'s default_value to 1.
"""
function find_version(url)
	data = run_request(url, "get_data", "object_class_sq")
	i = findfirst(x -> x["name"] == "settings", data["object_class_sq"])
	if i == nothing
		settings_class = first([x for x in _template["object_classes"] if x[1] == "settings"])
		run_request(
			url,
			"import_data",
			Dict("object_classes" => [settings_class]),
			"Add settings object class"
		)
		return find_version(url)
	end
	settings_class = data["object_class_sq"][i]
	data = run_request(url, "get_data", "parameter_definition_sq")
	j = findfirst(
		x -> x["name"] == "version" && x["entity_class_id"] == settings_class["id"], data["parameter_definition_sq"]
	)
	if j == nothing
		version_par_def = first([x for x in _template["object_parameters"] if x[1:2] == ["settings", "version"]])
		version_par_def[3] = 1  # position 3 is default_value
		run_request(
			url,
			"import_data",
			Dict("object_parameters" => [version_par_def]),
			"Add version parameter definition"
		)
		return find_version(url)
	end
	parse(Int, data["parameter_definition_sq"][j]["default_value"])
end
