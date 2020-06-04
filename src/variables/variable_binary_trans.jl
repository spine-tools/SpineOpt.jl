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
    variable_binary_trans(m::Model)

Create the `binary_trans` variable for the model `m`.

This variable enforces unidirectional flow for each timestep.

"""
function create_binary_trans!(m::Model)
    KeyType = NamedTuple{(:connection, :node, :direction, :t),Tuple{Object,Object,Object,TimeSlice}}
    m.ext[:variables][:binary_trans] = Dict{KeyType,Any}(
        (connection=conn, node=n, direction=d, t=t) => @variable(
            m, base_name="binary_trans[$conn,$n,$d, $(t.JuMP_name)]", binary=true
        )
        for (conn, n,c,d,t) in trans_indices()
            if unitary_trans(connection=conn, node= n, direction=d) == :unitary_trans
    )
end
