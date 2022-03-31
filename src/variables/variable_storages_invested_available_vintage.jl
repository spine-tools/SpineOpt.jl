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
    storages_invested_available_vintage_indices(storage=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `storages_invested_available` variable where
the keyword arguments act as filters for each dimension.
"""
function storages_invested_available_vintage_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t_vintage=anything,
    t=anything,
    temporal_block=anything,
)
    node = members(node)
    unique([
        (node=n, stochastic_scenario=s, t_vintage=t_v, t=t)
        for (n, tb) in node__investment_temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for (n, s, t_v) in node_investment_stochastic_time_indices(
            m;
            node=n,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t_vintage,
        )
        for (n, s, t) in node_investment_stochastic_time_indices(
            m;
            node=n,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t,
        )
        if t >= t_v
    ])
end

"""
    fix_initial_storages_invested_available_vintage()

If fix_storages_invested_available_vintage is not defined in the timeslice preceding the first rolling window
then force it to be zero so that the model doesn't get free investments and the user isn't forced
to consider this.
"""
function fix_initial_storages_invested_available_vintage(m)
    for n in indices(candidate_storages)
        t = last(history_time_slice(m))
        t_v = last(history_time_slice(m))
        if fix_storages_invested_available(node=n, t_vintage=t_v, t=t, _strict=false) === nothing
            node.parameter_values[n][:fix_storages_invested_available_vintage] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
            node.parameter_values[n][:starting_fix_storages_invested_available_vintage] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
        end
    end
end

"""
    add_variable_nodes_invested_available_vintage!(m::Model)

Add `storages_invested_available` variables to model `m`.
"""
function add_variable_storages_invested_available_vintage!(m::Model)
    # fix_initial_storages_invested_available_vintage(m)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :storages_invested_available_vintage,
        storages_invested_available_vintage_indices;
        lb=x -> 0,
        ub=x -> candidate_storages(node=x.node), #FIXME
        # fix_value=x -> fix_storages_invested_available_vintage(
        #     node=x.node,
        #     stochastic_scenario=x.stochastic_scenario,
        #     analysis_time=t0,
        #     t=x.t,
        #     t_vintage=x.t_vintage,
        #     _strict=false,
        # ),
        vintage=true,
    )
end
