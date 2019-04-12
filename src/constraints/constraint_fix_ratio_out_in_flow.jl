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
        gathering = []
        constraint_generate_on = []
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
        for t_in in time_slices_constraint_in
            overlaps_of_t_in = t_overlaps_t(t_overlap=t_in)
            for overlaps in overlaps_of_t_in
                ## search for overlapping which are also part of t_out
                overlap_out_in = time_slices_constraint_out[findall(x -> x == overlaps, time_slices_constraint_out)]
                if overlap_out_in != []
                    gathering = push!(gathering, t_in)
                    gathering = push!(gathering, overlap_out_in[1])
                    ## TODO make sure that gathering[1] is start always
                end
            end
        end
        ## within overlapping timeslices -> get the ones with highest resolution
        # TODO: how to handle if timeslices are not ordered, include ordering (-> is this always the case anyways)
        sort!(gathering)
        j = 1
        i =1
        while i < length(gathering)
            while j <= length(gathering) && (gathering[i].start == gathering[j].start || gathering[i].end_ >= gathering[j].end_) ##NOTE: sufficient?
                if gathering[i].end_ < gathering[j].end_
                    i = j
                    j +=1
                else #go to next [j]
                    j += 1
                end
            end
            constraint_generate_on = push!(constraint_generate_on, gathering[i])
            i = j
        end
######## give flow keys? e.g. for flow in flowkeys ...
        @butcher for t in constraint_generate_on
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
