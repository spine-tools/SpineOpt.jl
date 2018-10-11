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
function constraint_fix_ratio_out_in_flow(m::Model, v_flow)
    @constraint(
        m,
        [
            u in unit(),
            cg_out in commodity_group(),
            cg_in in commodity_group(),
            t=1:number_of_timesteps(time="timer");
            fix_ratio_out_in_flow(unit=u, commodity_group1=cg_out, commodity_group2=cg_in) != nothing
        ],
        + sum(v_flow[c_out, n, u, "out", t] for c_out in commodity_group__commodity(commodity_group=cg_out), n in node()
            if [c_out, n] in commodity__node__unit__direction(unit=u, direction="out"))
        ==
        + fix_ratio_out_in_flow(unit=u, commodity_group1=cg_out, commodity_group2=cg_in)
            * sum(v_flow[c_in, n, u, "in", t] for c_in in commodity_group__commodity(commodity_group=cg_in), n in node()
                if [c_in, n] in commodity__node__unit__direction(unit=u, direction="in"))
    )
end
