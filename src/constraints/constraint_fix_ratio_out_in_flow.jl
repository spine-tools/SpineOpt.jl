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

# @Maren:
# 1) this constraint does not make use of the @butcher. I believe that if it is beneficial to use that in the variable generation, the same applies for constraints. constraint_flow_capacity does currently use @butcher already
#   @manuelma: We were having some problems with @butcher so someone must have commented it out,
#   now seems to be working again
# 2) Since all functions to generate the constraint are in the constraints folder, could we rename the files by removing 'constraint_'?
#   @manuelma: good idea, perhaps we could do the same for objective and variable?
function constraint_fix_ratio_out_in_flow(m::Model, flow)
    @butcher @constraint(
        m,
        [
            u in unit(),
            cg_out in commodity_group(),
            cg_in in commodity_group(),
            tblock = temporal_block(),
            t in time_slice(temporal_block=tblock);
            #fix_ratio_out_in_flow_t(
            #    unit__commodity_group__commodity_group__temporal_block=(u, cg_out, cg_in, tblock)) != nothing
            (u, cg_out, cg_in, tblock) in unit__commodity_group__commodity_group__temporal_block()
        ],
        + reduce(
            +,
            flow[c_out, n, u, :out, t2]
            for (c_out, n) in commodity__node__unit__direction(unit=u, direction=:out)
                for t2 in t_in_t(t_long=t)
                    if c_out in commodity_group__commodity(commodity_group=cg_out)
                        && haskey(flow, (c_out, n, u, :out, t2));
            init=0
        )
        ==
        + fix_ratio_out_in_flow_t(unit__commodity_group__commodity_group__temporal_block=(u, cg_out, cg_in, tblock))
            * reduce(
                +,
                flow[c_in, n, u, :in, t2]
                for (c_in, n) in commodity__node__unit__direction(unit=u, direction=:in)
                    for t2 in t_in_t(t_long=t)
                        if c_in in commodity_group__commodity(commodity_group=cg_in)
                            && haskey(flow, (c_in, n, u, :in, t2));
                init=0
            )
    )
end
