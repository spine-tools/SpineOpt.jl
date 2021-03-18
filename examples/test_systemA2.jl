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
using SpineOpt
using Gurobi

#include("test_systemA2_extend_functions.jl")


db_url_in = "sqlite:///C:\\Users\\u0122387\\Documents\\Spine\\Gas_study\\Gas_study_project\\.spinetoolbox\\items\\advanced_db\\advanced_db_gas.sqlite"
db_url_out = "sqlite:///C:\\Users\\u0122387\\Documents\\Spine\\Gas_study\\Gas_study_project\\.spinetoolbox\\items\\advanced_db\\advanced_db_gas_out.sqlite"
m = run_spineopt(db_url_in,db_url_out,mip_solver = optimizer_with_attributes(Gurobi.Optimizer))#, add_user_variables=m -> add_variables_for_gas(m))#, add_constraints -> add_constraints_for_gas(m))
