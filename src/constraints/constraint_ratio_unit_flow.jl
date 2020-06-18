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
    constraint_ratio_unit_flow_indices(ratio, d1, d2)

Forms the stochastic index set for the `:ratio_unit_flow` constraint for the
desired `ratio` and direction pair `d1` and `d2`. Uses stochastic path indices
due to potentially different stochastic structures between `unit_flow` and
`units_on` variables.
"""
function constraint_ratio_unit_flow_indices(ratio, d1, d2)
    ratio_unit_flow_indices = []
    for (u, ng1, ng2) in indices(ratio)
        for t in t_lowest_resolution(x.t for x in unit_flow_indices(unit=u, node=[ng1, ng2]))
            #NOTE: we're assuming that the ratio constraint follows the resolution of flows
            # Ensure type stability
            active_scenarios = Array{Object,1}()
            # `unit_flow` for `direction` `d1`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    unit_flow_indices(unit=u, node=ng1, direction=d1, t=t_in_t(t_long=t))
                )
            )
            # `unit_flow` for `direction` `d2`
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    unit_flow_indices(unit=u, node=ng2, direction=d2, t=t_in_t(t_long=t))
                )
            )
            # `units_on` with coefficient
            append!(
                active_scenarios,
                map(
                    inds -> inds.stochastic_scenario,
                    units_on_indices(unit=u, t=t_in_t(t_long=t))
                )
            )
            # Find stochastic paths for `active_scenarios`
            unique!(active_scenarios)
            for path in active_stochastic_paths(full_stochastic_paths, active_scenarios)
                push!(
                    ratio_unit_flow_indices,
                    (unit=u, node1=ng1, node2=ng2, stochastic_path=path, t=t_overlaps_t(t))
                )
            end
        end
    end
    return unique!(ratio_unit_flow_indices)
end


"""
    add_constraint_ratio_unit_flow!(m, ratio, sense, d1, d2)

Ratio of `unit_flow` variables.
"""
function add_constraint_ratio_unit_flow!(m::Model, ratio, units_on_coefficient, sense, d1, d2)
    @fetch unit_flow, units_on = m.ext[:variables]
    cons = m.ext[:constraints][ratio.name] = Dict()
    for (u, ng1, ng2, stochastic_path, t) in constraint_ratio_unit_flow_indices(ratio, d1, d2)
        cons[u, ng1, ng2, stochastic_path, t] = sense_constraint(
            m,
            + expr_sum(
                unit_flow[u, n1, d1, s, t_short] * duration(t_short)
                for (u, n1, d1, s, t_short) in unit_flow_indices(
                    unit=u, node=ng1, direction=d1, stochastic_scenario=stochastic_path, t=t_in_t(t_long=t)
                );
                init=0
            )
            ,
            sense,
            + ratio[(unit=u, node1=ng1, node2=ng2, t=t)]
            * expr_sum(
                unit_flow[u, n2, d2, s, t_short] * duration(t_short)
                for (u, n2, d2, s, t_short) in unit_flow_indices(
                    unit=u, node=ng2, direction=d2, stochastic_scenario=stochastic_path, t=t_in_t(t_long=t)
                );
                init=0
            )
            + units_on_coefficient[(unit=u, node1=ng1, node2=ng2, t=t)]
            * expr_sum(
                units_on[u, s, t1] * min(duration(t1), duration(t))
                for (u, s, t1) in units_on_indices(
                    unit=u, stochastic_scenario=stochastic_path, t=t_overlaps_t(t)
                );
                init=0
            ),
        )
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
