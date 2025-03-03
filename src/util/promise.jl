#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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

realize(x::DualPromise) = has_duals(owner_model(x.value)) ? dual(x.value) : 0.0
realize(x::ReducedCostPromise) = has_duals(owner_model(x.value)) ? reduced_cost(x.value) : 0.0

Base.:+(x::X, y::Y) where {X<:AbstractPromise,Y<:AbstractPromise} = Call(+, x, y)
