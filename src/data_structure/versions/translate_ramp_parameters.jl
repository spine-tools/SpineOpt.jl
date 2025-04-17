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
	translate_ramp_parameters(db_url)

Get rid of all the lower bound parameters,
min_startup_ramp, min_shutdown_ramp, min_res_startup_ramp, min_res_shutdown_ramp;
we just need minimum_operating_point.
Get rid of max_res_startup_ramp and max_res_shutdown_ramp parameters;
instead, use max_startup_ramp and max_shutdown_ramp also for the non-spinning reserve flows 
- but rename these parameters to startup_limit and shutdown_limit.
"""
function translate_ramp_parameters(db_url, log_level)
	to_rm_pnames = (
		"min_startup_ramp",
		"min_shutdown_ramp",
		"min_res_startup_ramp",
		"min_res_shutdown_ramp",
		"max_res_startup_ramp",
		"max_res_shutdown_ramp",
	)
	new_name_by_old_name = Dict("max_startup_ramp" => "start_up_limit", "max_shutdown_ramp" => "shut_down_limit")
	to_rm_str = join(("`$x`" for x in to_rm_pnames), ", ", " and ")
	new_name_old_name_str = join(("`$x` to `$y`" for (x, y) in new_name_by_old_name), ", ", " and ")
	@log log_level 0 "Removing $to_rm_str, and renaming $new_name_old_name_str"
	pdefs = run_request(db_url, "query", ("parameter_definition_sq",))["parameter_definition_sq"]
	pid_by_name = Dict(x["name"] => x["id"] for x in pdefs)
	to_rm_pdef_ids = unique(pid_by_name[name] for name in intersect(to_rm_pnames, keys(pid_by_name)))
	to_upd_pdefs = [
		Dict("id" => pid_by_name[old_name], "name" => new_name_by_old_name[old_name])
		for old_name in intersect(keys(new_name_by_old_name), keys(pid_by_name))
	]
	if !isempty(to_rm_pdef_ids)
		run_request(db_url, "call_method", ("remove_items", "parameter_definition", to_rm_pdef_ids...))
	end
	if !isempty(to_upd_pdefs)
		run_request(db_url, "call_method", ("update_items", "parameter_definition", to_upd_pdefs...))
	end
	true
end