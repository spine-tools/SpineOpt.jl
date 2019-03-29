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
    constraint_stor_state_init(m::Model, stor_state)

Balance for storage level.
"""
function constraint_stor_state_init(m::Model, stor_state, timeslicemap)
    @butcher for (c, stor, block) in commodity__storage__temporal_block(),   t in timeslicemap(temporal_block=block)
        all([
        t == timeslicemap(temporal_block=block)[1],
        haskey(stor_state,(c,stor,t)),
        stor_state_init(commodity__storage=(c,stor)) != nothing
        ]) || continue
    @constraint(
        m,
        + stor_state[c,stor,t]
        <=
        + stor_state_init(commodity__storage=(c,stor))
    )
end
end
