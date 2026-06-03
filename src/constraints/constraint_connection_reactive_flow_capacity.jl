#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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


function add_constraint_connection_reactive_flow_capacity!(m::Model)
    _add_constraint!(
        m,
        :connection_reactive_flow_capacity,
        constraint_connection_reverse_flow_capacity_indices,
        _build_constraint_connection_reactive_flow_capacity,
    )
    _add_constraint!(
        m,
        :connection_reverse_reactive_flow_capacity,
        constraint_connection_reverse_flow_capacity_indices,
        _build_constraint_connection_reverse_reactive_flow_capacity,
    )
end

function  _build_constraint_connection_reactive_flow_capacity(m, conn, ng, d, s_path, t)
    @fetch connection_flow_reactive = m.ext[:spineopt].variables

    @build_constraint(
        + sum(
            get(connection_flow_reactive, (conn, n, d, s, t), 0) * duration(t)
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0,
        )
        <=
        + _term_total_number_of_connections(m, conn, ng, d, s_path, t)
        * _term_connection_flow_capacity(m, conn, ng, d, s_path, t)
    )
end
    
function  _build_constraint_connection_reverse_reactive_flow_capacity(m, conn, ng, d, s_path, t)
    @fetch connection_flow_reactive = m.ext[:spineopt].variables

    @build_constraint(
        + sum(
            get(connection_flow_reactive, (conn, n, d, s, t), 0) * duration(t)
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0,
        )
        >=
        - _term_total_number_of_connections(m, conn, ng, d, s_path, t)
        * _term_connection_flow_capacity(m, conn, ng, d, s_path, t)
    )
end