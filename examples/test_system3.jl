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
using Revise
using SpineModel
using SpineInterface
try
    using Gurobi
catch
    using Cbc
end

db_url_in = "sqlite:///$(@__DIR__)/data/new_temporal.sqlite"
db_url_out = "sqlite:///$(@__DIR__)/data/new_temporal_out.sqlite"
m = try
    run_spinemodel(db_url_in, db_url_out; optimizer=Gurobi.Optimizer)
catch
     run_spinemodel(db_url_in, db_url_out; optimizer=Cbc.Optimizer)
end
