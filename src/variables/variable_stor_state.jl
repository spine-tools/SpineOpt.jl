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
    stor_state_indices(filtering_options...)

A set of tuples for indexing the `stor_state` variable. Any filtering options can be specified
for `storage`, `commodity`, and `t`.
Tuples are generated for the highest resolution 'flows' or 'trans' of the involved commodity.
"""
function stor_state_indices(;storage=anything, commodity=anything, t=anything)
    NamedTuple{(:storage, :commodity, :t),Tuple{Object,Object,TimeSlice}}[
        [
            (storage=stor, commodity=c, t=t1)
            for (stor, c, u) in unit_stor_state_indices_rc(storage=storage, commodity=commodity, _compact=false)
            for t1 in t_highest_resolution(
                unique(x.t for x in flow_indices(unit=u, commodity=c, t=t))
            )
        ];
        [
            (storage=stor, commodity=c, t=t1)
            for (stor, c, conn) in connection_stor_state_indices_rc(
                storage=storage, commodity=commodity, _compact=false
            )
            for t1 in t_highest_resolution(
                unique(x.t for x in trans_indices(connection=conn, commodity=c, t=t))
            )
        ]
    ]
end

fix_stor_state_(x) = fix_stor_state(storage=x.storage, t=x.t, _strict=false)
stor_state_lb(x) = stor_state_min(storage=x.storage)

create_variable_stor_state!(m::Model) = create_variable!(m, :stor_state, stor_state_indices; lb=stor_state_lb)
save_variable_stor_state!(m::Model) = save_variable!(m, :stor_state, stor_state_indices)
fix_variable_stor_state!(m::Model) = fix_variable!(m, :stor_state, stor_state_indices, fix_stor_state_)
