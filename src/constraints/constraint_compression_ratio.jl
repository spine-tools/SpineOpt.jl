#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    constraint_compression_ratio(m::Model)

Constraint for compressor pipelines.
"""
function constraint_compression_ratio(m::Model)
    @fetch node_pressure = m.ext[:variables]
    constr_dict = m.ext[:constraints][:compression_ratio] = Dict()
    for (conn, n_orig, n_dest) in indices(compression_factor)
        for (n_orig,t) in node_pressure_indices(node=n_orig)
            constr_dict[conn, n_orig, n_dest, t] = @constraint(
                m,
                node_pressure[n_dest,t]
                <=
                compression_factor(connection = conn,node1=n_orig,node2=n_dest) * node_pressure[n_orig,t]
                )
        end
    end
end
