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
        f(unit_capacity; unit=unit, node=node, direction=direction, _default=_default, kwargs...),
        f(unit_availability_factor; unit=unit, kwargs...),
        f(unit_conv_cap_to_flow; unit=unit, node=node, direction=direction, kwargs...),
    )
end

function _connection_flow_capacity(
    f; connection=connection, node=node, direction=direction, _default=nothing, kwargs...
)
    _prod_or_nothing(
        f(connection_capacity; connection=connection, node=node, direction=direction, _default=_default, kwargs...),
        f(connection_availability_factor; connection=connection, kwargs...),
        f(connection_conv_cap_to_flow; connection=connection, node=node, direction=direction, kwargs...),
    )
end

function _connection_flow_lower_limit(
    f; connection=connection, node=node, direction=direction, _default=0, kwargs...
)
    _prod_or_nothing(
        f(connection_capacity; connection=connection, node=node, direction=direction, _default=_default, kwargs...),
        f(connection_min_factor; connection=connection, kwargs...),
        f(connection_conv_cap_to_flow; connection=connection, node=node, direction=direction, kwargs...),
    )
end

function _node_state_capacity(f; node=node, _default=nothing, kwargs...)
    _prod_or_nothing(
        f(node_state_cap; node=node, _default=_default, kwargs...),
        f(node_availability_factor; node=node, kwargs...),
    )
end

function _node_state_lower_limit(f; node=node, _default=0, kwargs...)
    max(
        something(
            _prod_or_nothing(
                f(node_state_cap; node=node, _default=_default, kwargs...),
                f(node_state_min_factor; node=node, kwargs...),
            ),
            0,
        ),
        f(node_state_min; node=node, kwargs...),
    )
end

_prod_or_nothing(args...) = _prod_or_nothing(collect(args))
_prod_or_nothing(args::Vector) = any(isnothing.(args)) ? nothing : *(args...)
_prod_or_nothing(args::Vector{T}) where T<:Call = Call(_prod_or_nothing, args)

const unit_flow_capacity = ParameterFunction(_unit_flow_capacity)
const connection_flow_capacity = ParameterFunction(_connection_flow_capacity)
const connection_flow_lower_limit = ParameterFunction(_connection_flow_lower_limit)
const node_state_capacity = ParameterFunction(_node_state_capacity)
const node_state_lower_limit = ParameterFunction(_node_state_lower_limit)
const current_bi = _make_bi(1)