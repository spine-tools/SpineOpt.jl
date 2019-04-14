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

# 2) Since all functions to generate the constraint are in the constraints folder, could we rename the files by removing 'constraint_'?
function constraint_fix_ratio_out_in_flow(m::Model, flow)
    for (u, cg_out, cg_in) in unit__out_commodity_group__in_commodity_group()
        time_slices_constraint_out = []
        time_slices_constraint_in = []
        ## get all time_slices for which the flow variables are defined (direction = :out)
        for c_out in commodity_group__commodity(commodity_group=cg_out)
            for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:out, commodity=c_out)
                for t in time_slice(temporal_block=tblock)
                    push!(time_slices_constraint_out ,t)
                end
            end
        end
        ## get all time_slices for which the flow variables are defined (direction = :in)
        for c_in in commodity_group__commodity(commodity_group=cg_in)
            for (n, tblock) in commodity__node__unit__direction__temporal_block(unit=u, direction=:in, commodity=c_in)
                for t in time_slice(temporal_block=tblock)
                    push!(time_slices_constraint_in, t)
                end
            end
        end
        ## remove duplicates (e.g. if two flows of the same direction are defined on the same temp level)
        unique!(time_slices_constraint_out)
        unique!(time_slices_constraint_in)
        ## look for overlapping timeslice -> only timeslices which actually have an overlap should be considered
        overlaps = t_overlaps_t(t_overlap1 = time_slices_constraint_in,t_overlap2 = time_slices_constraint_out)

        ## within overlapping timeslices -> get the ones with highest resolution
        # TODO: how to handle if timeslices are not ordered, include ordering (-> is this always the case anyways)

######## give flow keys? e.g. for flow in flowkeys ...
        @butcher for t in t_top_level(t_list = overlaps)
            if fix_ratio_out_in_flow(unit__out_commodity_group__in_commodity_group=(u, cg_out, cg_in))(t=t) == nothing
                continue
            end
            @constraint(
                m,
                + reduce(
                    +,
                    flow[c_out, n, u, :out, t1]*duration(time_slice=t1)
                    for c_out in commodity_group__commodity(commodity_group=cg_out)
                        for (n, tblock) in commodity__node__unit__direction__temporal_block(
                                unit=u, direction=:out, commodity=c_out)
                            for t1 in t_in_t(t_long=t)
                                if haskey(flow,(c_out,n,u,:out,t1));
                    init= 0
                )
                ==
                + fix_ratio_out_in_flow(unit__out_commodity_group__in_commodity_group=(u, cg_out, cg_in))(t=t)
                    * reduce(
                        +,
                        flow[c_in, n, u, :in, t2]*duration(time_slice=t2)
                        for c_in in commodity_group__commodity(commodity_group=cg_in)
                            for (n, tblock) in commodity__node__unit__direction__temporal_block(
                                    unit=u, direction=:in, commodity=c_in)
                                for t2 in t_in_t(t_long=t)
                                    if haskey(flow,(c_in,n,u,:in,t2));
                        init = 0
                    )
            )
        end
    end
end
