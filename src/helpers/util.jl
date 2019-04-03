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

const iso8601dateformat = dateformat"y-m-dTH:M:S" 

"""
    pack_trailing_dims(dictionary::Dict, n::Int64=1)

An equivalent dictionary where the last `n` dimensions are packed into a matrix
"""
function pack_trailing_dims(dictionary::Dict, n::Int64=1)
    left_dict = Dict{Any,Any}()
    for (key, value) in dictionary
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
    value(dictionary::Dict)

An equivalent dictionary where values are gathered using `JuMP.value`.
"""
value(dictionary::Dict) = Dict(k => JuMP.value(v) for (k, v) in dictionary)


"""
    checkout_spinemodeldb(db_url)

Generate and export convenience functions for accessing the database at the given url.
Use custom `parse_value` and `get_value`.
"""
function checkout_spinemodeldb(db_url; upgrade=false)
    checkout_spinedb(db_url; parse_value=parse_value, get_value=get_value, upgrade=upgrade)
end
