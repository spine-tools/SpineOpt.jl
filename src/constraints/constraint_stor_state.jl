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
function constraint_stor_state(m::Model)
    @fetch stor_state, trans, flow = m.ext[:variables]
    for (stor, c, t1) in stor_state_indices(), t2 in t_before_t(t_before=t1)
        if !isempty(t_before_t(t_after=t)) && t2 in [t for (stor, c, t) in stor_state_indices()]
            @constraint(
                m,
                + stor_state[c,stor,t2]
                ==
                stor_state[c,stor, t1] * (1 - frac_state_loss(commodity=c, storage=stor))
                - reduce(
                    +,
                    flow[u, n, c, :out, t1] * stor_discharg_eff(storage=stor, commodity=c, unit=u)
                    for (u, n, c, d, t1) in flow_indices(
                        unit =unit_stor_discharg_eff_indices(storage=stor, commodity=c),
                        commodity=c,
                        t=t2
                    );
                    init=0
                )
                + reduce(
                    +,
                    flow[u, n, c, :out, t1] * stor_charg_eff(storage=stor, commodity=c, unit=u)
                    for (u, n, c, d, t1) in flow_indices(
                        unit =unit_stor_charg_eff_indices(storage=stor, commodity=c),
                        commodity=c,
                        t=t2
                    );
                    init=0
                )
                - reduce(
                    +,
                    trans[conn, n, c, :out, t1] * stor_discharg_eff(storage=stor, commodity=c, connection=conn)
                    for (conn, n, c, d, t1) in trans_indices(
                        conn =conn_stor_discharg_eff_indices(storage=stor, commodity=c),
                        commodity=c,
                        t=t2
                    );
                    init=0
                )
                + reduce(
                    +,
                    trans[conn, n, c, :out, t1] * stor_charg_eff(storage=stor, commodity=c, connection=conn)
                    for (conn, n, c, d, t1) in trans_indices(
                        conn =conn_stor_charg_eff_indices(storage=stor, commodity=c),
                        commodity=c,
                        t=t2
                    );
                    init=0
                )
            )
        end
    end
end
