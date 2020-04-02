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

# NOTE: these `MissingItemHandler`s come into play whenever the database is missing some of the stuff
# SpineModel expects to find in there.
# The above can happen (i) during development, as we introduce new symbols for novel functionality, and
# (ii) in production, if the user 'accidentally' deletes something.
# I believe SpineModel needs this kind of safeguards to be robust.
# As things stabilize, we should see a correspondance between this
# and what we find in `spinedb_api.create_new_spine_database(for_spine_model=True)`

"""
A type to handle missing db items.
"""
struct MissingItemHandler
    name::Symbol
    value::Any
    handled::Ref{Bool}
    MissingItemHandler(name, value) = new(name, value, false)
end

function (item::MissingItemHandler)(args...; kwargs...)
    if !item.handled[]
        @warn "`$(item.name)` is missing"
        item.handled[] = true
    end
    item.value
end

function SpineInterface.indices(item::MissingItemHandler; kwargs...)
    if !item.handled[]
        @warn "`$(item.name)` is missing"
        item.handled[] = true
    end
    ()
end

function Base.getproperty(item::MissingItemHandler, prop::Symbol)
    prop in (:name, :value, :handled) && return getfield(item, prop)
    if !item.handled[]
        @warn "`$(item.name)` is missing"
        item.handled[] = true
    end
    []
end

const object_classes = [
    :unit,
    :connection,
    :commodity,
    :node,
    :model,
    :temporal_block,
    :output,
    :report,
]

const relationship_classes = [
    :unit__from_node,
    :unit__to_node,
    :unit__node__node,
    :connection__from_node,
    :connection__to_node,
    :connection__node__node,
    :node__commodity,
    :node__node,
    :node__temporal_block,
    :unit_group__unit,
    :commodity_group__commodity,
    :node_group__node,
    :unit_group__commodity_group,
    :commodity_group__node_group,
    :report__output,
]

const parameters = [
    (:model_start, nothing),
    (:model_end, nothing),
    (:duration_unit, :minute),
    (:roll_forward, nothing),
    (:block_start, nothing),
    (:block_end, nothing),
    (:resolution, nothing),
    (:fom_cost, nothing),
    (:start_up_cost, nothing),
    (:shut_down_cost, nothing),
    (:number_of_units, nothing),
    (:unit_availability_factor, nothing),
    (:min_down_time, nothing),
    (:min_up_time, nothing),
    (:online_variable_type, nothing),
    (:fix_units_on, nothing),
    (:demand, nothing),
    (:state_coeff, 0),
    (:has_state, nothing),
    (:node_state_cap, nothing),
    (:node_state_min, 0),
    (:frac_state_loss, 0),
    (:diff_coeff, 0),
    (:unit_conv_cap_to_flow, nothing),
    (:unit_capacity, nothing),
    (:connection_capacity, nothing),
    (:connection_conv_cap_to_flow, nothing),
    (:connection_availability_factor, nothing),
    (:operating_cost, nothing),
    (:vom_cost, nothing),
    (:tax_net_unit_flow, nothing),
    (:tax_out_unit_flow, nothing),
    (:tax_in_unit_flow, nothing),
    (:fix_ratio_out_in_unit_flow, nothing),
    (:fix_ratio_in_in_unit_flow, nothing),
    (:fix_ratio_out_out_unit_flow, nothing),
    (:max_ratio_out_in_unit_flow, nothing),
    (:max_ratio_in_in_unit_flow, nothing),
    (:max_ratio_out_out_unit_flow, nothing),
    (:min_ratio_out_in_unit_flow, nothing),
    (:min_ratio_in_in_unit_flow, nothing),
    (:min_ratio_out_out_unit_flow, nothing),
    (:fix_ratio_out_in_connection_flow, nothing),
    (:fix_ratio_in_in_connection_flow, nothing),
    (:fix_ratio_out_out_connection_flow, nothing),
    (:max_ratio_out_in_connection_flow, nothing),
    (:max_ratio_in_in_connection_flow, nothing),
    (:max_ratio_out_out_connection_flow, nothing),
    (:min_ratio_out_in_connection_flow, nothing),
    (:min_ratio_in_in_connection_flow, nothing),
    (:min_ratio_out_out_connection_flow, nothing),
    (:minimum_operating_point, nothing),
    (:max_cum_in_unit_flow_bound, nothing),
    (:fix_unit_flow, nothing),
    (:fix_connection_flow, nothing),
    (:fix_node_state, nothing),
    (:output_db_url, nothing),
    (:horizon_start_datetime, 0),
    (:horizon_end_datetime, 0),
    (:initial_condition_duration, 0),
    (:reoptimization_frequency, 0),
    (:rolling_window_duration, 0),
    (:fuel_cost, nothing),
    (:connection_flow_delay, Second(0)),
]

for name in [object_classes; relationship_classes]
    quoted_name = Expr(:quote, name)
    @eval $name = MissingItemHandler($quoted_name, ())
end
for (name, default) in parameters
    quoted_name = Expr(:quote, name)
    @eval $name = MissingItemHandler($quoted_name, $default)
end
