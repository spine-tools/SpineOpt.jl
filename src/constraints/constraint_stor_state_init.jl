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
function constraint_stor_state_init(m::Model, stor_state)
    for (stor, c) in indices(stor_state_init),
        (stor, c, t) in stor_state_indices(storage=stor, commodity=c)
        if isempty(t_before_t(t_after=t))
            @constraint(
                m,
                + stor_state[stor, c, t]
                <=
                + stor_state_init(storage=stor, commodity=c)
            )
        end
    end
end
