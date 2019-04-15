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
    for (u, cg_out, cg_in) in unit__out_commodity_group__in_commodity_group()
        ## get all time_slices for which the flow variables are defined (direction = :out)
        time_slices_out = [
            t for (c_out, n, u_out, d, t) in keys(flow)
                if c_out in commodity_group__commodity(commodity_group=cg_out) && d == :out && u_out == u
        ]
        time_slices_in = [
            t for (c_in, n, u_in, d, t) in keys(flow)
                if c_in in commodity_group__commodity(commodity_group=cg_in) && d == :in && u_in == u
        ]
        ## get all time_slices for which the flow variables are defined (direction = :in)
        ## remove duplicates (e.g. if two flows of the same direction are defined on the same temp level)
        unique!(time_slices_out)
        unique!(time_slices_in)
        ## look for overlapping timeslice -> only timeslices which actually have an overlap should be considered
        overlaps = t_overlaps_t(time_slices_in, time_slices_out)
######## give flow keys? e.g. for flow in flowkeys ...
        @butcher for t in t_top_level(overlaps)
            fix_ratio_out_in_flow(unit=u, commodity_group1=cg_out, commodity_group2=cg_in)(t=t) == nothing && continue
            @constraint(
                m,
                + reduce(
                    +,
                    flow[c_out, n, u, :out, t1] * duration(t=t1)
                    for (c_out, n, u_out, d, t1) in keys(flow)
                        if c_out in commodity_group__commodity(commodity_group=cg_out)
                            && d == :out && u_out==u && t1 in t_in_t(t_long=t);
                    init= 0
                )
                ==
                + fix_ratio_out_in_flow(unit=u, commodity_group1=cg_out, commodity_group2=cg_in)(t=t)
                * reduce(
                    +,
                    flow[c_in, n, u, :in, t1] * duration(t=t1)
                    for (c_in, n, u_in, d, t1) in keys(flow)
                        if c_in in commodity_group__commodity(commodity_group=cg_in)
                            && d == :in && u_in==u && t1 in t_in_t(t_long=t);
                    init= 0
                )
            )
        end
    end
end
