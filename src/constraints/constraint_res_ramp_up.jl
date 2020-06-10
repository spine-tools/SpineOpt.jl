# Done, TODO fix rest in ramp_up, start_up constraints
# #############################################################################
# # Copyright (C) 2017 - 2018  Spine Project
# #
# # This file is part of Spine Model.
# #
# # Spine Model is free software: you can redistribute it and/or modify
# # it under the terms of the GNU Lesser General Public License as published by
# # the Free Software Foundation, either version 3 of the License, or
# # (at your option) any later version.
# #
# # Spine Model is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# # GNU Lesser General Public License for more details.
# #
# # You should have received a copy of the GNU Lesser General Public License
# # along with this program.  If not, see <http://www.gnu.org/licenses/>.
# #############################################################################
#
#
# """
#     constraint_ramp_up(m::Model)
#
# Limit the maximum ramp of `flow` of a `unit` if the parameters
# `ramp_up_limit,unit_capacity,unit_conv_cap_to_flow, minimum_operating_point` exist.
#
# """
#
# ##TODO: use method parameter, rempove/replace with ramp constraints
# function add_constraint_res_ramp_up!(m::Model)
#       @fetch flow, units_on,  units_shut_down, units_started_up, nonspin_starting_up, nonspin_shutting_down = m.ext[:variables]
#      constr_dict = m.ext[:constraints][:res_ramp_up_spin] = Dict()
#      #TODO: make sure this is done with ramp_up constraint!
#     #   for (u, c, d) in indices(res_ramp_up_limit)
#     #      for (u, t_after) in units_on_indices(unit=u)
#     #          for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
#     #              constr_dict[u, c, d, t_before] = @constraint(
#     #                     m,
#     #                     + sum(
#     #                         flow[u_, n_, c_, d_, t_]
#     #                                 for (u_, n_, c_, d_, t_) in flow_indices(unit=u, commodity=c, direction = d, t=t_before)
#     #                                     if reserve_node_type(node=n_) == :upward_spinning
#     #                     )
#     #                     <=
#     #                     (
#     #                         + (units_on[u, t_after] - units_started_up[u,t_after])
#     #                              * res_ramp_up_limit(unit=u, commodity=c, direction=d, t=t_after)
#     #                     )
#     #                    * reduce(
#     #                    +,
#     #                    unit_conv_cap_to_flow(unit=u, commodity=c2, t=t_after) *unit_capacity(unit=u, commodity=c2, direction=d, t=t_after)
#     #                      for (u2,c2) in collect(indices(minimum_operating_point;unit=u)); ### hardcoded fix!
#     #                          init=0
#     #                          )
#     #                 )
#     #         end
#     #     end
#     # end
#     constr_dict = m.ext[:constraints][:res_ramp_up_nonspin] = Dict()
#      for (u, c, d) in indices(max_res_startup_ramp)
#         for (u, t_after) in units_on_indices(unit=u)
#             for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
#                 constr_dict[u, c, d, t_before] = @constraint(
#                        m,
#                        + sum(
#                            flow[u_, n_, c_, d_, t_]
#                                    for (u_, n_, c_, d_, t_) in flow_indices(unit=u, commodity=c, direction = d, t=t_before)
#                                        if reserve_node_type(node=n_) == :upward_nonspinning
#                        )
#                        <=
#                        (
#                            + reduce(
#                                +,
#                                nonspin_starting_up[u_,n_,t_]
#                                * max_res_startup_ramp(unit=u_, commodity=c, direction=d, t=t_)
#                                    for (u_,n_,t_) in nonspin_starting_up_indices(
#                                        unit=u,node=node__commodity(commodity=expand_commodity_group(c)),t=t_before);
#                                init=0)
#                        )
#                        * reduce(
#                        +,
#                        unit_conv_cap_to_flow(unit=u, commodity=c2, t=t_after) *unit_capacity(unit=u, commodity=c2, direction=d, t=t_after)
#                          for (u2,c2) in collect(indices(minimum_operating_point;unit=u)); ### hardcoded fix!
#                              init=0
#                              )
#                    )
#            end
#        end
#    end
#    constr_dict = m.ext[:constraints][:res_min_ramp_up_nonspin] = Dict()
#     for (u, c, d) in indices(max_res_startup_ramp)
#        for (u, t_after) in units_on_indices(unit=u)
#            for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
#                constr_dict[u, c, d, t_before] = @constraint(
#                       m,
#                       + sum(
#                           flow[u_, n_, c_, d_, t_]
#                                   for (u_, n_, c_, d_, t_) in flow_indices(unit=u, commodity=c, direction = d, t=t_before)
#                                       if reserve_node_type(node=n_) == :upward_nonspinning
#                       )
#                       >=
#                       (
#                            reduce(
#                               +,
#                               nonspin_starting_up[u_,n_,t_]
#                               * minimum_operating_point(unit=u, commodity=c2, t=t_)
#                               for (u_,n_,t_) in nonspin_starting_up_indices(
#                                     unit=u,node=node__commodity(commodity=expand_commodity_group(c)),t=t_before)
#                                   for (u2,c2) in collect(indices(minimum_operating_point;unit=u)); ### this is very hard-coded quick fix!!
#                                       init=0)
#                       )
#                           *
#                           reduce(
#                           +,
#                           unit_conv_cap_to_flow(unit=u, commodity=c2,  t=t_after) *unit_capacity(unit=u, commodity=c2, direction=d, t=t_after)
#                             for (u2,c2) in collect(indices(minimum_operating_point;unit=u)); ### hardcoded fix!
#                                 init=0
#                                 )
#                   )
#           end
#       end
#   end
# end
#
# update_constraint_res_ramp_up!(m::Model) = nothing
