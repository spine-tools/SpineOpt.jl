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
    variable_stor_state(m::Model)

A `stor_level` variable for each tuple returned by `commodity__stor()`,
attached to model `m`.
`stor_level` represents the state of the storage level.
"""
function variable_stor_state(m::Model)
    KeyType = NamedTuple{(:storage, :commodity, :t),Tuple{Object,Object,TimeSlice}}
    m.ext[:variables][:var_stor_state] = Dict{KeyType,Any}(
        (storage=stor, commodity=c, t=t) => @variable(
            m, base_name="stor_state[$stor, $c, $(t.JuMP_name)]", lower_bound=0
        ) for (stor, c, t) in var_stor_state_indices()
    )
    m.ext[:variables][:fix_stor_state] = Dict{KeyType,Any}(
        (storage=stor, commodity=c, t=t) => fix_stor_state(storage=stor, t=t)
        for (stor, c, t) in fix_stor_state_indices()
    )
    m.ext[:variables][:stor_state] = merge(
        m.ext[:variables][:var_stor_state],
        m.ext[:variables][:fix_stor_state]
    )
end


"""
    stor_state_indices(filtering_options...)

A set of tuples for indexing the `stor_state` variable. Any filtering options can be specified
for `storage`, `commodity`, and `t`.
Tuples are generated for the highest resolution 'flows' or 'trans' of the involved commodity.
"""
function stor_state_indices(;storage=anything, commodity=anything, t=anything)
    [
        var_stor_state_indices(storage=storage, commodity=commodity, t=t);
        fix_stor_state_indices(storage=storage, commodity=commodity, t=t)
    ]
end

function var_stor_state_indices(;storage=anything, commodity=anything, t=anything)
    [
        [
            (storage=stor, commodity=c, t=t1)
            for u in storage__unit(storage=storage)
                for (stor, c) in storage__commodity(storage=storage, commodity=commodity, _compact=false)
                    for t1 in t_highest_resolution(
                            unique(t2 for (conn, n, c, d, t2) in flow_indices(unit=u, commodity=c, t=t))
                        )
        ];
        [
            (storage=stor, commodity=c, t=t1)
            for conn in storage__connection(storage=storage)
                for (stor, c) in storage__commodity(storage=storage, commodity=commodity, _compact=false)
                    for t1 in t_highest_resolution(
                            unique(t2 for (conn, n, c, d, t2) in trans_indices(connection=conn, commodity=c, t=t))
                        )
        ]
    ]
end

function fix_stor_state_indices(;storage=anything, commodity=anything, t=anything)
    [
        (storage=stor, commodity=c, t=t1)
        for (stor, c) in storage__commodity(storage=storage, commodity=commodity, _compact=false)
            for (stor,) in indices(fix_stor_state; storage=stor)
                    if fix_stor_state(storage=stor) isa TimeSeriesValue
                for t1 in intersect(
                        t_highest_resolution(
                            [
                                t for s in time_stamps(fix_stor_state(storage=stor))
                                    for t in time_slice() if t.start <= s < t.end_
                            ]
                        ),
                        t
                    )
    ]
end
