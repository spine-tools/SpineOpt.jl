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
    fixed_om_costs(m)

Create an expression for fixed operation costs of units.
"""
function fixed_om_costs(m, t_range)
    @fetch units_invested_available = m.ext[:spineopt].variables
    @expression(
        m,
        sum(
            + unit_capacity(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * fom_cost(m; unit=u, stochastic_scenario=s, t=t)
            * (
                + number_of_units(m; unit=u, stochastic_scenario=s, t=t, _default=_default_nb_of_units(u))
                + (is_candidate(unit=u) ? units_invested_available[u, s, t] : 0)
                # Default value of `number_of_units` is 1 in the template: assumption for non-investable units.
                # For investable unit, we assume the `number_of_units`=0 (existing ones) unless explicitly specified.
            )
            * (
                !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
                unit_discounted_duration[(unit=u, stochastic_scenario=s, t=t)] * 
                _discounted_duration_coeff_investable_assets(t) : duration(t)
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            # This term is activated when there is a representative temporal block that includes t.
            # We assume only one representative temporal structure available, of which the termporal blocks represent
            # an extended period of time with a weight >=1, e.g. a representative month represents 3 months.
            * (
                is_candidate(unit=u) ? 
                unit_stochastic_scenario_weight(m; unit=u, stochastic_scenario=s) : 
                node_stochastic_scenario_weight(m; node=ng, stochastic_scenario=s)
            )
            for (u, ng, d) in indices(unit_capacity; unit=indices(fom_cost))
            for (u, s, t) in Iterators.flatten(
                is_candidate(unit=u) ? (units_invested_available_indices(m; unit=u, t=t_range),) :
                (
                    ((u, s, t) for (u, _n, _d, s, t) in unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_range)),
                )
            );
            init=0,
        )
    )
end
#TODO: scenario tree?

function _discounted_duration_coeff_investable_assets(t::TimeSlice; _exact=false)
    # In our economic discounting functionality, 1 Year is the base duration for investment (years) and operation.
    # So `unit_discounted_duration` only counts the number (discounted) of years over a multi-year investment period.
    # Hence, the product `unit_discounted_duration` and `duration(t)` is only valid 
    # when the TimeSlice t spans no more than 1 year, otherwise the `unit_discounted_duration` would double-counts
    # the year in a multi-year investment period.
    # Therefore, when the `duration(t)` > 1 Year, 
    # we need this substituting coefficient for `duration(t)` to represent the length (in hour) of 1 Year.

    # We assume the 1st year of the investment period as the base.
    _base_duration = TimeSlice(start(t), start(t)+Year(1)) |> duration
    # average number of years during one investment window period, rounded to integer.
    _number_of_years = div(duration(t), _base_duration, RoundNearest)
    
    # This conditional is irrelevant to whether the asset is investable or not.
    if _number_of_years <= 1
        return duration(t)
    else
        # _exact=true calculates the average length of 1 Year of a multi-year investment period.
        # _exact=false assumes the investment period consists of multiple of the base (1 Year).
        return _exact ? duration(t)/_number_of_years : _base_duration
    end
end