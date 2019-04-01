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
    constraint_flow_capacity(m::Model, flow, time_slice)

Limit the maximum in/out `flow` of a `unit` if the parameters `unit_capacity,
number_of_unit, unit_conv_cap_to_flow, avail_factor` exist.
"""

# Suggested new version (see comments in version above)
# @Maren: should the parameter unit_capacity have a direction index?
function constraint_flow_capacity(m::Model, flow, time_slice)
    @butcher for (c, n, u, d) in commodity__node__unit__direction(), t in time_slice()
        all([
            haskey(flow, (c, n, u, d, t)),
            #unit_capacity(unit__commodity=(u, c)) != nothing,
            #number_of_units(unit=u) != nothing,
            #unit_conv_cap_to_flow(unit__commodity=(u,c)) != nothing,
            #avail_factor(unit=u) != nothing            
            (u, c) in unit__commodity()
        ]) || continue
        @constraint(
            m,
            + flow[c, n, u, d, t]
            <=
            + avail_factor(unit=u)
                * unit_capacity(unit__commodity=(u,c))
                    * number_of_units(unit=u)
                        * unit_conv_cap_to_flow(unit__commodity=(u,c))
        )
    end
end


# function constraint_flow_capacity_old(m::Model, flow, time_slice)
#     @butcher for (c, n, u, d, t) in collect(keys(flow))
#         all([
#             unit_capacity(unit=u, commodity=c) != 0, # @Maren: I think it would be better to replace this line by: (u,c) in keys(unit_capacity(). Now, if someone sets unit_capacity at zero, no constraint would be generated.
#             number_of_units(unit=u) != 0, #@Maren: This condition should be removed. If number_of_unit = 0, flow would be unconstrained because no constraint would be generated currently
#             unit_conv_cap_to_flow(unit=u, commodity=c) != 0, #@Maren: same as for the above line, rather an error than no constraint beig generated.
#             avail_factor(unit=u, t=1) != 0 #@Maren: again, same problem
#         ]) || continue
#         @constraint(
#             m,
#             + flow[c, n, u, d, t]
#             <=
#             + avail_factor(unit=u, t=1) #@Maren: what is this t=1 thing here?
#                 * unit_capacity(unit=u, commodity=c)
#                     * number_of_units(unit=u)
#                         * unit_conv_cap_to_flow(unit=u, commodity=c)
#         )
#     end
# end
