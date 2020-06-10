# TODO: take care of ramp down constraints
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
#     constraint_ramp_down(m::Model)
#
# Limit the maximum ramp of `flow` of a `unit` if the parameters
# `ramp_down_limit,unit_capacity,unit_conv_cap_to_flow, minimum_operating_point` exist.
# """
# ## TODO: use method parameter, remove replace with camp constraint
# ### TODO: What happends if I want to define flow_ramp on a higher temporal resolution than units_on?
# ###TODO: use method parameter
# function add_constraint_res_ramp_down!(m::Model)
#     @fetch flow, units_on,  units_shut_down, units_started_up = m.ext[:variables]
#     constr_dict = m.ext[:constraints][:res_ramp_down] = Dict()
#      for (u, c, d) in indices(res_ramp_down_limit)
#          for (u, t_after) in unit_on_indices(unit=u)
#              for (u,t_before) in units_on_indices(unit=u,t=t_before_t(t_after=t_after))
#                  constr_dict[u, c, d, t_before] = @constraint(
#                     m,
#                     + sum(
#                         flow[u_, n_, c_, d_, t_]
#                                 for (u_, n_, c_, d_, t_) in flow_indices(unit=u, commodity=c, direction = d, t=t_before)
#                                     if reserve_node_type(node=n_)==:downward_spinning || :downward_nonspinning
#                     )
#                     <=
#                     (
#                         + (units_on[u, t_after] - units_started_up[u,t_after] -
#                             reduce(
#                                 +,
#                                 nonspin_shutting_down[u_,n_,t_]
#                                 for (u_,n_,t_) in nonspin_shutting_down_indices(unit=u,node=node__commodity(commodity=c),t=t_before);
#                                     init=0)
#                                 )
#                              * res_ramp_down_limit(unit=u, commodity=c, direction=d, t=t)
#                          + reduce(
#                              +,
#                              nonspin_starting_up[u_,n_,t_]
#                              * max_res_startup_ramp(unit=u_, commodity=c, direction=d, t=t_)
#                                 for (u_,n_,t_) in nonspin_starting_up_indices(unit=u,node=node__commodity(commodity=c),t=t_before);
#                                  init=0)
#                                  )
#                     * unit_conv_cap_to_flow(unit=u, commodity=c, direction=d, t=t) *unit_capacity(unit=u, commodity=c, direction=d, t=t)
#                 )
#             end
#         end
#     end
# end
#
# update_constraint_res_ramp_down!(m::Model) = nothing
