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

import SpineOpt:
    time_slice,
    to_time_slice,
    history_time_slice,
    t_in_t,
    t_before_t,
    t_overlaps_t,
    generate_temporal_structure!,
    roll_temporal_structure!,
    unit_dynamic_time_indices,
    unit_investment_dynamic_time_indices,
    connection_investment_dynamic_time_indices,
    node_dynamic_time_indices,
    node_stochastic_time_indices,
    unit_stochastic_time_indices,
    node_investment_dynamic_time_indices

_is_constraint_equal(con1, con2) = con1.func == con2.func && con1.set == con2.set

function _load_test_data(db_url, test_data)
    SpineInterface._import_spinedb_api()
    db_map = db_api.DatabaseMapping(db_url; create=true)
    data = Dict(Symbol(key) => value for (key, value) in SpineOpt.template())
    merge!(data, test_data)
    db_api.import_data(db_map; data...)
    db_map
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
end

function SpineOpt.run_spineopt(db_map::PyObject, url_out::String; kwargs...)
    using_spinedb(db_map, SpineOpt)
    SpineOpt.generate_missing_items() 
    if !isempty(model(model_type=:spineopt_master))
        rerun_spineopt_mp(url_out; kwargs...)
    else
        rerun_spineopt(url_out; kwargs...)
    end
end
SpineOpt.run_spineopt(db_map::PyObject; kwargs...) = run_spineopt(db_map, db_map.db_url; kwargs...)

@testset begin
    include("data_structure/check_data_structure.jl")
    include("data_structure/preprocess_data_structure.jl")
    include("data_structure/generate_missing_items.jl")
    include("data_structure/temporal_structure.jl")
    include("data_structure/stochastic_structure.jl")
    include("constraints/constraint_unit.jl")
    include("constraints/constraint_node.jl")
    include("constraints/constraint_connection.jl")
    include("objective/objective.jl")
    include("util/misc.jl")
    include("util/postprocess_results.jl")
    include("run_spineopt.jl")
end
