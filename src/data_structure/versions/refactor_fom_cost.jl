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
    refactor_fom_cost(db_url, log_level; kwargs...)

Refactor `unit` parameter `fom_cost` to `fixed_annual_cost`,
including renaming the parameter and scaling up the old values into annual values.

The old values are given per `duration_unit` of the `model`, so they are multiplied by the number of hours (8760)
or minutes (525600) in a year. If the models in the database use different duration units,
the values are converted per hour and a warning is logged.
"""
function refactor_fom_cost(db_url, log_level; kwargs...)
    @log log_level 0 "Converting `fom_cost` of `unit` to `fixed_annual_cost`"
    # NOTE: `scale_parameter_value` and `rename_parameter` are defined in `major_upgrade_1.jl`
    dur_units = model_duration_units(db_url)
    dur_unit = length(dur_units) == 1 ? only(dur_units) : "hour"
    if length(dur_units) > 1
        @log log_level 0 string("Warning: the models use different duration units ($(join(sort(collect(dur_units)), ", "))). ",
            "`fom_cost` values are converted per `hour`; please check the values of `fixed_annual_cost` of `unit`.")
    end
    factor = Dates.value(Dict("hour" => Hour, "minute" => Minute)[dur_unit](Day(365)))
    # Scaling happens before renaming so that only the migrated values are scaled,
    # not any values of an already existing (e.g. hand-made) new parameter.
    @log log_level 0 "- Scaling parameter values per $dur_unit by $factor..."
    scale_parameter_value(db_url, "unit", "fom_cost", factor, log_level)
    @log log_level 0 "- Renaming `fom_cost` to `fixed_annual_cost`... "
    rename_parameter(db_url, "unit", "fom_cost", "fixed_annual_cost", "", log_level)
    true
end

# The `duration_unit`s in effect for the models in the database: the explicit values of each model,
# or the default value for models without one. Unknown values are taken as `hour`.
function model_duration_units(db_url)
    pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
        "entity_class_name" => "model", "name" => "duration_unit")
    )
    # NOTE: A missing definition is added with the template default (`hour`) at the end of the migration
    default_unit = isempty(pdef) ? "hour" : _default_value(db_url, pdef)
    # NOTE: SpineOpt falls back to `minute` when `duration_unit` has no value at all
    default_unit = something(default_unit, "minute")
    pvals = run_request(db_url, "call_method", ("get_parameter_value_items",), Dict(
        "entity_class_name" => "model", "parameter_definition_name" => "duration_unit")
    )
    vals = create_dict_from_parameter_value_items(db_url, pvals)
    models = entity_bynames(db_url, "model")
    dur_units = Set(
        string(val) for model in models for (_alt, val) in get(vals, model, [(nothing, default_unit)])
    )
    isempty(dur_units) && push!(dur_units, string(default_unit))
    Set(u in ("hour", "minute") ? u : "hour" for u in dur_units)
end

# The parsed default value of the given parameter definition, resolving a value from a parameter value list
function _default_value(db_url, pdef)
    list_value_id = get(pdef, "list_value_id", nothing)
    isnothing(list_value_id) && return parse_db_value(pdef["default_value"], pdef["default_type"])
    list_value = run_request(db_url, "call_method", ("get_list_value_item",), Dict("id" => list_value_id))
    parse_db_value(list_value["value"], list_value["type"])
end
