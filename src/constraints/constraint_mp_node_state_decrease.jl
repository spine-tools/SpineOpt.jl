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

"""
    add_constraint_mp_node_state_decrease!(m::Model)

Limit the decrease in node state between timeslices in the master problem to `decomposed_max_state_decrease`, if it exists.

"""
function add_constraint_mp_node_state_decrease!(m::Model)
    @fetch node_state = m.ext[:variables]
    t0 = startref(current_window(m))
    m.ext[:constraints][:mp_node_state_decrease] = Dict(
        (node=ng, stochastic_scenario=s, t_before=t_before, t_after=t_after) => @constraint(
            m,
            - expr_sum(
                    +node_state[ng, s, t_after]
                    for (ng, s, t_after) in node_state_indices(m; node=ng, stochastic_scenario=s, t=t_after);
                    init=0,
                )
            + expr_sum(
                +node_state[ng, s, t_before]            
                for (ng, s, t_before) in node_state_indices(m; node=ng, stochastic_scenario=s, t=t_before);                    
                init=0,
            )      
            <=
            +decomposed_max_state_decrease[(node=ng, stochastic_scenario=s, analysis_time=t0, t=t_before)]            
            *min(duration(t_before), duration(t_after))
        ) for (ng, s, t) in constraint_mp_node_state_decrease_indices(m)
    )
end


"""
    constraint_mp_node_state_decrease_indices(m::Model; filtering_options...)

Form the stochastic index array for the `:constraint_mp_node_state_increase` constraint.

Uses stochastic path indices of the `node_state` variables. Keyword arguments can be used to filter the resulting 
"""
function constraint_mp_node_state_decrease_indices(
    m::Model;    
    node=anything,    
    stochastic_path=anything,
    t_before=anything,
    t_after=anything,
)
    unique(
        (node=ng, stochastic_path=path, t_before=t_before, t_after=t_after)                       
        for (ng, s, t_after) in node_state_indices(m; node=node) 
            if ng in mp_storage_node && ng in indices(decomposed_max_state_decrease)
        for (ng, t_before, t_after) in node_dynamic_time_indices(m; node=ng, t_before=t_before, t_after=t_after)
        for path in active_stochastic_paths(unique(
            ind.stochastic_scenario for ind in node_state_indices(m; node=ng, t=[t_before, t_after])
        )) if path == stochastic_path || path in stochastic_path
        
    )
end

