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
    add_constraint_min_node_pressure!(m::Model)

Limit the minimum value of a `node_pressure` variable to be below `min_node_pressure`, if it exists.
"""
function add_constraint_min_node_pressure!(m::Model)
    @fetch node_pressure = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][:min_node_pressure] = Dict(
        (node=ng, stochastic_scenario=s, t=t) => @constraint(
            m,
            + expr_sum(
                + node_pressure[ng, s, t]
                for (ng, s, t) in node_pressure_indices(m; node=ng, stochastic_scenario=s, t=t);
                init=0,
            )
            >=
            + min_node_pressure[(node=ng, stochastic_scenario=s, analysis_time=t0, t=t)]
        ) for (ng, s, t) in constraint_min_node_pressure_indices(m)
    )
end

function constraint_min_node_pressure_indices(m::Model)
    unique(
        (node=ng, stochastic_path=path, t=t)
        for (ng, s, t) in node_pressure_indices(m; node=indices(min_node_pressure)) for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in node_pressure_indices(m; node=ng, t=t)),
        )
    )
end

"""
    constraint_min_node_pressure_indices_filtered(m::Model; filtering_options...)

Form the stochastic index array for the `:min_node_pressure` constraint.

Uses stochastic path indices of the `node_pressure` variables. Keyword arguments can be used to filter the resulting
"""
function constraint_min_node_pressure_indices_filtered(m::Model; node=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_min_node_pressure_indices(m))
end
