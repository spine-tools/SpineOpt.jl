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
    constraint_unitary_trans(m::Model)

Enoforcing unitray flow along transmission line at one timestep
"""
function constraint_unitary_trans(m::Model)
    @fetch binary_trans = m.ext[:variables]
    constr_dict = m.ext[:constraints][:unitary_trans] = Dict()
    for (conn,n,d) in indices(unitary_trans)
        for (conn,n,c,d,t) in trans_indices(connection=conn,node=n,direction=d)
            constr_dict[conn,t] = @constraint(
                m,
                binary_trans[conn,n,d,t]
                +
                    reduce(
                    +,
                        binary_trans[conn1,n1,d1,t1]
                            for (conn1,n1,c1,d1,t1) in trans_indices(connection=conn,direction=d,t=t)
                                if n1 != n && unitary_trans(connection=conn1, node= n1, direction=d1) == :unitary_trans;
                        init=0
                    )
                <=
                1
            )
        end
    end
end
