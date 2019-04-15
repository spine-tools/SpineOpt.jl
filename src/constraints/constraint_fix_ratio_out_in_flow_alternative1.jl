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

# Since all functions to generate the constraint are in the constraints folder, could we rename the files by removing 'constraint_'?
# good idea, but it looks like doesn't work?
function constraint_fix_ratio_out_in_flow(m::Model, flow)
    @butcher for (u, cg_out, cg_in) in unit__out_commodity_group__in_commodity_group(), t in time_slice()
        all([
            all([
            (any(haskey(flow,(c_out,n,u,:out,t)) for c_out in commodity_group__commodity(commodity_group=cg_out) for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:out, commodity = c_out)) && any(haskey(flow,(c_in,n,u,:in,t1)) for c_in in commodity_group__commodity(commodity_group=cg_in) for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:in, commodity = c_in) for t1 in t_in_t(t_long=t)))||
            (any(haskey(flow,(c_in,n,u,:in,t)) for c_in in commodity_group__commodity(commodity_group=cg_in) for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:in, commodity = c_in)) && any(haskey(flow,(c_out,n,u,:out,t1)) for c_out in commodity_group__commodity(commodity_group=cg_out) for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:out, commodity = c_out) for t1 in t_in_t(t_long=t)))
            ])
            fix_ratio_out_in_flow(unit__out_commodity_group__in_commodity_group=(u, cg_out, cg_in))(t=t) != nothing
       ]) || continue
        @constraint(
        m,
        + reduce(
            +,
            flow[c_out, n, u, :out, t1] * duration(t1)
            for c_out in commodity_group__commodity(commodity_group=cg_out)
                for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:out, commodity = c_out)
                    for t1 in t_in_t(t_long=t)
                        if haskey(flow,(c_out,n,u,:out,t1));
            init= 0
        )
        ==
        + fix_ratio_out_in_flow(unit__out_commodity_group__in_commodity_group=(u, cg_out, cg_in))(t=t)
            * reduce(
                +,
                flow[c_in, n, u, :in, t2] * duration(t2)
                for c_in in commodity_group__commodity(commodity_group=cg_in)
                    for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:in, commodity = c_in)
                        for t2 in t_in_t(t_long=t)
                            if haskey(flow,(c_in,n,u,:in,t2));
                init = 0
            )
        )
    end
end
