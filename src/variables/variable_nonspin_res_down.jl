#TODO: add this later on 
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
# """
#     units_on_indices(unit=anything, t=anything)
#
# A list of `NamedTuple`s corresponding to indices of the `units_on` variable.
# The keyword arguments act as filters for each dimension.
# """
# function nonspin_starting_up_indices(;unit=anything, t=anything, node=anything)
#     [
#         (unit=u, node=n, t=t_)
#             for u_ in intersect(SpineModel.unit(),unit)
#                 for (u,c,d) in filter(x -> x.unit in u_,collect(indices(max_res_startup_ramp)))
#                     for n in intersect(SpineModel.node(), node)
#                         for t_ in t_highest_resolution(unique(x.t for x in flow_indices(unit=u, node=n, t=t)))
#                             if reserve_node_type(node=n) == :upward_nonspinning
#     ]
# end
# function nonspin_shutting_down_indices(;unit=anything, t=anything, node=anything)
#     [
#         (unit=u, node=n, t=t_)
#             for u in intersect(SpineModel.unit(), unit)
#                 for n in intersect(SpineModel.node(), node)
#                     for t_ in t_highest_resolution(unique(x.t for x in flow_indices(unit=u, node=n, t=t)))
#                         if reserve_node_type(node=n) == :downward_nonspinning
#     ]
# end
#
# fix_nonspin_starting_up_(x) = fix_nonspin_starting_up(unit=x.unit, node=x.node, t=x.t, _strict=false)
# fix_nonspin_shutting_down_(x) = fix_nonspin_shutting_down(unit=x.unit, node=x.node, t=x.t, _strict=false)
# nonspin_starting_up_bin(x) = online_variable_type(unit=x.unit) == :binary
# nonspin_shutting_down_bin(x) = online_variable_type(unit=x.unit) == :binary
# nonspin_starting_up_int(x) = online_variable_type(unit=x.unit) == :integer
# nonspin_shutting_down_int(x) = online_variable_type(unit=x.unit) == :integer
#
# function create_variable_nonspin_starting_up!(m::Model)
#     create_variable!(m, :nonspin_starting_up, nonspin_starting_up_indices; lb=x -> 0, bin=nonspin_starting_up_bin, int=nonspin_starting_up_int)
# end
# function create_variable_nonspin_shutting_down!(m::Model)
#     create_variable!(m, :nonspin_shutting_down, nonspin_shutting_down_indices; lb=x -> 0, bin=nonspin_shutting_down_bin, int=nonspin_shutting_down_int)
# end
#
# fix_variable_nonspin_starting_up!(m::Model) = fix_variable!(m, :nonspin_starting_up, nonspin_starting_up_indices, fix_nonspin_starting_up_)
# fix_variable_nonspin_shutting_down!(m::Model) = fix_variable!(m, :nonspin_shutting_down, nonspin_shutting_down_indices,fix_nonspin_shutting_down_)
