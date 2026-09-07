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

"""
    Produces a McCormick envelope for the variable line_charging_q_cand, which
    force the variable to the appropriate value when there is one invested 
    connection, and zero otherwise. Assumes that the total number of connections
    is either 0 or 1.

    The constraint includes four actual constraints.

"""
function add_constraint_connection_line_charging!(m::Model)
    _add_constraint!(
        m,
        :connection_line_charging_tozero1,
        constraint_connection_line_charging_indices,
        _build_constraint_line_charging_tozero1,
    )
    _add_constraint!(
        m,
        :connection_line_charging_tozero2,
        constraint_connection_line_charging_indices,
        _build_constraint_line_charging_tozero2,
    )
    _add_constraint!(
        m,
        :connection_line_charging_tovalue1,
        constraint_connection_line_charging_indices,
        _build_constraint_line_charging_tovalue1,
    )
    _add_constraint!(
        m,
        :connection_line_charging_tovalue2,
        constraint_connection_line_charging_indices,
        _build_constraint_line_charging_tovalue2,
    )
end

function  _build_constraint_line_charging_tozero1(m, conn, ng, d, s_path, t)
    @fetch line_charging_q_cand, node_voltage_squared = m.ext[:spineopt].variables

    @build_constraint(
        + sum(
            get(line_charging_q_cand, (conn, n, d, s, t), 0) 
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0,
        )
        <=
        + _term_total_number_of_connections(m, conn, ng, d, s_path, t)
        * 2.0
    )
end

function  _build_constraint_line_charging_tozero2(m, conn, ng, d, s_path, t)
    @fetch line_charging_q_cand, node_voltage_squared = m.ext[:spineopt].variables

    @build_constraint(
        + sum(
            get(line_charging_q_cand, (conn, n, d, s, t), 0) 
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0,
        )
        >=
        + _term_total_number_of_connections(m, conn, ng, d, s_path, t)
        * 0.5
    )
end

function  _build_constraint_line_charging_tovalue1(m, conn, ng, d, s_path, t)
    @fetch line_charging_q_cand, node_voltage_squared = m.ext[:spineopt].variables

    @build_constraint(
        + sum(
            get(line_charging_q_cand, (conn, n, d, s, t), 0) 
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0
        )
        <= 
        + sum(
            get(node_voltage_squared, (n,s,t), 0)
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0
        )
        + (1 - _term_total_number_of_connections(m, conn, ng, d, s_path, t))
        * 0.5
    )
end

function  _build_constraint_line_charging_tovalue2(m, conn, ng, d, s_path, t)
    @fetch line_charging_q_cand, node_voltage_squared = m.ext[:spineopt].variables

    @build_constraint(
        + sum(
            get(line_charging_q_cand, (conn, n, d, s, t), 0) 
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0
        )
        >= 
        + sum(
            get(node_voltage_squared, (n,s,t), 0)
            for n in members(ng), s in s_path, t in t_in_t(m; t_long=t);
            init=0
        )
        + (1 - _term_total_number_of_connections(m, conn, ng, d, s_path, t))
        * 2.0
    )
end

function constraint_connection_line_charging_indices(m::Model)
    (
    x for x in constraint_connection_reverse_flow_capacity_indices(m)
        if x.connection in indices(line_shunt_susceptance)
    )
end
