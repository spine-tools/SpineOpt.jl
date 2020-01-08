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
    create_variable_stor_state!(m::Model)

Add `stor_state` variable to model `m`.
`stor_state` represents the state of the storage level.
"""
function create_variable_stor_state!(m::Model)
    KeyType = NamedTuple{(:storage, :commodity, :t),Tuple{Object,Object,TimeSlice}}
    var = Dict{KeyType,Any}(
        (storage=stor, commodity=c, t=t) => @variable(
            m,
            base_name="stor_state[$stor, $c, $(t.JuMP_name)]",
            lower_bound= stor_state_min(storage=stor)
        )
        for (stor, c, t) in var_stor_state_indices()
    )
    fix = Dict{KeyType,Any}(
        (storage=stor, commodity=c, t=t) => fix_stor_state(storage=stor, t=t)
        for (stor, c, t) in fix_stor_state_indices()
    )
    merge!(get!(m.ext[:variables], :stor_state, Dict{KeyType,Any}()), var, fix)
end

function variable_stor_state_value(m::Model)
    Dict{NamedTuple{(:storage, :commodity, :t),Tuple{Object,Object,TimeSlice}},Any}(
        (storage=stor, commodity=c, t=t) => value(m.ext[:variables][:stor_state][stor, c, t]) 
        for (stor, c, t) in var_stor_state_indices()
    )
end


"""
    stor_state_indices(filtering_options...)

A set of tuples for indexing the `stor_state` variable. Any filtering options can be specified
for `storage`, `commodity`, and `t`.
Tuples are generated for the highest resolution 'flows' or 'trans' of the involved commodity.
"""
function stor_state_indices(;storage=anything, commodity=anything, t=anything)
    unique(
        [
            var_stor_state_indices(storage=storage, commodity=commodity, t=t);
            fix_stor_state_indices(storage=storage, commodity=commodity, t=t)
        ]
    )
end

function var_stor_state_indices(;storage=anything, commodity=anything, t=anything)
    [
        [
            (storage=stor, commodity=c, t=t1)
            for (stor, c) in storage__commodity(storage=storage, commodity=commodity, _compact=false)
            for u in storage__unit(storage=stor)
            for t1 in t_highest_resolution(unique(x.t for x in flow_indices(unit=u, commodity=c, t=t)))
        ];
        [
            (storage=stor, commodity=c, t=t1)
            for (stor, c) in storage__commodity(storage=storage, commodity=commodity, _compact=false)
            for conn in storage__connection(storage=stor)
            for t1 in t_highest_resolution(unique(x.t for x in trans_indices(connection=conn, commodity=c, t=t)))
        ]
    ]
end

function fix_stor_state_indices(;storage=anything, commodity=anything, t=anything)
    [
        (storage=stor, commodity=c, t=t_)
        for (stor,) in indices(fix_stor_state; storage=storage)
        for t_ in current_time_slice(t=t)
        if fix_stor_state(storage=stor, t=t_) != nothing
        for (stor_, c) in storage__commodity(storage=stor, commodity=commodity, _compact=false)
    ]
end
