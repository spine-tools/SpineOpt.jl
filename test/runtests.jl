#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

using SpineOpt
using SpineInterface
using Test
using Dates
using JuMP
using PyCall

_is_constraint_equal(con1, con2) = con1.func == con2.func && con1.set == con2.set

function _load_template(url_in)
	db_api.create_new_spine_database(url_in)
	template = Dict(Symbol(key) => value for (key, value) in SpineOpt.template)
	db_api.import_data_to_url(url_in; template...)
end

"""
	_dismember_constraint(constraint)

Show the given constraint in an organized way.
Useful for writing tests.
"""
function _dismember_constraint(constraint)
	for k in sort(collect(keys(constraint)))
		println("key: ", k)
		con_obj = constraint_object(constraint[k])
		_dismember_constraint_object(con_obj)
	end
end

function _dismember_constraint_object(con_obj)
	_dismember_function(con_obj.func)
	println("set: ", con_obj.set)
	println()
end

function _dismember_function(func)
	for (k, term) in enumerate(func.terms)
		println("term $k: ", term)
	end
	println("term constant: ", func.constant)
	println()
end

include("data_structure/check_data_structure.jl")
include("data_structure/temporal_structure.jl")
include("constraints/constraint_unit.jl")
include("constraints/constraint_node.jl")
include("constraints/constraint_connection.jl")
include("objective/objective.jl")
