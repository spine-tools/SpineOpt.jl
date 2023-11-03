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

function t_lowest_resolution_path(m, indices)
    scens_by_t = Dict()
    for x in indices
        scens = get!(scens_by_t, x.t) do
            Set{Object}()
        end
        push!(scens, x.stochastic_scenario)
    end
    (
        (t, path)
        for (t, scens) in t_lowest_resolution_sets!(scens_by_t)
        for path in active_stochastic_paths(m, scens)
    )
end

function past_units_on_indices(m, u, s, t, min_time)
    t0 = _analysis_time(m)
    units_on_indices(
        m;
        unit=u,
        stochastic_scenario=s,
        t=to_time_slice(
            m; t=TimeSlice(end_(t) - min_time(unit=u, analysis_time=t0, stochastic_scenario=s, t=t), end_(t))
        ),
        temporal_block=anything
    )    
end

function _minimum_operating_point(u, ng, d, s, t0, t)
    minimum_operating_point[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t, _default=1)]
end

function _unit_flow_capacity(u, ng, d, s, t0, t)
    (
        + unit_capacity[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
        * unit_conv_cap_to_flow[(unit=u, node=ng, direction=d, stochastic_scenario=s, analysis_time=t0, t=t)]
    )
end