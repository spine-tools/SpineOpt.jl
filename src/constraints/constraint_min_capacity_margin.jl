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


function add_constraint_min_capacity_margin!(m::Model)
    @fetch capacity_margin = m.ext[:spineopt].expressions
    t0 = _analysis_time(m)
    m.ext[:spineopt].constraints[:min_capacity_margin] = Dict(
        (node=n, stochastic_path=s, t=t) => @constraint(
            m,
            + capacity_margin[n, s, t]            
            >=
            + min_capacity_margin[(node=n, stochastic_scenario=s, analysis_time=t0, t=t)]
        )
        for (n, s, t) in constraint_min_capacity_margin_indices(m)
    )
end

function constraint_min_capacity_margin_indices(m;)
    unique(
        (node=n, stochastic_path=s, t=t)
        for (n, s, t) in expression_capacity_margin_indices(m)
        if n in indices(min_capacity_margin)        
    )
end
    