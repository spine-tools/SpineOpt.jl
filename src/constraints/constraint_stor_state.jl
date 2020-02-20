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
    add_constraint_stor_state!(m::Model)

Balance for storage level.
"""
function add_constraint_stor_state!(m::Model)
    @fetch stor_state, trans, flow = m.ext[:variables]
    cons = m.ext[:constraints][:stor_state] = Dict()
    for (stor, c, t_after) in stor_state_indices()
        for (stor, c, t_before) in stor_state_indices(storage=stor, commodity=c, t=t_before_t(t_after=t_after))
            cons[stor, c, t_before, t_after] = @constraint(
                m,
                (
                    stor_state[stor, c, t_after] * state_coeff(storage=stor, t=t_after)
                    - stor_state[stor, c, t_before] * state_coeff(storage=stor, t=t_before)   
                )
                    / duration(t_after)
                ==
                - stor_state[stor, c, t_after] * frac_state_loss(storage=stor, t=t_after)
                - reduce(
                    +,
                    stor_state[stor, c, t_after]
                    * diff_coeff(storage1=stor, storage2=stor_, t=t_after)
                    for stor_ in storage__storage(storage1=stor);
                    init = 0
                )
                + reduce(
                    +,
                    stor_state[stor_, c, t_after]
                    * diff_coeff(storage1=stor_, storage2=stor, t=t_after)
                    for stor_ in storage__storage(storage2=stor);
                    init = 0
                )
                - reduce(
                    +,
                    flow[u, n, c_, d, t_] * stor_unit_discharg_eff(storage=stor, unit=u, t=t_after) # TODO: Shouldn't this be divided by the efficiency instead of multiplying?
                    for (u, n, c_, d, t_) in flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_discharg_eff; storage=stor)],
                        commodity=c,
                        direction=direction(:to_node),
                        t=t_after
                    );
                    init=0
                )
                + reduce(
                    +,
                    flow[u, n, c_, d, t_] * stor_unit_charg_eff(storage=stor, unit=u, t=t_after)
                    for (u, n, c_, d, t_) in flow_indices(
                        unit=[u1 for (stor1, u1) in indices(stor_unit_charg_eff; storage=stor)],
                        commodity=c,
                        direction=direction(:from_node),
                        t=t_after
                    );
                    init=0
                )
                - reduce(
                    +,
                    trans[conn, n, c_, d, t_] * stor_conn_discharg_eff(storage=stor, connection=conn, t=t_after) # TODO: Shouldn't this be divided by the efficiency instead of multiplying?
                    for (conn, n, c_, d, t_) in trans_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_discharg_eff; storage=stor)],
                        commodity=c,
                        direction=direction(:to_node),
                        t=t_after
                    );
                    init=0
                )
                + reduce(
                    +,
                    trans[conn, n, c_, d, t_] * stor_conn_charg_eff(storage=stor, connection=conn, t=t_after)
                    for (conn, n, c_, d, t_) in trans_indices(
                        connection=[conn1 for (stor1, conn1) in indices(stor_conn_charg_eff; storage=stor)],
                        commodity=c,
                        direction=direction(:from_node),
                        t=t_after
                    );
                    init=0
                )
            )
        end
    end
end

function update_constraint_stor_state!(m::Model)
    @fetch stor_state, trans, flow = m.ext[:variables]
    cons = m.ext[:constraints][:stor_state]
    for (stor, c, t_after) in stor_state_indices()
        for (stor, c, t_before) in stor_state_indices(storage=stor, commodity=c, t=t_before_t(t_after=t_after))
            # Update this storage's stor_state(t_after) coefficient
            set_normalized_coefficient(
                cons[stor, c, t_before, t_after],
                stor_state[stor, c, t_after],
                + state_coeff(storage=stor, t=t_after) / duration(t_after)
                + frac_state_loss(storage=stor, t=t_after)
                + reduce(
                    +,
                    diff_coeff(storage1=stor, storage2=stor_, t=t_after)
                    for stor_ in storage__storage(storage1=stor);
                    init = 0
                )
            )
            # Update this storage's stor_state(t_before) coefficient
            set_normalized_coefficient(
                cons[stor, c, t_before, t_after],
                stor_state[stor, c, t_before],
                - state_coeff(storage=stor, t=t_before) / duration(t_after)
            )
            # Update coefficients for connected stor_states
            for stor_ in storage__storage(storage2=stor)
                set_normalized_coefficient(
                    cons[stor, c, t_before, t_after],
                    stor_state[stor_, c, t_after],
                    - diff_coeff(storage1=stor_, storage2=stor, t=t_after)
                )
            end
            # Update coefficients for connected discharging units
            for (u, n, c_, d, t_) in flow_indices(
                unit=[u1 for (stor1, u1) in indices(stor_unit_discharg_eff; storage=stor)],
                commodity=c,
                direction=direction(:to_node),
                t=t_after
            )
                set_normalized_coefficient(
                    cons[stor, c, t_before, t_],
                    flow[u, n, c_, d, t_],
                    stor_unit_discharg_eff(storage=stor, unit=u, t=t_) # TODO: Shouldn't this be divided by the efficiency instead of multiplying?
                )
            end
            # Update coefficients for connected charging units
            for (u, n, c_, d, t_) in flow_indices(
                unit=[u1 for (stor1, u1) in indices(stor_unit_charg_eff; storage=stor)],
                commodity=c,
                direction=direction(:from_node),
                t=t_after
            )
                set_normalized_coefficient(
                    cons[stor, c, t_before, t_],
                    flow[u, n, c_, d, t_],
                    - stor_unit_charg_eff(storage=stor, unit=u, t=t_)
                )
            end
            # Update coefficients for connected discharging connections
            for (conn, n, c_, d, t_) in trans_indices(
                connection=[conn1 for (stor1, conn1) in indices(stor_conn_discharg_eff; storage=stor)],
                commodity=c,
                direction=direction(:to_node),
                t=t_after
            )
                set_normalized_coefficient(
                    cons[stor, c, t_before, t_],
                    trans[conn, n, c_, d, t_],
                    stor_conn_discharg_eff(storage=stor, connection=conn, t=t_) # TODO: Shouldn't this be divided by the efficiency instead of multiplying?
                )
            end
            # Update coefficients for connected charging connections
            for (conn, n, c_, d, t_) in trans_indices(
                connection=[conn1 for (stor1, conn1) in indices(stor_conn_charg_eff; storage=stor)],
                commodity=c,
                direction=direction(:from_node),
                t=t_after
            )
                set_normalized_coefficient(
                    cons[stor, c, t_before, t_],
                    trans[conn, n, c_, d, t_],
                    - stor_conn_charg_eff(storage=stor, connection=conn, t=t_)
                )
            end
        end
    end
end