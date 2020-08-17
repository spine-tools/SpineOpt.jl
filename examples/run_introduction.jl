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
using SpineOpt
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
url_in = "sqlite:///C:\\Users\\u0122387\\Documents\\Spine\\Spine Introduction\\.spinetoolbox\\items\\minimal_example\\C2_A_DA_master.sqlite"
url_out = "sqlite:///C:\\Users\\u0122387\\Documents\\Spine\\Spine Introduction\\.spinetoolbox\\items\\minimal_example\\C2_A_DA_master_out.sqlite"# url_in = "sqlite:///$(@__DIR__)\\data\\minimal example.sqlite"
# url_out = "sqlite:///$(@__DIR__)\\data\\minimal example_out.sqlite"

m = run_spineopt(url_in, url_out; with_optimizer=SpineOpt.JuMP.with_optimizer(Gurobi.Optimizer,MIPGap=0.001,TimeLimit=600), cleanup=true)

# Show active variables and constraints
println("*** Active constraints: ***")
for key in keys(m.ext[:constraints])
    !isempty(m.ext[:constraints][key]) && println(key)
end
println("*** Active variables: ***")
for key in keys(m.ext[:variables])
    !isempty(m.ext[:variables][key]) && println(key)
end
