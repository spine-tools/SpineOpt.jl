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

import SpineInterface: realize

abstract type AbstractPromise end

struct DualPromise <: AbstractPromise
    value::JuMP.ConstraintRef
end

struct ReducedCostPromise <: AbstractPromise
    value::JuMP.VariableRef
end

realize(x::T) where T <: AbstractPromise = x.value

function JuMP.dual(x::DualPromise)
    realized = realize(x)
    has_duals(owner_model(realized)) ? dual(realized) : nothing
end

function JuMP.reduced_cost(x::ReducedCostPromise)
    realized = realize(x)
    has_duals(owner_model(realized)) ? reduced_cost(realized) : nothing
end

function SpineInterface.db_value(x::TimeSeries{T}) where T <: DualPromise
    db_value(TimeSeries(x.indexes, JuMP.dual.(x.values), x.ignore_year, x.repeat))
end
function SpineInterface.db_value(x::TimeSeries{T}) where T <: ReducedCostPromise
    db_value(TimeSeries(x.indexes, JuMP.reduced_cost.(x.values), x.ignore_year, x.repeat))
end

Base.:+(x::X, y::Y) where {X<:AbstractPromise,Y<:AbstractPromise} = Call(+, x, y)
