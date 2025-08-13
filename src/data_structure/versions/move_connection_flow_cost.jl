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
	move_connection_flow_cost(db_url)

Move connection_flow_cost from connection to connection__from_node and connection__to_node.
"""
function move_connection_flow_cost(db_url, log_level)
	@log log_level 0 "Moving `connection_flow_cost` from `connection` to `connection__from_node`, `connection__to_node`"
	data = run_request(
		db_url, "query", ("parameter_definition_sq", "object_parameter_value_sq", "wide_relationship_sq")
	)
	# Find conn_flow_cost_vals
	pvals = data["object_parameter_value_sq"]
	conn_flow_cost_vals = [x for x in pvals if x["parameter_name"] == "connection_flow_cost"]
	# Find rels_by_conn_id
	rels = data["wide_relationship_sq"]
	rels_by_conn_id = Dict()
	for rel in rels
		if rel["class_name"] in ("connection__from_node", "connection__to_node")
			conn_id = parse(Int64, first(split(rel["object_id_list"], ",")))
			push!(get!(rels_by_conn_id, conn_id, []), rel)
		end
	end
	# Prepare new_data
	new_data = Dict()
	new_data[:relationship_parameters] = [
		x for x in template()["relationship_parameters"] if x[2] == "connection_flow_cost"
	]
	# Compute new_pvals and invalid_conns
	new_data[:relationship_parameter_values] = new_pvals = []
	invalid_conns = []
	for pval in conn_flow_cost_vals
		conn_id = pval["object_id"]
		rels = get(rels_by_conn_id, conn_id, [])
		if isempty(rels)
			push!(invalid_conns, pval["object_name"])
			continue
		end
		rel = first(sort(rels, by=x -> x["class_name"] == "connection__to_node"))
		value = (pval["value"], pval["type"])
		new_pval = [rel["class_name"], split(rel["object_name_list"], ","), "connection_flow_cost", value]
		push!(new_pvals, new_pval)
	end
	if !isempty(invalid_conns)
		error(_invalid_connections_message(invalid_conns))
	end
	# Remove old_conn_flow_cost
	pdefs = data["parameter_definition_sq"]
	old_conn_flow_costs = [x for x in pdefs if x["name"] == "connection_flow_cost"]
	if !isempty(old_conn_flow_costs)
		id_ = first(old_conn_flow_costs)["id"]
		run_request(db_url, "call_method", ("remove_items", "parameter_definition", id_))
	end
	# Add new data
	run_request(db_url, "import_data", (new_data, ""))
	true
end

function _invalid_connections_message(invalid_conns)
	invalid_conns_str = join(invalid_conns, ", ", ", and ")
	msg = """
	failed to upgrade db:
	the following `connection` objects don't have any `connection__from_node` or `connection__to_node`
	to associate their `connection_flow_cost`: $invalid_conns_str
	"""
end