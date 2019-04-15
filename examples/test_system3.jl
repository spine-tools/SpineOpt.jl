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

db_url_in = "sqlite:///$(@__DIR__)/data/new_temporal.sqlite"
file_out = "$(@__DIR__)/data/new_temporal_out.sqlite"
db_url_out = "sqlite:///$file_out"
isfile(file_out) || create_results_db(db_url_out, db_url_in)
# NOTE: This below can't be in a function, otherwise the exported functions are the wrong world age...
printstyled("Creating convenience functions...\n"; bold=true)
@time checkout_spinemodeldb(db_url_in; upgrade=true)
printstyled("Creating temporal structure...\n"; bold=true)
@time begin
    generate_time_slice()
    generate_time_slice_relationships()
end
printstyled("Running Spine model...\n"; bold=true)

try
    using Gurobi
    run_spinemodel(db_url_in, db_url_out; optimizer=Gurobi.Optimizer)
catch
    using Clp
    run_spinemodel(db_url_in, db_url_out; optimizer=Clp.Optimizer)
end
