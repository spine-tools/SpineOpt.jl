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
    constraint_stor_state(m::Model)

Balance for storage level.
"""
@catch_undef function constraint_stor_state(m::Model)
    @fetch stor_state, trans, flow = m.ext[:variables]
    constr_dict = m.ext[:constraints][:stor_state] = Dict()
    for (stor, c, t1) in stor_state_indices()
        for (stor, c, t2) in stor_state_indices(storage=stor, commodity=c, t=t_before_t(t_before=t1))
            constr_dict[stor, c, t1, t2] = @constraint(
                m,
                + stor_state[stor, c, t2]
                ==
                + stor_state[stor, c, t1] * (1 - frac_state_loss(storage=stor))
                - reduce(
                    +,
                    flow[u, n, c_, d, t_] * stor_unit_discharg_eff(storage=stor, unit=u)
                    for (u, n, c_, d, t_) in flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_discharg_eff)],
                        commodity=c,
                        direction=:to_node,
                        t=t2
                    );
                    init=0
                )
                + reduce(
                    +,
                    flow[u, n, c_, d, t_] * stor_unit_charg_eff(storage=stor, unit=u)
                    for (u, n, c_, d, t_) in flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_charg_eff)],
                        commodity=c,
                        direction=:from_node,
                        t=t2
                    );
                    init=0
                )
                - reduce(
                    +,
                    trans[conn, n, c_, d, t_] * stor_conn_discharg_eff(storage=stor, connection=conn)
                    for (conn, n, c_, d, t_) in trans_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_discharg_eff)],
                        commodity=c,
                        direction=:to_node,
                        t=t2
                    );
                    init=0
                )
                + reduce(
                    +,
                    trans[conn, n, c_, d, t_] * stor_conn_charg_eff(storage=stor, connection=conn)
                    for (conn, n, c_, d, t_) in trans_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_charg_eff)],
                        commodity=c,
                        direction=:from_node,
                        t=t2
                    );
                    init=0
                )
            )
        end
    end
end
