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
    constraint_flow_capacity(m::Model)

Limit the maximum in/out `flow` of a `unit` for all `unit_capacity` indices.
Check if `unit_conv_cap_to_flow` is defined.
"""
@catch_undef function constraint_flow_capacity(m::Model)
    @fetch flow, units_on = m.ext[:variables]
    constr_dict = m.ext[:constraints][:flow_capacity] = Dict{NamedTuple,Any}()
    for (u, c, d) in indices(unit_capacity)
        for t in time_slice()
            constr_dict[(unit=u, commodity=c, direction=d)] = @constraint(
                m,
                + reduce(
                    +,
                    + flow[u1, n1, c1, d1, t1] * duration(t1)
                    for (u1, n1, c1, d1, t1) in flow_indices(
                        unit=u,
                        commodity=c,
                        direction=d,
                        t=t
                    );
                    init=0
                )
                <=
                + reduce(
                    +,
                    + units_on[u1, t1]
                    * unit_capacity(unit=u, commodity=c, direction=d)
                        * unit_conv_cap_to_flow(unit=u, commodity=c)
                            * duration(t1)
                    for (u1, t1) in units_on_indices(unit=u, t=t_in_t(t_long=t));
                    init=0
                )
            )
        end
    end
end
