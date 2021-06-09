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

"""
    add_constraint_min_node_voltage_angle!(m::Model)

Limit the minimum value of a `node_voltage_angle` variable to be above `min_voltage_angle`, if it exists.
"""
function add_constraint_min_node_voltage_angle!(m::Model)
    @fetch node_voltage_angle = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:min_node_voltage_angle] = Dict(
        (node=ng, stochastic_scenario=s, t=t) => @constraint(
            m,
            + expr_sum(
                + node_voltage_angle[ng, s, t]
                for (ng, s, t) in node_voltage_angle_indices(m; node=ng, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            + min_voltage_angle[(node=ng, stochastic_scenario=s, analysis_time=t0, t=t)]
        ) for (ng, s, t) in constraint_min_node_voltage_angle_indices(m)
    )
end

function constraint_min_node_voltage_angle_indices(m::Model)
    unique(
        (node=ng, stochastic_path=path, t=t)
        for (ng, s, t) in node_voltage_angle_indices(m; node=indices(min_voltage_angle))
        for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in node_voltage_angle_indices(m; node=ng, t=t)),
        )
    )
end

"""
    constraint_min_node_voltage_angle_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:min_node_voltage_angle` constraint.

Uses stochastic path indices of the `node_voltage_angle` variables. Keyword arguments can be used to filter the resulting
"""
function constraint_min_node_voltage_angle_indices_filtered(
    m::Model;
    node=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_min_node_voltage_angle_indices(m))
end
