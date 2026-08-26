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

function _unit_flow_capacity(f; unit=unit, node=node, direction=direction, _default=nothing, kwargs...)
    _prod_or_nothing(
        f(capacity_per_unit; unit=unit, node=node, direction=direction, _default=_default, kwargs...),
        f(availability_factor; unit=unit, kwargs...),
        f(capacity_to_flow_conversion_factor; unit=unit, node=node, direction=direction, kwargs...),
    )
end

function _connection_flow_capacity(
    f; connection=connection, node=node, direction=direction, _default=nothing, kwargs...
)
    _prod_or_nothing(
        f(capacity_per_connection; connection=connection, node=node, direction=direction, _default=_default, kwargs...),
        f(availability_factor; connection=connection, kwargs...),
        f(capacity_to_flow_conversion_factor; connection=connection, node=node, direction=direction, kwargs...),
    )
end

function _connection_flow_lower_limit(
    f; connection=connection, node=node, direction=direction, _default=0, kwargs...
)
    _prod_or_nothing(
        f(capacity_per_connection; connection=connection, node=node, direction=direction, _default=_default, kwargs...),
        f(connection_min_factor; connection=connection, kwargs...),
        f(capacity_to_flow_conversion_factor; connection=connection, node=node, direction=direction, kwargs...),
    )
end

function _node_state_capacity(f; node=node, _default=nothing, kwargs...)
    _prod_or_nothing(
        f(storage_state_max; node=node, _default=_default, kwargs...),
        f(storage_state_max_fraction; node=node, kwargs...),
    )
end

function _node_state_lower_limit(f; node=node, _default=0, kwargs...)
    max(
        something(
            _prod_or_nothing(
                f(storage_state_max; node=node, _default=_default, kwargs...),
                f(storage_state_min_fraction; node=node, kwargs...),
            ),
            0,
        ),
        f(storage_state_min; node=node, kwargs...),
    )
end

_prod_or_nothing(args...) = _prod_or_nothing(collect(args))
_prod_or_nothing(args::Vector) = any(isnothing.(args)) ? nothing : *(args...)
_prod_or_nothing(args::Vector{T}) where T<:Call = Call(_prod_or_nothing, args)

"""
    unit_flow_capacity(f; unit=unit, node=node, direction=direction, _default=nothing, kwargs...)

`ParameterFunction` calculating the capacity of a [unit\\_flow variable](@ref var_unit_flow).

Returns the product of:
* [capacity\\_per\\_unit](@ref)
* [availability\\_factor](@ref)
* [capacity\\_to\\_flow\\_conversion\\_factor](@ref)
each evaluated for `f` with the given `kwargs`.
Returns `nothing` if the product yields nothing.
"""
const unit_flow_capacity = ParameterFunction(_unit_flow_capacity)

"""
    connection_flow_capacity(
        f; connection=connection, node=node, direction=direction, _default=nothing, kwargs...
    )

`ParameterFunction` calculating the capacity of a [connection\\_flow variable](@ref var_connection_flow).

Returns the product of:
* [capacity\\_per\\_connection](@ref)
* [availability\\_factor](@ref)
* [capacity\\_to\\_flow\\_conversion\\_factor](@ref)
each evaluated for `f` with the given `kwargs`.
Returns `nothing` if the product yields nothing.
"""
const connection_flow_capacity = ParameterFunction(_connection_flow_capacity)

"""
    connection_flow_lower_limit(
        f; connection=connection, node=node, direction=direction, _default=0, kwargs...
    )

`ParameterFunction` calculating the lower limit of a [connection\\_flow variable](@ref var_connection_flow).

Returns the product of:
* [capacity\\_per\\_connection](@ref)
* [connection\\_min\\_factor](@ref)
* [capacity\\_to\\_flow\\_conversion\\_factor](@ref)
each evaluated for `f` with the given `kwargs`.
Returns `nothing` if the product yields nothing.
"""
const connection_flow_lower_limit = ParameterFunction(_connection_flow_lower_limit)

"""
    node_state_capacity(f; node=node, _default=nothing, kwargs...)

`ParameterFunction` calculating the capacity of a [node\\_state variable](@ref var_node_state).

Returns the product of:
* [storage\\_state\\_max](@ref)
* [storage\\_state\\_max\\_fraction](@ref)
both evaluated for `f` with the given `kwargs`.
Returns `nothing` if the product yields nothing.
"""
const node_state_capacity = ParameterFunction(_node_state_capacity)

"""
    node_state_lower_limit(f; node=node, _default=0, kwargs...)

`ParameterFunction` calculating the lower limit of a [node\\_state variable](@ref var_node_state).

Returns the product of:
* [storage\\_state\\_max](@ref)
* [storage\\_state\\_min\\_fraction](@ref)
* OR [storage\\_state\\_min](@ref) if it is higher than the above product.
each evaluated for `f` with the given `kwargs`.
Returns `nothing` if the product yields nothing.
"""
const node_state_lower_limit = ParameterFunction(_node_state_lower_limit)
const current_bi = _make_bi(1)