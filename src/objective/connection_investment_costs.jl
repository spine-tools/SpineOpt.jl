#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    connection_investment_costs(m::Model)

Create and expression for connection investment costs.
"""
function connection_investment_costs(m::Model, t_range)
    @fetch connections_invested = m.ext[:spineopt].variables
    connection = indices(connection_investment_cost)
    @expression(
        m,
        + sum(
            connections_invested[c, s, t]
            * _connection_weight_for_multiyear_economic_discounting(m; c, s, t)
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * connection_investment_cost(m; connection=c, stochastic_scenario=s, t=t)
            * connection_stochastic_scenario_weight(m; connection=c, stochastic_scenario=s)
            for (c, s, t) in connections_invested_available_indices(m; connection=connection, t=t_range);
            init=0,
        )
    )
end

function _connection_weight_for_multiyear_economic_discounting(m; c, s, t)
    if !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance))
        return (1- connection_salvage_fraction[(connection=c, stochastic_scenario=s, t=t)]) * 
                connection_tech_discount_factor[(connection=c, stochastic_scenario=s, t=t)] * 
                connection_conversion_to_discounted_annuities[(connection=c, stochastic_scenario=s, t=t)]
    else
        return 1
    end
end
