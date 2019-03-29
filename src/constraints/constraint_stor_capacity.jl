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
    constraint_stor_capacity(m::Model, stor_state)

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""
function constraint_stor_capacity(m::Model, stor_state, timeslicemap)
    @butcher for (c, stor) in commodity__storage(), t in timeslicemap()
        all([
            stor_capacity(commodity__storage=(c,stor)) != nothing
            haskey(stor_state,(c,stor,t))
        ]) || continue
        @constraint(
            m,
                stor_state[c,stor,t]
                 <=
                      stor_capacity(commodity__storage=(c,stor))
        )
    end
end
