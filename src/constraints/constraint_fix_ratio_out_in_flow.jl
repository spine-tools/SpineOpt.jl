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
    constraint_fix_ratio_out_in_flow(m::Model, flow)

Fix ratio between the output `flow` of a `commodity_group` to an input `flow` of a
`commodity_group` for each `unit` for which the parameter `fix_ratio_out_in_flow`
is specified.
"""
function constraint_fix_ratio_out_in_flow(m::Model, flow, timeslicemap, t_in_t)
    #@butcher
    @constraint(
        m,
        [
            u in unit(),
            cg_out in commodity_group(),
            cg_in in commodity_group(),
            tblock = temporal_block(),
            t in timeslicemap(temporal_block=tblock);
            fix_ratio_out_in_flow_t(unit__commodity_group__commodity_group__temporal_block=(u, cg_out, cg_in, tblock)) != nothing
        ],
        + reduce(+,
            flow[c_out, n, u, :out, t2]
            for (c_out, n) in commodity__node__unit__direction(unit=u, direction=:out)
                for t2 in t_in_t(t_above=t)
                    if c_out in commodity_group__commodity(commodity_group=cg_out) &&
                        haskey(flow,(c_out,n,u,:out,t2));
                        init=0
            )
        ==
        + fix_ratio_out_in_flow_t(unit__commodity_group__commodity_group__temporal_block=(u, cg_out, cg_in, tblock))
            * reduce(+,
                flow[c_in, n, u, :in, t2]
                for (c_in, n) in commodity__node__unit__direction(unit=u, direction=:in)
                    for t2 in t_in_t(t_above=t)
                        if c_in in commodity_group__commodity(commodity_group=cg_in) &&
                            haskey(flow,(c_in,n,u,:in,t2));
                            init=0
                )
    )
end
