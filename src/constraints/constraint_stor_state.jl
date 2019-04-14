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
    constraint_stor_state(m::Model, stor_state, trans, flow)

Balance for storage level.
"""
function constraint_stor_state(m::Model, stor_state, trans, flow)
    @butcher for (c, stor, block) in commodity__storage__temporal_block(), t in time_slice(temporal_block=block)
        all([
            t != time_slice(temporal_block=block)[1]
            haskey(stor_state, (c, stor, t))
            frac_state_loss(commodity=c, storage=stor) != nothing
            eff_stor_charg(storage=stor) != nothing
            eff_stor_discharg(storage=stor) != nothing
        ]) || continue
        @constraint(
            m,
            + stor_state[c,stor,t]
            ==
            + reduce(
                +,
                stor_state[c,stor, t2] for t2 in t_before_t(t_after=t) if haskey(stor_state, (c, stor, t2));
                init=0
            ) * (1 - frac_state_loss(commodity=c, storage=stor))
            - reduce(
                +,
                flow[c, n, u, :out, t2]
                for (n, u) in commodity__node__unit__direction(commodity=c, direction=:out)
                    for t2 in t_before_t(t_after=t)
                        if u in storage__unit(storage=stor) && haskey(flow, (c, n, u, :out, t2));
                init=0
            ) * eff_stor_discharg(storage=stor)
            + reduce(
                +,
                flow[c, n, u, :in, t2]
                for (n, u) in commodity__node__unit__direction(commodity=c, direction=:in)
                    for t2 in t_before_t(t_after=t)
                        if u in storage__unit(storage=stor) && haskey(flow, (c, n, u, :in, t2));
                init=0
            ) * eff_stor_charg(storage=stor)
            - reduce(
                +,
                trans[c, n, conn, :out, t2]
                for (n, conn) in commodity__node__connection__direction(commodity=c, direction=:out)
                    for t2 in t_before_t(t_after=t)
                        if conn in storage__connection(storage=stor) && haskey(trans, (c, n, conn, :out, t2));
                init=0
            ) * eff_stor_discharg(storage=stor)
            + reduce(
                +,
                trans[c, n, conn, :in, t2]
                for (n, conn) in commodity__node__connection__direction(commodity=c, direction=:in)
                    for t2 in t_before_t(t_after=t)
                        if conn in storage__connection(storage=stor) && haskey(trans, (c, n, conn, :in, t2));
                init=0
            ) * eff_stor_charg(storage=stor)
        )
    end
end
