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
file_out = "$(@__DIR__)/data/new_temporal_out.sqlite"
db_url_out = "sqlite:///$file_out"
isfile(file_out) || create_results_db(db_url_out, db_url_in)

try
    m, flow, trans, stor_state, units_online,
        units_available, units_starting_up, units_shutting_down =
        run_spinemodel(db_url_in, db_url_out; optimizer=Gurobi.Optimizer)
catch
    m, flow, trans, stor_state, units_online,
        units_available, units_starting_up, units_shutting_down =
        run_spinemodel(db_url_in, db_url_out; optimizer=Cbc.Optimizer)
end
