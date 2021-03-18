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
    constraint_stor_state(m::Model)

Balance for storage level.
"""
function constraint_init_stor_state(m::Model)
    @fetch stor_state,flow,connection_flow= m.ext[:variables]
    constr_dict = m.ext[:constraints][:init_stor_state] = Dict()
    for (stor, c, t_after) in stor_state_indices()
        if t_after == time_slice()[1]
            constr_dict[stor, c, t_after] = @constraint(
                m,
                + stor_state[stor, c, t_after]
                    * state_coeff(storage=stor)
                     / duration(t_after)
                ==
                stor_state_init(storage=stor)
                - reduce(
                    +,
                   unit_flow[u, n, c_, d, t_] * stor_unit_discharg_eff(storage=stor, unit=u)
                    for (u, n, c_, d, t_) in unit_flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_discharg_eff; storage=stor)],
                        commodity=c,
                        direction=:to_node,
                        t=t_after
                    );
                    init=0
                )
                + reduce(
                    +,
                    unit_flow[u, n, c_, d, t_] * stor_unit_charg_eff(storage=stor, unit=u)
                    for (u, n, c_, d, t_) in unit_flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_charg_eff; storage=stor)],
                        commodity=c,
                        direction=:from_node,
                        t=t_after
                    );
                    init=0
                )
                - reduce(
                    +,
                    connection_flow[conn, n, c_, d, t_] * stor_conn_discharg_eff(storage=stor, connection=conn)
                    for (conn, n, c_, d, t_) in connection_flow_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_discharg_eff; storage=stor)],
                        commodity=c,
                        direction=:to_node,
                        t=t_after
                    );
                    init=0
                )
                + reduce(
                    +,
                    connection_flow[conn, n, c_, d, t_] * stor_conn_charg_eff(storage=stor, connection=conn)
                    for (conn, n, c_, d, t_) in connection_flow_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_charg_eff; storage=stor)],
                        commodity=c,
                        direction=:from_node,
                        t=t_after
                    );
                    init=0
                )
                )
        end
        if t_after == time_slice()[end]
            constr_dict[stor, c, t_after] = @constraint(
                m,
                + stor_state[stor, c, t_after]
                    * state_coeff(storage=stor)
                     / duration(t_after)
                >=
                stor_state_init(storage=stor)
                )
        end
    end
end
