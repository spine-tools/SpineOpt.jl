#############################################################################
# Copyright (C) 2017 - 2020  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

function diagnose_spineopt(url_in; upgrade=false, log_level=3, filters=Dict("tool" => "object_activity_control"))
	prepare_spineopt(url_in; upgrade=upgrade, log_level=log_level, filters=filters)
	_diagnose(node, _node_issue)
	_diagnose(unit, _unit_issue)
	_diagnose(connection, _connection_issue)
end

function _diagnose(class::ObjectClass, issue_fn)
	issues = [string(x, " -- ", issue) for (x, issue) in ((x, issue_fn(x)) for x in class()) if issue !== nothing]
	if !isempty(issues)
		@warn string("the following $(class.name) items might have issues:\n\t", join(issues, "\n\t"))
	end
end

function _node_issue(n)
	if any(balance_type(node=ng) === :balance_type_group for ng in groups(n))
		return nothing
	end
	if balance_type(node=n) === :balance_type_none
		return "balance_type is set to balance_type_none"
	end
end

function _has_cap_or_cost(indices, parameters)
	[(x.node, any(p(; x..., _strict=false) !== nothing for p in parameters)) for x in indices]
end

function _unit_issue(u)
	parameters = (unit_capacity, fuel_cost, vom_cost)
	node_from_has_cap_or_cost = _has_cap_or_cost(unit__from_node(unit=u, _compact=false), parameters)
	node_to_has_cap_or_cost = _has_cap_or_cost(unit__to_node(unit=u, _compact=false), parameters)
	for (n_from, has_cap_or_cost_from) in node_from_has_cap_or_cost
		has_cap_or_cost_from || any(
			has_cap_or_cost_to && _are_unit_flows_related(u, n_from, n_to)
			for (n_to, has_cap_or_cost_to) in node_to_has_cap_or_cost
		) || return "flow from $n_from is unbounded"
	end
	for (n_to, has_cap_or_cost_to) in node_to_has_cap_or_cost
		has_cap_or_cost_to || any(
			has_cap_or_cost_from && _are_unit_flows_related(u, n_from, n_to)
			for (n_from, has_cap_or_cost_from) in node_from_has_cap_or_cost
		) || return "flow to $n_to is unbounded"
	end
end

function _are_unit_flows_related(u, n_from, n_to)
	any(
		ratio(unit=u, node1=n_to, node2=n_from, _strict=false) !== nothing
		for ratio in (fix_ratio_out_in_unit_flow, max_ratio_out_in_unit_flow, min_ratio_out_in_unit_flow)
	) || any(
		ratio(unit=u, node1=n_from, node2=n_to, _strict=false) !== nothing
		for ratio in (fix_ratio_in_out_unit_flow, max_ratio_in_out_unit_flow, min_ratio_in_out_unit_flow)
	) || unit_incremental_heat_rate(unit=u, node1=n_from, node2=n_to, _strict=false) !== nothing
end

function _connection_issue(c)
	parameters = (connection_capacity, connection_flow_cost)
	node_from_has_cap_or_cost = _has_cap_or_cost(connection__from_node(connection=c, _compact=false), parameters)
	node_to_has_cap_or_cost = _has_cap_or_cost(connection__to_node(connection=c, _compact=false), parameters)
	for (n_from, has_cap_or_cost_from) in node_from_has_cap_or_cost
		has_cap_or_cost_from || any(
			has_cap_or_cost_to && _are_connection_flows_related(u, n_from, n_to)
			for (n_to, has_cap_or_cost_to) in node_to_has_cap_or_cost
		) || "flow from $n_from is unbounded"
	end
	for (n_to, has_cap_or_cost_to) in node_to_has_cap_or_cost
		has_cap_or_cost_to || any(
			has_cap_or_cost_from && _are_connection_flows_related(u, n_from, n_to)
			for (n_from, has_cap_or_cost_from) in node_from_has_cap_or_cost
		) || return "flow to $n_to is unbounded"
	end
end

function _are_connection_flows_related(u, n_from, n_to)
	any(
		ratio(unit=u, node1=n_to, node2=n_from, _strict=false) !== nothing
		for ratio in (
			fix_ratio_out_in_connection_flow, max_ratio_out_in_connection_flow, min_ratio_out_in_connection_flow
		)
	)
end
