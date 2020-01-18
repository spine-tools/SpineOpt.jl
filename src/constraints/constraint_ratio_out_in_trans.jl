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
    constraint_ratio_out_in_trans(m, parameter, sense)

Ratio of `trans` variables.
"""
function constraint_ratio_out_in_trans(m::Model, ratio, sense)
    @fetch trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][ratio.name] = Dict()
    for (conn, n1, n2) in indices(ratio)
        for t in t_lowest_resolution(map(x -> x.t, trans_indices(connection=conn, node=[n1, n2])))
            constr_dict[conn, n1, n2, t] = sense_constraint(
                m,
                + reduce(
                    +,
                    trans[conn_, n1_, c, d, t_] * duration(t_)
                    for (conn_, n1_, c, d, t_) in trans_indices(
                        connection=conn, node=n1, direction=:to_node, t=t_in_t(t_long=t)
                    );
                    init=0
                ),
                sense,
                + ratio(connection=conn, node1=n1, node2=n2, t=t)
                * reduce(
                    +,
                    trans[conn_, n2_, c, d, t_]
                    * overlap_duration(t_, t - trans_delay(connection=conn, node1=n1, node2=n2, t=t))
                    for (conn_, n2_, c, d, t_) in trans_indices(
                        connection=conn,
                        node=n2,
                        direction=:from_node,
                        t=to_time_slice(t - trans_delay(connection=conn, node1=n1, node2=n2, t=t))
                    );
                    init=0
                )
            )
        end
    end
end

constraint_fix_ratio_out_in_trans(m::Model) = constraint_ratio_out_in_trans(m, fix_ratio_out_in_trans, ==)
constraint_max_ratio_out_in_trans(m::Model) = constraint_ratio_out_in_trans(m, max_ratio_out_in_trans, <=)
constraint_min_ratio_out_in_trans(m::Model) = constraint_ratio_out_in_trans(m, min_ratio_out_in_trans, >=)