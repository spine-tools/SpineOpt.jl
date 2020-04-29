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
    postprocess_results!(m::Model)

Perform calculations on the model outputs and save them to the ext.values dict.
bases on contents of report__output
"""

function postprocess_results!(m::Model)
    outputs = [Symbol(x[2]) for x in report__output()]

    if :connection_avg_throughflow in outputs
        save_connection_avg_throughflow!(m)
    end
end

# TODO: Try and refactor this so it accounts for different time resolution in connection nodes
function save_connection_avg_throughflow!(m::Model)
    @fetch connection_flow = m.ext[:variables]
    val = m.ext[:values][:connection_avg_throughflow] = Dict{NamedTuple{(:connection, :t),Tuple{SpineInterface.Object,SpineInterface.TimeSlice}},Number}()

    for conn in connection(connection_monitored=:value_true, has_ptdf=true)
        for (conn, n_to, d, t) in connection_flow_indices(;
                connection=conn, last(connection__from_node(connection=conn))...
            ) # NOTE: always assume that the second (last) node in `connection__from_node` is the 'to' node
            end_(t) <= end_(current_window) || continue
            for (conn, n_from, d, t) in connection_flow_indices(;
                    connection=conn, first(connection__from_node(connection=conn))...
                )
                val[(connection=conn, t=t)] = (
                    + JuMP.value(connection_flow[conn, n_to, direction(:to_node), t])
                    - JuMP.value(connection_flow[conn, n_to, direction(:from_node), t])
                    - JuMP.value(connection_flow[conn, n_from, direction(:to_node), t])
                    + JuMP.value(connection_flow[conn, n_from, direction(:from_node), t])
                ) / 2
            end
        end
    end
end
