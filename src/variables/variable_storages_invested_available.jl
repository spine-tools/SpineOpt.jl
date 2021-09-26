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
    storages_invested_available_indices(node=anything, t=anything)

A list of `NamedTuple`s corresponding to indices of the `storagess_invested_available` variable where
the keyword arguments act as filters for each dimension.
"""
function storages_invested_available_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    t=anything,
    temporal_block=anything,
)
    [
        (node=n, stochastic_scenario=s, t=t)
        for (n, tb) in node__investment_temporal_block(node=node, temporal_block=temporal_block, _compact=false)
        for (n, s, t) in node_investment_stochastic_time_indices(
            m;
            node=n,
            stochastic_scenario=stochastic_scenario,
            temporal_block=tb,
            t=t,
        )
    ]
end

"""
    storages_invested_available_int(x)

Check if storage investment variable type is defined to be an integer.
"""

storages_invested_available_int(x) = storage_investment_variable_type(node=x.node) == :variable_type_integer

"""
    fix_initial_storages_invested_available()

If fix_storages_invested_available is not defined in the timeslice preceding the first rolling window
then force it to be zero so that the model doesn't get free investments and the user isn't forced
to consider this.
"""
function fix_initial_storages_invested_available(m)
    for n in indices(candidate_storages)
        t = last(history_time_slice(m))
        if fix_storages_invested_available(node=n, t=t, _strict=false) === nothing
            node.parameter_values[n][:fix_storages_invested_available] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
            node.parameter_values[n][:starting_fix_storages_invested_available] = parameter_value(
                TimeSeries([start(t)], [0], false, false),
            )
        end
    end
end

"""
    add_variable_storages_invested_available!(m::Model)

Add `storages_invested_available` variables to model `m`.
"""
function add_variable_storages_invested_available!(m::Model)
    # fix storages_invested_available to zero in the timestep before the investment window to prevent "free" investments
    fix_initial_storages_invested_available(m)
    t0 = _analysis_time(m)
    add_variable!(
        m,
        :storages_invested_available,
        storages_invested_available_indices;
        lb=x -> 0,
        int=storages_invested_available_int,
        fix_value=x -> fix_storages_invested_available(
            node=x.node,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
    )
end
