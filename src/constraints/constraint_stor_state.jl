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
function constraint_stor_state(m::Model, stor_state,trans,flow, timeslicemap, t_before_t)
    @butcher for (c, stor, block) in commodity__storage__temporal_block(),
        t in keys(timeslicemap) if !(timeslicemap[t].Start_Date == start_date(block))
        all([
            haskey(stor_state,("$c,$stor,$t"))
            frac_state_loss(commodity=c,storage=stor) != nothing
            eff_stor_charg(storage=stor) != nothing
            eff_stor_discharg(storage=stor) != nothing
        ]) || continue
        @constraint(
            m,
            + stor_state[c,stor,t]
            ==
            + reduce(+,
                stor_state[c,stor, t2]
                    for t2 in keys(t_before_t[t]) if haskey(stor_state,("$c,$stor,$t2"));init=0)
                *(1-frac_state_loss(commodity=c,storage=stor))
                #=
            - reduce(+,
                flow[a,b,d, :out, keys(t_before_t[t])]*eff_stor_discharg(storage=stor)
                    for (a,b,d) in filter(t -> in(t[3],storage__unit(storage=stor)), commodity__node__unit__direction(direction=:out)))
            + reduce(+,
                flow[a,b,d, :in, keys(t_before_t[t])]*eff_stor_charg(storage=stor)
                    for (a,b,d) in filter(t -> in(t[3],storage__unit(storage=stor)), commodity__node__unit__direction(direction=:in)))
            - reduce(+,
                trans[a,b,d, :out,t_before_t[t].name]*eff_stor_discharg(storage=stor)
                    for (a,b,d) in filter(t -> in(t[3],storage__connection(storage=stor)), commodity__node__connection__direction(direction=:out)))
            - reduce(+,
                trans[a,b,d, :in,t_before_t[t].name]*eff_stor_charg(storage=stor) #TO DO: EFF STOR ALS FKT von unit
                    for (a,b,d) in filter(t -> in(t[3],storage__connection(storage=stor)), commodity__node__connection__direction(direction=:in)))
                    =#
        )
    end
end
end
