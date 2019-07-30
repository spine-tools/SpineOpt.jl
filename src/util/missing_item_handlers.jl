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

"""
    (f::MissingItemHandler)(args...; kwargs...)

The `value` field of `f`. Warn the user that this is a missing item handler.
"""
function (f::MissingItemHandler)(args...; kwargs...)
    if !f.handled[]
        @warn "`$(f.name)` is missing"
        f.handled[] = true
    end
    f.value
end


function SpineInterface.indices(f::MissingItemHandler; kwargs...)
    if !f.handled[]
        @warn "`$(f.name)` is missing"
        f.handled[] = true
    end
    ()
end

const object_classes = [
    :direction,
    :unit,
    :connection,
    :storage,
    :commodity,
    :node,
    :temporal_block,
    :rolling,
]
const relationship_classes = [
    :unit__node__direction__temporal_block,
    :connection__node__direction__temporal_block,
    :node__commodity,
    :unit_group__unit,
    :commodity_group__commodity,
    :node_group__node,
    :unit_group__commodity_group,
    :commodity_group__node_group,
    :unit__commodity,
    :unit__commodity__direction,
    :unit__commodity__commodity,
    :connection__node__direction,
    :connection__node__node,
    :node__temporal_block,
    :storage__unit,
    :storage__connection,
    :storage__commodity,
    :report__output,
]
const parameters = [
    (:fom_cost, nothing),
    (:start_up_cost, nothing),
    (:shut_down_cost, nothing),
    (:number_of_units, nothing),
    (:avail_factor, nothing),
    (:min_down_time, nothing),
    (:min_up_time, nothing),
    (:start_datetime, nothing),
    (:end_datetime, nothing),
    (:time_slice_duration, nothing),
    (:demand, nothing),
    (:online_variable_type, nothing),
    (:fix_units_on, nothing),
    (:state_coeff, nothing),
    (:stor_state_cap, nothing),
    (:stor_state_min, nothing),
    (:frac_state_loss, nothing),
    (:diff_coeff, nothing),
    (:unit_conv_cap_to_flow, nothing),
    (:unit_capacity, nothing),
    (:conn_capacity, nothing),
    (:operating_cost, nothing),
    (:vom_cost, nothing),
    (:tax_net_flow, nothing),
    (:tax_out_flow, nothing),
    (:tax_in_flow, nothing),
    (:fix_ratio_out_in_flow, nothing),
    (:fix_ratio_in_in_flow, nothing),
    (:fix_ratio_out_out_flow, nothing),
    (:max_ratio_out_in_flow, nothing),
    (:max_ratio_in_in_flow, nothing),
    (:max_ratio_out_out_flow, nothing),
    (:min_ratio_out_in_flow, nothing),
    (:min_ratio_in_in_flow, nothing),
    (:min_ratio_out_out_flow, nothing),
    (:fix_ratio_out_in_trans, nothing),
    (:fix_ratio_in_in_trans, nothing),
    (:fix_ratio_out_out_trans, nothing),
    (:max_ratio_out_in_trans, nothing),
    (:max_ratio_in_in_trans, nothing),
    (:max_ratio_out_out_trans, nothing),
    (:min_ratio_out_in_trans, nothing),
    (:min_ratio_in_in_trans, nothing),
    (:min_ratio_out_out_trans, nothing),
    (:minimum_operating_point, nothing),
    (:stor_unit_discharg_eff, nothing),
    (:stor_unit_charg_eff, nothing),
    (:stor_conn_discharg_eff, nothing),
    (:stor_conn_charg_eff, nothing),
    (:max_cum_in_flow_bound, nothing),
    (:fix_flow, nothing),
    (:fix_trans, nothing),
    (:fix_stor_state, nothing),
    (:output_db_url, nothing),
    (:window_start_datetime, 0),
    (:window_end_datetime, 0),
    (:initial_condition_duration, 0),
    (:reoptimization_frequency, 0),
    (:rolling_window_duration, 0),
    (:fuel_cost, nothing),
]
for name in [object_classes; relationship_classes]
    quoted_name = Expr(:quote, name)
    @eval $name = MissingItemHandler($quoted_name, ())
end
for (name, default) in parameters
    quoted_name = Expr(:quote, name)
    @eval $name = MissingItemHandler($quoted_name, $default)
end
