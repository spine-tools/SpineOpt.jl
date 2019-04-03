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


struct TimeSeries
    keys::Array{DateTime,1}
    values::Array{N,1} where N
    TimeSeries(k,v) = length(k) != length(v) ? error("lengths don't match") : new(k,v)
end


function Base.show(io::IO, ts::TimeSeries)
    # TODO: this needs more work
    Base.show(id, Dict(zip(ts.keys, ts.values)))
end
