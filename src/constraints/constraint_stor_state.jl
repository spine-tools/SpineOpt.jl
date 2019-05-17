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
        for t2 in t_before_t(t_before=t1)
            if !isempty(t_before_t(t_after=t)) && t2 in [t for (stor, c, t) in stor_state_indices()]
                constr_dict[stor, c, t1, t2] = @constraint(
                    m,
                    + stor_state[c,stor,t2]
                    ==
                    stor_state[c,stor, t1] * (1 - frac_state_loss(storage=stor, commodity=c))
                    - reduce(
                        +,
                        flow[u, n, c, :to_node, t1] * stor_unit_discharg_eff(storage=stor, commodity=c, unit=u)
                        for (u, n, c, d, t1) in flow_indices(
                            unit=indices(stor_unit_discharg_eff; storage=stor, commodity=c),
                            commodity=c,
                            t=t2
                        );
                        init=0
                    )
                    + reduce(
                        +,
                        flow[u, n, c, :to_node, t1] * stor_unit_charg_eff(storage=stor, commodity=c, unit=u)
                        for (u, n, c, d, t1) in flow_indices(
                            unit=indices(stor_unit_charg_eff; storage=stor, commodity=c),
                            commodity=c,
                            t=t2
                        );
                        init=0
                    )
                    - reduce(
                        +,
                        trans[conn, n, c, :to_node, t1] * stor_conn_discharg_eff(storage=stor, commodity=c, connection=conn)
                        for (conn, n, c, d, t1) in trans_indices(
                            conn=indices(stor_conn_discharg_eff; storage=stor, commodity=c),
                            commodity=c,
                            t=t2
                        );
                        init=0
                    )
                    + reduce(
                        +,
                        trans[conn, n, c, :to_node, t1] * stor_conn_charg_eff(storage=stor, commodity=c, connection=conn)
                        for (conn, n, c, d, t1) in trans_indices(
                            conn=indices(stor_conn_charg_eff; storage=stor, commodity=c),
                            commodity=c,
                            t=t2
                        );
                        init=0
                    )
                )
            end
        end
    end
end
