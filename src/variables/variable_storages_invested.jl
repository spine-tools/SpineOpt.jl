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
    storages_invested_int(x)

Check if node investment variable type is defined to be an integer.
"""

storages_invested_int(x) = storage_investment_variable_type(node=x.node) == :storage_investment_variable_type_integer

"""
    fix_initial_storages_invested()

If fix_storages_invested_available is not defined in the timeslice preceding the first rolling window
then force it to be zero so that the model doesn't get free investments and the user isn't forced
to consider this.
"""
function fix_initial_storages_invested(m)
    for n in indices(candidate_storages) #FIXME: needs to also have investment temporal block
        t = history_time_slice(m; temporal_block=node__investment_temporal_block(node=n))
        if fix_storages_invested(node=n, t=last(t), _strict=false) === nothing
            node.parameter_values[n][:fix_storages_invested] = parameter_value(
                TimeSeries(start.(t), zeros(length(start.(t))), false, false),
            )
            node.parameter_values[n][:starting_fix_storages_invested] = parameter_value(
                TimeSeries(start.(t), zeros(length(start.(t))), false, false),
            )
        end
    end
end

"""
    add_variable_storages_invested!(m::Model)

Add `storages_invested` variables to model `m`.
"""
function add_variable_storages_invested!(m::Model)
    t0 = _analysis_time(m)
    fix_initial_storages_invested(m)
    add_variable!(
        m,
        :storages_invested,
        storages_invested_available_indices;
        lb=x -> 0,
        fix_value=x -> fix_storages_invested(
            node=x.node,
            stochastic_scenario=x.stochastic_scenario,
            analysis_time=t0,
            t=x.t,
            _strict=false,
        ),
        int=storages_invested_int,
    )
end
