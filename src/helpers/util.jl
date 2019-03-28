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
    matrix_value(variable::Dict, n::Int64=1)

Take `variable` and return a new Dict where the last `n` dimensions are assembled into a matrix
"""
function matrix_value(variable::Dict{Tuple{Vararg{T,N}},S}, n::Int64=1) where T where N where S
    left_dict = Dict{Any,Any}()
    for (key, value) in variable
        # TODO: handle length(key) < n and stuff like that?
        left_key = key[1:end-n]
        if length(left_key) == 1
            left_key = left_key[1]
        end
        right_key = key[end-n+1:end]
        right_dict = get!(left_dict, left_key, Dict())
        right_dict[right_key] = value
    end
    Dict(key => reshape([v for (k, v) in sort(collect(value))], :, n) for (key, value) in left_dict)
end


"""
    value(variable::Dict)
"""
value(variable::Dict) = Dict(k => JuMP.value(v) for (k, v) in variable)
