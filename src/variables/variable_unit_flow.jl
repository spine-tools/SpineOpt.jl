#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
    unit_flow_indices(
        unit=anything,
        node=anything,
        direction=anything,
        s=anything
        t=anything
    )

A list of `NamedTuple`s corresponding to indices of the `unit_flow` variable where the keyword arguments act as filters
for each dimension.
"""
function unit_flow_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
#=
    rc = get!(m.ext, :unit_flow_indices) do
        ef = select(
            join_temporal_stochastic_indices(
                m, innerjoin(unit__node__direction__temporal_block(), node__stochastic_structure(); on=:node)
            ),
            [:unit, :node, :direction, :stochastic_scenario, :t, :temporal_block];
            copycols=false,
        )
        RelationshipClass(
            :unit_flow_indices,
            [:unit, :node, :direction, :stochastic_scenario, :t, :temporal_block],
            ef.df,
        )
    end
    unit = members(unit)
    node = members(node)
    return rc(;
        unit=unit,
        node=node,
        direction=direction,
        stochastic_scenario=stochastic_scenario,
        t=t,
        temporal_block=temporal_block,
        _compact=false,
    )
=#
    unit = members(unit)
    node = members(node)
    select(
        join_temporal_stochastic_indices(
            m,
            innerjoin(
                unit__node__direction__temporal_block(
                    unit=unit, node=node, direction=direction, temporal_block=temporal_block, _compact=false
                ),
                node__stochastic_structure(node=node, _compact=false);
                on=:node,
            );
            stochastic_scenario=stochastic_scenario,
            t=t,
            temporal_block=temporal_block,
        ),
        [:unit, :node, :direction, :stochastic_scenario, :t];
        copycols=false,
    )  # FIXME: join with members of temporal_block, as in master
end

function unit_flow_time_indices(
    m::Model;
    unit=anything,
    node=anything,
    direction=anything,
    t=anything,
    temporal_block=temporal_block(representative_periods_mapping=nothing),
)
    unit = members(unit)
    node = members(node)
    unique(
        (unit=u, node=n, direction=d, stochastic_scenario=s, t=t)
        for (u, n, d, tb) in unit__node__direction__temporal_block(
            unit=unit, node=node, direction=direction, temporal_block=temporal_block, _compact=false
        )
        for (n, t) in node_time_indices(m; node=n, temporal_block=tb, t=t)
    )
end

"""
    add_variable_unit_flow!(m::Model)

Add `unit_flow` variables to model `m`.
"""
function add_variable_unit_flow!(m::Model)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :unit_flow,
        unit_flow_indices;
        lb=min_unit_flow,
        fix_value=fix_unit_flow,
        initial_value=initial_unit_flow,
        non_anticipativity_time=unit_flow_non_anticipativity_time,
        non_anticipativity_margin=unit_flow_non_anticipativity_margin,
    )
end
