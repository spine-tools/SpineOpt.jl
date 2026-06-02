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
        sum( # Fixed costs for units.
            + capacity_per_unit(m; unit=u, node=ng, direction=d, stochastic_scenario=s, t=t)
            * fom_cost(m; unit=u, stochastic_scenario=s, t=t)
            * (
                + existing_units(m; unit=u, stochastic_scenario=s, t=t, _default=_default_nb_of_units(u))
                + _get_units_invested_available(m, u, s, t)
                # Default value of `existing_units` is 1 in the template: assumption for non-investable units.
                # For investable unit, we assume the `existing_units`=0 (existing ones) unless explicitly specified.
            )
            * (
                !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
                unit_discounted_duration[(unit=u, stochastic_scenario=s, t=t)] * discounted_duration_base(t) : 
                duration(t)
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
            for (u, ng, d) in indices(capacity_per_unit; unit=indices(fom_cost))
            for (u, s, t) in Iterators.flatten(
                is_candidate(unit=u) ? 
                (units_invested_available_indices(m; unit=u, t=t_range),) :
                (
                    ((u, s, t) for (u, _n, _d, s, t) in unit_flow_indices(m; unit=u, node=ng, direction=d, t=t_range)),
                )
            );
            init=0, # No fixed costs if none defined.
        )
        + sum( # Fixed costs for connections. (Mimicks the above unit costs)
            capacity_per_connection(m; connection=conn, node=ng, direction=d, stochastic_scenario=s, t=t)
            * _connection_fixed_costs_per_duration_unit(m, conn, s, t)
            * (
                existing_connections(
                    m; connection=conn, stochastic_scenario=s, t=t, _default=_default_nb_of_connections(conn)
                )
                + _get_connections_invested_available(m, conn, s, t)
            )
            * (
                !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
                connection_discounted_duration[
                    (connection=conn, stochastic_scenario=s, t=t)
                ] * discounted_duration_base(t) : 
                duration(t)
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * (
                is_candidate(connection=conn) ? 
                connection_stochastic_scenario_weight(m; connection=conn, stochastic_scenario=s) : 
                node_stochastic_scenario_weight(m; node=ng, stochastic_scenario=s)
            )
            for (conn, ng, d) in indices(capacity_per_connection; connection=indices(connection_fixed_annual_cost))
            for (conn, s, t) in Iterators.flatten(
                is_candidate(connection=conn) ? 
                (connections_invested_available_indices(m; connection=conn, t=t_range),) :
                (
                    ((conn, s, t) for (conn, _n, _d, s, t) in connection_flow_indices(
                        m; connection=conn, node=ng, direction=d, t=t_range
                    )),
                )
            );
            init=0, # No fixed costs if none defined.
        )
        + sum( # Fixed costs for storages. (Mimicks the above unit costs)
            node_state_capacity(m; node=n, stochastic_scenario=s, t=t)
            * _storage_fixed_costs_per_duration_unit(m, n, s, t)
            * (
                existing_storages(m; node=n, stochastic_scenario=s, t=t, _default=_default_nb_of_storages(n))
                + _get_storages_invested_available(m, n, s, t)
            )
            * (
                !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) ?
                node_discounted_duration[(node=n, stochastic_scenario=s, t=t)] * discounted_duration_base(t) : 
                duration(t)
            )
            * prod(weight(temporal_block=blk) for blk in blocks(t))
            * node_stochastic_scenario_weight(m; node=n, stochastic_scenario=s)
            for n in indices(storage_fixed_annual_cost)
            for (n, s, t) in (
                is_candidate(node=n) ?
                storages_invested_available_indices(m; node=n, t=t_range) :
                node_stochastic_time_indices(m; node=n, t=t_range)
            );
            init=0, # No fixed costs if none defined.
        )
    )
end
#TODO: scenario tree?

function _fixed_costs_annual_duration(m::Model, t::TimeSlice)::Union{Hour, Minute}
    # Currently, SpineOpt only allows `hour` and `minute`, 
    # see `duration_unit` in the template (`spineopt_template.json`).
    dur_unit = _model_duration_unit(m) 
    # Assumption: start(t) for the year base
    annual_duration = dt_fixed_duration(Year(1), start(t) |> Dates.year |> DateTime, Val(:forward))
    return dur_unit(annual_duration)
end

function _connection_fixed_costs_per_duration_unit(m::Model, conn, s, t)
    return (
        connection_fixed_annual_cost(connection=conn, stochastic_scenario=s, t=t)
        / _fixed_costs_annual_duration(m, t).value
    )
end

function _storage_fixed_costs_per_duration_unit(m::Model, n, s, t)
    return (
        storage_fixed_annual_cost(node=n, stochastic_scenario=s, t=t)
        / _fixed_costs_annual_duration(m, t).value
    )
end