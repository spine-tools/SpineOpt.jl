#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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

"""
    add_constraint_ratio_unit_flow!(m, ratio, sense, d1, d2)

Ratio of `unit_flow` variables.
"""
function add_constraint_ratio_unit_flow!(m::Model, ratio, units_on_coefficient, sense, d1, d2)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][ratio.name] = Dict()
    for (u, n1, n2) in indices(ratio)
        for t in t_lowest_resolution(x.t for x in unit_flow_indices(unit=u, node=[n1, n2]))
            cons[u, n1, n2, t] = sense_constraint(
                m,
                + expr_sum(
                    unit_flow[u, n1, d1, t_short] * duration(t_short)
                    for (u, n1, d1, t_short) in unit_flow_indices(
                        unit=u, node=n1, direction=d1, t=t_in_t(t_long=t)
                    );
                    init=0
                )
                ,
                sense,
                + ratio[(unit=u, node1=n1, node2=n2, t=t)]
                * expr_sum(
                    unit_flow[u, n2, d2, t_short] * duration(t_short)
                    for (u, n2, d2, t_short) in unit_flow_indices(
                        unit=u, node=n2, direction=d2, t=t_in_t(t_long=t)
                    );
                    init=0
                )
                + units_on_coefficient[(unit=u, node1=n1, node2=n2, t=t)]
                * expr_sum(
                    units_on[u, t_short] * duration(t_short)
                    for (u, t_short) in units_on_indices(unit=u, t=t_in_t(t_long=t));
                    init=0
                ),

            )
        end
    end
end

function add_constraint_fix_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_out_in_unit_flow, fix_units_on_coefficient_out_in, ==, direction(:to_node), direction(:from_node)
    )
end
function add_constraint_max_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_out_in_unit_flow, max_units_on_coefficient_out_in, <=, direction(:to_node), direction(:from_node)
    )
end
function add_constraint_min_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_out_in_unit_flow, min_units_on_coefficient_out_in, >=, direction(:to_node), direction(:from_node)
    )
end
function add_constraint_fix_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_in_in_unit_flow, fix_units_on_coefficient_in_in, ==, direction(:from_node), direction(:from_node)
    )
end
function add_constraint_max_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_in_in_unit_flow, max_units_on_coefficient_in_in, <=, direction(:from_node), direction(:from_node)
    )
end
function add_constraint_fix_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_out_out_unit_flow, fix_units_on_coefficient_out_out, ==, direction(:to_node), direction(:to_node)
    )
end
function add_constraint_max_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_out_out_unit_flow, max_units_on_coefficient_out_out, <=, direction(:to_node), direction(:to_node)
    )
end
function add_constraint_fix_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, fix_ratio_in_out_unit_flow, fix_units_on_coefficient_in_out, ==, direction(:from_node), direction(:to_node)
    )
end
function add_constraint_max_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, max_ratio_in_out_unit_flow, max_units_on_coefficient_in_out, <=, direction(:from_node), direction(:to_node)
    )
end
function add_constraint_min_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m, min_ratio_in_out_unit_flow, min_units_on_coefficient_in_out, >=, direction(:from_node), direction(:to_node)
    )
end
