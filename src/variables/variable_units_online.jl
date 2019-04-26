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
    generate_units_online(m::Model)

#TODO: add model descirption here
"""
function variable_units_online(m::Model)
    @butcher Dict{Tuple,JuMP.VariableRef}(
        (u, t) => @variable(
            m, base_name="units_online[$u, $(t.JuMP_name)]", lower_bound=0
        ) for (u, t) in unit_online_indices()
    )
end


"""
    unit_online_indices(filtering_options...)

A set of tuples for indexing the `flow` variable. Any filtering options can be specified
for `commodity`, `node`, `unit`, `direction`, and `t`.
"""
function unit_online_indices(;unit=:any,t=:any)
    [
        (unit=u, t=t1) for u in SpineModel.unit(
        ) for t1 in t_highest_resolution([t_list
            for clock in unit__node__direction__temporal_block(
            unit=u,node=:any,direction=:any, _compact=true
            ) for t_list in time_slice(temporal_block=clock)]
        ) if t_in_t_list(t1, t)
    ]
end
