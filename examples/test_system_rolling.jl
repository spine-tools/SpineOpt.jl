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
using SpineInterface

db_url = "sqlite:///$(@__DIR__)/data/test_rolling.sqlite"
# The database only has one `temporal_block` and one `rolling` object, so `run_spinemodel` doesn't work for now.
# You're welcome to fix this by adding some data to `test_rolling.sqlite`
# run_spinemodel(db_url)

# The following is just for illustration purposes. If shows all the steps of the rolling horizon optimization,
# their blocks and time slices per block
using_spinedb(db_url)
for (step, block_time_slices) in enumerate(SpineModel.block_time_slices_split())
    @show step
    for (block, time_slices) in block_time_slices
        @show block
        @show time_slices
    end
end
