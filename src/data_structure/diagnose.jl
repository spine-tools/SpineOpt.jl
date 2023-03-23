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

# NOTE: I see some small problem here, related to doing double work.
# For example, checking that the stochastic dags have no loops requires to generate those dags,
# but we can't generate them just for checking and then throw them away, can we?
# So I propose we do that type of checks when we actually generate the corresponding structure.
# And here, we just perform simpler checks that can be done directly on the contents of the db,
# and don't require to build any additional structures.

function diagnose_spineopt(url_in; upgrade=false, log_level=3, filters=Dict("tool" => "object_activity_control"))
	prepare_spineopt(url_in; upgrade=upgrade, log_level=log_level, filters=filters)
	_diagnose(node, _node_issue)
	_diagnose(unit, _unit_issue)
end

function _diagnose(class::ObjectClass, issue_fn)
	issues = [string(x, "\t", issue) for (x, issue) in ((x, issue_fn(x)) for x in class()) if issue !== nothing]
	if !isempty(issues)
		@warn string("the following $(class.name) items have issues:\n\t", join(issues, "\n\t"))
	end
end

function _node_issue(n)
	if any(balance_type(node=ng) === :balance_type_group for ng in groups(n))
		return nothing
	end
	if balance_type(node=n) === :balance_type_none
		return "unbalanced - balance_type_none"
	end
end

function _unit_issue(u)
	nodes_from = unit__from_node(unit=u, direction=direction(:from_node))
	isempty(nodes_from) && return "no input flows"
	nodes_to = unit__to_node(unit=u, direction=direction(:to_node))
	isempty(nodes_to) && return "no output flows"
	for n_from in nodes_from
		for n_to in nodes_to
			for ratio in (fix_ratio_out_in_unit_flow, max_ratio_out_in_unit_flow, min_ratio_out_in_unit_flow)
				if ratio(unit=u, node1=n_to, node2=n_from, _strict=false) !== nothing
					return nothing
				end
			end
			for ratio in (fix_ratio_in_out_unit_flow, max_ratio_in_out_unit_flow, min_ratio_in_out_unit_flow)
				if ratio(unit=u, node1=n_fr, node2=n_to, _strict=false) !== nothing
					return nothing
				end
			end
			if unit_incremental_heat_rate(unit=u, node1=n_fr, node2=n_to, _strict=false) !== nothing
				return nothing
			end
		end
	end
	"input and output flows not related"
end
