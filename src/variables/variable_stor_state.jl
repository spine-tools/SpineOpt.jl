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
    generate_variable_stor_state(m::Model)

A `stor_level` variable for each tuple returned by `commodity__stor()`,
attached to model `m`.
`stor_level` represents the state of the storage level.
"""
function variable_stor_state(m::Model)
    Dict{Tuple,JuMP.VariableRef}(
        (stor, c, t) => @variable(
            m, base_name="stor_state[$stor, $c, $(t.JuMP_name)]", lower_bound=0
        ) for (stor, c, t) in stor_state_indices()
    )
end


"""
    stor_state_indices(filtering_options...)

A set of tuples for indexing the `stor_state` variable. Any filtering options can be specified
for `storage`, `commodity`, and `t`.
Tuples are generated for the highest resolution 'flows' or 'trans' of the involved commodity.
"""
# NEEDS TESTING!!
function stor_state_indices(;storage=:any, commodity=:any, t=:any)
    t_connection = unique(Array{TimeSlice,1}([
        x.t for c in storage__connection(storage=storage) for x in trans_indices(connection=c, commodity=commodity, t=t)
    ]))
    t_unit = unique(Array{TimeSlice,1}([
        x.t for u in storage__unit(storage=storage) for x in flow_indices(unit=u, commodity=commodity, t=t)
    ]))
    t_all = vcat(t_highest_resolution(t_unit), t_highest_resolution(t_connection))
    [
        (storage=stor, commodity=c, t=t1)
        for (stor, c) in storage__commodity(storage=storage, commodity=commodity) for t1 in t_all
    ]
end
