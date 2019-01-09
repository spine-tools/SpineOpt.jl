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
    constraint_stor_state(m::Model, stor_state)

Balance for storage level.
"""
function constraint_stor_state(m::Model, stor_state,trans,flow)
    @butcher for (c, stor) in commodity__stor(), t=2:number_of_timesteps(time=:timer)
        all([
        ### check if discharge, charge are defined
        ### for all existing stor__unit, sotr__connection, stor__node
        ## storage loss
            frac_state_loss(c,stor) != nothing,
            number_of_units(unit=u) != nothing,
            unit_conv_cap_to_flow(unit=u, commodity=c) != nothing,
            avail_factor(unit=u, t=t) != nothing
        ]) || continue
        @constraint(
            m,
            + stor_state[c,stor,t]
            <=
            + stor_state[c,stor,t-1]
                *(1-frac_state_loss(c,stor))

            + sum(flow[c, n, u, :out, t-1]*eff_stor_charg(u,stor)
            for (c, n, u) in commodity__node__unit__direction(direction=:out))
            - sum(flow[c, n, u, :in, t-1]*eff_stor_discharg(u,stor)
                for (c, n, u) in commodity__node__unit__direction(direction=:in)
                     if u in storage__unit(storage=stor))
                    ### todo: which sets/relationship need to be created?

            + sum(trans[conn, n, t-1]
            for (conn,n) in connection__node()
                if conn in storage__connection(storage=stor))
                ### todo: which sets?
        )
    end

    @butcher for (c, stor) in commodity__stor(), t=1
        all([
        ### check if discharge, charge are defined
        ### for all existing stor__unit, sotr__connection, stor__node
        ## storage loss
            frac_state_loss(c,stor) != nothing,
            number_of_units(unit=u) != nothing,
            unit_conv_cap_to_flow(unit=u, commodity=c) != nothing,
            avail_factor(unit=u, t=t) != nothing
        ]) || continue
        @constraint(
            m,
            + stor_state[c,stor,t]
            =
            0
        )
    end
end
