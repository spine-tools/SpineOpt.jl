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
# Export contents of database into the current session
using SpineModel
# using MOI #necessary?
using SpineInterface
try
    using Gurobi
catch
    using Cbc
end

# Run the model from the database
# url_in = ARGS[1]
# url_out = ARGS[2]
url_in = "sqlite:///C:\\Users\\u0122387\\Documents\\EUsysflex\\project_C1_convert\\.spinetoolbox\\items\\c1_a_da_uncoord_convert\\C1_A_DA_uncoord_convert.sqlite"
# C:\Users\u0122387\Documents\EUsysflex\project_C1_convert\.spinetoolbox\items\c1_a_da_uncoord_convert\C1_A_DA_uncoord_convert.sqlite
url_out = "sqlite:///C:\\Users\\u0122387\\Documents\\EUsysflex\\project_C1_convert\\.spinetoolbox\\items\\c1_a_da_uncoord_convert\\confirm_results.sqlite"
# url_out = "sqlite:///C:\\Users\\u0122387\\Documents\\EUsysflex\\project_C1\\.spinetoolbox\\items\\a_da_uncoord_out\\confirm_result_2.sqlite"
# include("C:\\Users\\u0122387\\Desktop\\SpineModel\\model\\examples/test_script_UC_user_constraints.jl")

m = run_spinemodel(url_in, url_out; with_optimizer=SpineModel.JuMP.with_optimizer(Gurobi.Optimizer,MIPGap=0.0001,TimeLimit=600), cleanup=true)

# Show active variables and constraints
println("*** Active constraints: ***")
for key in keys(m.ext[:constraints])
    !isempty(m.ext[:constraints][key]) && println(key)
end
println("*** Active variables: ***")
for key in keys(m.ext[:variables])
    !isempty(m.ext[:variables][key]) && println(key)
end
