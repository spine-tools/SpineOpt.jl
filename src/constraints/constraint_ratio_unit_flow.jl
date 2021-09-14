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
    add_constraint_ratio_unit_flow!(m, ratio, sense, d1, d2)

Ratio of `unit_flow` variables.

Note that the `<sense>_ratio_<directions>_unit_flow` parameter uses the stochastic dimensions of the second
<direction>!
"""
function add_constraint_ratio_unit_flow!(m::Model, ratio, units_on_coefficient, sense, d1, d2)
    @fetch unit_flow, units_on = m.ext[:variables]
    t0 = _analysis_time(m)
    m.ext[:constraints][ratio.name] = Dict(
        (unit=u, node1=ng1, node2=ng2, stochastic_path=s, t=t) => sense_constraint(
            m,
            + expr_sum(
                unit_flow[u, n1, d1, s, t_short] * duration(t_short) for (u, n1, d1, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=ng1,
                    direction=d1,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ),
            sense,
            + expr_sum(
                unit_flow[u, n2, d2, s, t_short]
                * duration(t_short)
                * ratio[(unit=u, node1=ng1, node2=ng2, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, n2, d2, s, t_short) in unit_flow_indices(
                    m;
                    unit=u,
                    node=ng2,
                    direction=d2,
                    stochastic_scenario=s,
                    t=t_in_t(m; t_long=t),
                );
                init=0,
            ) + expr_sum(
                units_on[u, s, t1]
                * min(duration(t1), duration(t))
                * units_on_coefficient[(unit=u, node1=ng1, node2=ng2, stochastic_scenario=s, analysis_time=t0, t=t)]
                for (u, s, t1) in units_on_indices(m; unit=u, stochastic_scenario=s, t=t_overlaps_t(m; t=t));
                init=0,
            ),
        ) for (u, ng1, ng2, s, t) in constraint_ratio_unit_flow_indices(m, ratio, d1, d2)
    )
end

"""
    add_constraint_fix_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        fix_ratio_out_in_unit_flow,
        fix_units_on_coefficient_out_in,
        ==,
        direction(:to_node),
        direction(:from_node),
    )
end

"""
    add_constraint_max_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        max_ratio_out_in_unit_flow,
        max_units_on_coefficient_out_in,
        <=,
        direction(:to_node),
        direction(:from_node),
    )
end

"""
    add_constraint_min_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_out_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        min_ratio_out_in_unit_flow,
        min_units_on_coefficient_out_in,
        >=,
        direction(:to_node),
        direction(:from_node),
    )
end

"""
    add_constraint_fix_ratio_in_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        fix_ratio_in_in_unit_flow,
        fix_units_on_coefficient_in_in,
        ==,
        direction(:from_node),
        direction(:from_node),
    )
end

"""
    add_constraint_max_ratio_in_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        max_ratio_in_in_unit_flow,
        max_units_on_coefficient_in_in,
        <=,
        direction(:from_node),
        direction(:from_node),
    )
end

"""
    add_constraint_min_ratio_in_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_in_in_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        min_ratio_in_in_unit_flow,
        min_units_on_coefficient_in_in,
        >=,
        direction(:from_node),
        direction(:from_node),
    )
end

"""
    add_constraint_max_ratio_out_in_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        fix_ratio_out_out_unit_flow,
        fix_units_on_coefficient_out_out,
        ==,
        direction(:to_node),
        direction(:to_node),
    )
end

"""
    add_constraint_max_ratio_out_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        max_ratio_out_out_unit_flow,
        max_units_on_coefficient_out_out,
        <=,
        direction(:to_node),
        direction(:to_node),
    )
end

"""
    add_constraint_min_ratio_out_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_out_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        min_ratio_out_out_unit_flow,
        min_units_on_coefficient_out_out,
        >=,
        direction(:to_node),
        direction(:to_node),
    )
end

"""
    add_constraint_fix_ratio_in_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_fix_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        fix_ratio_in_out_unit_flow,
        fix_units_on_coefficient_in_out,
        ==,
        direction(:from_node),
        direction(:to_node),
    )
end

"""
    add_constraint_max_ratio_in_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_max_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        max_ratio_in_out_unit_flow,
        max_units_on_coefficient_in_out,
        <=,
        direction(:from_node),
        direction(:to_node),
    )
end

"""
    add_constraint_min_ratio_in_out_unit_flow!(m::Model)

Call `add_constraint_ratio_unit_flow!` with the appropriate parameter and `directions`.
"""
function add_constraint_min_ratio_in_out_unit_flow!(m::Model)
    add_constraint_ratio_unit_flow!(
        m,
        min_ratio_in_out_unit_flow,
        min_units_on_coefficient_in_out,
        >=,
        direction(:from_node),
        direction(:to_node),
    )
end

function constraint_ratio_unit_flow_indices(m::Model, ratio, d1, d2)
    unique(
        (unit=u, node1=n1, node2=n2, stochastic_path=path, t=t)
        for (u, n1, n2) in indices(ratio) for t in t_lowest_resolution(
            x.t for x in unit_flow_indices(m; unit=u, node=Iterators.flatten((members(n1), members(n2))))
        ) for path in active_stochastic_paths(
            unique(ind.stochastic_scenario for ind in _constraint_ratio_unit_flow_indices(m, u, n1, d1, n2, d2, t)),
        )
    )
end

"""
    constraint_ratio_unit_flow_indices_filtered(m::Model, ratio, d1, d2; filtering_options...)

Form the stochastic indexing Array for the `:ratio_unit_flow` constraint for the desired `ratio` and direction pair
`d1` and `d2`.

Uses stochastic path indices due to potentially different stochastic structures between `unit_flow` and
`units_on` variables. Keyword arguments can be used to filter the resulting Array.
"""
function constraint_ratio_unit_flow_indices_filtered(
    m::Model,
    ratio,
    d1,
    d2;
    unit=anything,
    node1=anything,
    node2=anything,
    stochastic_path=anything,
    t=anything,
)
    f(ind) = _index_in(ind; unit=unit, node1=node1, node2=node2, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_ratio_unit_flow_indices(m, ratio, d1, d2))
end

"""
    _constraint_ratio_unit_flow_indices(unit, node1, direction1, node2, direction2, t)

Gather the indices of the relevant `unit_flow` and `units_on` variables.
"""
function _constraint_ratio_unit_flow_indices(m, unit, node1, direction1, node2, direction2, t)
    Iterators.flatten((
        unit_flow_indices(m; unit=unit, node=node1, direction=direction1, t=t_in_t(m; t_long=t)),
        unit_flow_indices(m; unit=unit, node=node2, direction=direction2, t=t_in_t(m; t_long=t)),
        units_on_indices(m; unit=unit, t=t_in_t(m; t_long=t)),
    ))
end
