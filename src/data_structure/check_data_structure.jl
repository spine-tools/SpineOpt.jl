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

# NOTE: I see some small problem here, related to doing double work.
# For example, checking that the stochastic dags have no loops requires to generate those dags,
# but we can't generate them just for checking and then throw them away, can we?
# So I propose we do that type of checks when we actually generate the corresponding structure.
# And here, we just perform simpler checks that can be done directly on the contents of the db,
# and don't require to build any additional structures.

"""
    _check(cond, err_msg)

Check the conditional `cond` and throws an error with a message `err_msg` if `cond` is `false`.
"""
_check(cond, msg_parts...) = cond || error(msg_parts...)

"""
    _check_warn(cond, err_msg)

Check the conditional `cond` and throws a warning with a message `warn_msg` if `cond` is `false`.
"""
_check_warn(cond, msg_parts...) = cond || @warn string(msg_parts...)

"""
    check_data_structure()

Check if the data structure provided from the db results in a valid model.
"""
function check_data_structure()
    check_temporal_block_object()
    check_node_object()
    check_node__temporal_block()
    check_node__stochastic_structure()
    check_unit__stochastic_structure()
    check_minimum_operating_point_unit_capacity()
    check_branching_before_rolling()
    check_parameter_values()
end

"""
    check_model_object()

Check if at least one `model` object is defined.
"""
function check_model_object()
    _check(!isempty(model()), "`model` object not found - you need a `model` object to run SpineOpt")
end

"""
    check_temporal_block_object()

Check if at least one `temporal_block` is defined.
"""
function check_temporal_block_object()
    _check(
        !isempty(temporal_block()),
        "`temporal_block` object not found - you need at least one `temporal_block` to run SpineOpt",
    )
end

"""
    check_node_object()

Check if at least one `node` is defined.
"""
function check_node_object()
    _check(
        !isempty(node()), "`node` object not found - you need at least one `node` to run a SpineOpt Operations Model"
    )
end

"""
    check_node__temporal_block()

Check that each `node` has at least one `temporal_block` connected to it.
"""
function check_node__temporal_block()
    errors = [n for n in node() if n == members(n) && isempty(node__temporal_block(node=n))]
    _check(
        isempty(errors),
        "missing `node__temporal_block` definition ",
        "for some `node`(s): $(join(errors, ", ", " and ")) - ",
        "each `node` must be related to at least one `temporal_block`",
    )
    warnings = [n for n in node() if n != members(n) && isempty(node__temporal_block(node=n))]
    _check_warn(
        isempty(warnings),
        "missing `node__temporal_block` definition ",
        "for some `node` group(s): $(join(warnings, ", ", " and ")) - ",
        "these `node` groups will only be used for aggregation, ",
        "i.e., there will be no variables and balances associated with them",
    )
end

"""
    check_node__stochastic_structure()

Ensure there's exactly one `stochastic_structure` active per `node`.
"""
function check_node__stochastic_structure()
    errors = [n for n in node() if n == members(n) && length(node__stochastic_structure(node=n)) != 1]
    warnings = [n for n in node() if n != members(n) && length(node__stochastic_structure(node=n)) != 1]
    _check(
        isempty(errors),
        "missing or invalid `node__stochastic_structure` definition ",
        "for some `node`(s): $(join(errors, ", ", " and ")) - ",
        "each `node` must be related to one and only one `stochastic_structure`",
    )
    _check_warn(
        isempty(warnings),
        "missing or invalid `node__stochastic_structure` definition ",
        "for some `node` group(s): $(join(warnings, ", ", " and ")) - ",
        "these `node` groups will only be used for aggregation, ",
        "i.e., there will be no variables and balances associated with them",
    )
end

"""
    check_unit__stochastic_structure()

Ensure there's exactly one `stochastic_structure` active per `unit`.

"""
function check_unit__stochastic_structure()
    errors = [u for u in unit() if u == members(u) && length(units_on__stochastic_structure(unit=u)) != 1]
    _check(
        isempty(errors),
        "missing or invalid `units_on__stochastic_structure` definitions ",
        "for some `unit`(s): $(join(errors, ", ", " and ")) - ",
        "each `unit` must be related to one and only one `stochastic_structure`",
    )
end

"""
    check_minimum_operating_point_unit_capacity()

Check if every defined `minimum_operating_point` parameter has a corresponding `unit_capacity` parameter defined.
"""
function check_minimum_operating_point_unit_capacity()
    error_indices = [
        (u, n, d)
        for (u, n, d) in indices(minimum_operating_point)
        if unit_capacity(unit=u, node=n, direction=d) === nothing
    ]
    _check(
        isempty(error_indices),
        "missing `unit_capacity` value for indices: $(join(error_indices, ", ", " and ")) - ",
        "`unit_capacity` must be specified where `minimum_operating_point` is",
    )
end

"""
    check_branching_before_rolling()

Check that no `stochastic_structure` branches before `roll_forward`.
"""
function check_branching_before_rolling()
    for m in model()
        rf = roll_forward(model=m, i=1, _strict=false)
        isnothing(rf) && continue
        t0 = model_start(model=m)
        for (ss, scen) in indices(stochastic_scenario_end)
            scen_end = stochastic_scenario_end(stochastic_structure=ss, stochastic_scenario=scen)
            cond = isnothing(scen_end) || (t0 + scen_end >= t0 + rf)
            _check(
                cond,
                "invalid branching of `stochastic_structure` $ss before `model` $m rolls - ",
                "please make sure that `stochastic_scenario_end` for `stochastic_scenario` $scen ",
                "is larger than `roll_forward` for `model` $m"
            )
        end
    end
end

function check_parameter_values()
    check_model_start_smaller_than_end()
    check_operating_points()
    check_ramp_parameters()
end

function check_model_start_smaller_than_end()
    for m in indices(model_start)
        _check(model_start(model=m) <= model_end(model=m), "The model start for $m is greater than the model end")
    end
end

function check_operating_points()
    error_indices = [
        (u, n, d)
        for (u, n, d) in indices(minimum_operating_point)
        if !(0 <= minimum_operating_point(unit=u, node=n, direction=d) <= 1)
    ]
    _check(
        isempty(error_indices),
        "minimum operating point has to be between 0 and 1 for $(join(error_indices, ", ", " and ")) "
    )
end

function check_ramp_parameters()
    for param in (ramp_up_limit, ramp_down_limit, start_up_limit, shut_down_limit)
        # value between 0 and 1
        error_indices = [(u, n, d) for (u, n, d) in indices(param) if !(0 < param(unit=u, node=n, direction=d) <= 1)]
        _check(
            isempty(error_indices), "$param has to be between 0 (excl) and 1 for $(join(error_indices, ", ", " and ")) "
        )
    end
    for param in (start_up_limit, shut_down_limit)
        # value greater than minimum_operating_point
        error_indices = [
            (u, n, d)
            for (u, n, d) in intersect(indices(minimum_operating_point), indices(param))
            if minimum_operating_point(unit=u, node=n, direction=d) > param(unit=u, node=n, direction=d)
        ]
        _check(
            isempty(error_indices),
            "$param must be greater or equal than minimum_operating_point for $(join(error_indices, ", ", " and ")) "
        )
    end
end