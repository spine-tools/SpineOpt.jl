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
	rename_unit_constraint_to_user_constraint(db_url)

Replace unit_constraint by user_constraint in all object and relationship class names.
"""
function rename_unit_constraint_to_user_constraint(db_url)
	data = run_request(db_url, "get_data", "object_class_sq", "wide_relationship_class_sq")
	obj_classes = [x for x in data["object_class_sq"] if x["name"] == "unit_constraint"]
	rel_classes = [x for x in data["wide_relationship_class_sq"] if occursin("unit_constraint", x["name"])]
	for x in Iterators.flatten((obj_classes, rel_classes))
		x["name"] = replace(x["name"], "unit_constraint" => "user_constraint")
	end
	run_request(db_url, "call_method", "update_object_classes", obj_classes...)
	run_request(db_url, "call_method", "update_wide_relationship_classes", rel_classes...)
	run_request(db_url, "call_method", "commit_session", "Rename unit_constraint to user_constraint")
end