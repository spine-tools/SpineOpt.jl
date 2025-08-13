#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
using Pkg
import JSON
import MathOptInterface as MOI

# Resolve JuMP and SpineInterface `Parameter` and `parameter_value` conflicts.
import SpineInterface: Parameter, parameter_value

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

# Test code uses legacy syntax for `import_data`, so interpret here.
SpineInterface.import_data(db_url::String; kwargs...) = SpineInterface.import_data(db_url, "testing"; kwargs...)

# Convenience function for resetting the test in-memory db with the `SpineOpt.template`.
function _load_test_data(db_url, test_data)
    data = Dict(Symbol(key) => value for (key, value) in SpineOpt.template())
    merge!(append!, data, test_data)
    _load_test_data_without_template(db_url, data)
end

function _load_test_data_without_template(db_url, test_data)
    SpineInterface.close_connection(db_url)
    SpineInterface.open_connection(db_url)
    SpineInterface.import_data(db_url; test_data...)
end

function _is_constraint_equal(left, right)
    if !_is_constraint_equal_kernel(left, right)
        println("LEFT")
        _show_constraint(left)
        println("RIGHT")
        _show_constraint(right)
        false
    else
        true
    end
end

function _show_constraint(con)
    for (var, coef) in sort(con.func.terms; by=name)
        println(_signed_string(coef), " ", var)
    end
    println(_signed_string(con.func.constant))
    println(_sense_string(con.set))
    println(_signed_string(con.set))
    println("")
end

_signed_string(x) = string(x >= 0 ? "+" : "-", " ", abs(x))
_signed_string(s::MOI.LessThan) = _signed_string(s.upper)
_signed_string(s::MOI.EqualTo) = _signed_string(s.value)
_signed_string(s::MOI.GreaterThan) = _signed_string(s.lower)

_sense_string(::MOI.LessThan) = "<="
_sense_string(::MOI.EqualTo) = "=="
_sense_string(::MOI.GreaterThan) = ">="

function _is_constraint_equal_kernel(left, right)
    left_terms, right_terms = left.func.terms, right.func.terms
    missing_in_right = setdiff(keys(left_terms), keys(right_terms))
    if !isempty(missing_in_right)
        @error string("missing in right constraint: ", missing_in_right)
        return false
    end
    missing_in_left = setdiff(keys(right_terms), keys(left_terms))
    if !isempty(missing_in_left)
        @error string("missing in left constraint: ", missing_in_left)
        return false
    end
    result = true
    for k in keys(left_terms)
        if !isapprox(left_terms[k], right_terms[k])
            @error string(left_terms[k], " != ", right_terms[k])
            result = false
        end
    end
    if left.set != right.set
        @error string(left.set, " != ", right.set)
        result = false
    end
    result
end

function _is_expression_equal(x, y)
    x_terms, y_terms = x.terms, y.terms
    keys(x_terms) == keys(y_terms) && all(isapprox(realize(x_terms[k]), realize(y_terms[k])) for k in keys(x_terms))
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

@testset begin
    include("data_structure/migration.jl")
    include("data_structure/check_data_structure.jl")
    include("data_structure/check_economic_structure.jl") 
    include("data_structure/preprocess_data_structure.jl")
    include("data_structure/temporal_structure.jl")
    include("data_structure/stochastic_structure.jl")
    include("data_structure/postprocess_results.jl")
    include("expressions/expression.jl")
    include("constraints/constraint_unit.jl") # CRASHES with multithreading?
    include("constraints/constraint_node.jl") # CRASHES with multithreading?
    include("constraints/constraint_connection.jl") # CRASHES with multithreading?
    include("constraints/constraint_user_constraint.jl")
    include("constraints/constraint_investment_group.jl") # CRASHES with multithreading?
    include("objective/objective.jl") # CRASHES with multithreading?
    include("variables/variables.jl")
    include("util/misc.jl")
    include("run_spineopt.jl") # CRASHES with multithreading?
    include("run_spineopt_benders.jl")
    include("run_spineopt_multi_stage.jl")
    include("run_spineopt_investments.jl")
    include("run_spineopt_mga.jl") # CRASHES with multithreading?
    include("run_spineopt_monte_carlo.jl")
    include("run_spineopt_representative_periods.jl") # FREEZES with multithreading?
    include("run_examples.jl") # CRASHES with multithreading?
    include("run_benchmark_data.jl") # CRASHES with multithreading?
    include("run_spineopt_hsj_mga.jl")
end

