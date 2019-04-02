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


"""
    objective_minimize_production_cost(m::Model, flow)

Minimize the `production_cost` correspond to the sum over all
`conversion_cost` of each `unit`.
"""
function objective_minimize_production_cost(m::Model, flow)
    @butcher begin
        production_cost = zero(AffExpr)
        #for t in time_slice()
        #    for (c, n, u, d) in commodity__node__unit__direction()
        #        if haskey(flow, (c, n, u, d, t)) && conversion_cost(unit__commodity=(u, c)) != nothing
        #            production_cost += flow[c, n, u, d, t] * conversion_cost(unit__commodity=(u, c))
        #        end
        #    end
        #end
        for (c, n, u, d) in commodity__node__unit__direction(), t in time_slice()
            if haskey(flow, (c, n, u, d, t)) && (u, c) in unit__commodity()
                production_cost += flow[c, n, u, d, t] * conversion_cost(unit__commodity=(u, c))
            end
        end
        @objective(m, Min, production_cost)
    end
end
