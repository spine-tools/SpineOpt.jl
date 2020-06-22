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

@testset "add connection relationships" begin
    url_in = "sqlite:///$(@__DIR__)/test.sqlite"
    test_data = Dict(
        :objects => [["connection", "connection_ab"], ["node", "node_a"], ["node", "node_b"]],
        :relationships => [
            ["connection__from_node", ["connection_ab", "node_a"]], 
            ["connection__to_node", ["connection_ab", "node_b"]]
        ],
        :object_parameter_values => [
            ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"]
        ]
    )
    _load_template(url_in)
    db_api.import_data_to_url(url_in; test_data...)
    using_spinedb(url_in, SpineOpt)
    SpineOpt.add_connection_relationships()
    conn_ab = connection(:connection_ab)
    n_a = node(:node_a)
    n_b = node(:node_b)
    @test length(connection__from_node()) == 2
    @test isempty(symdiff(connection__from_node(), connection__to_node()))
    @test (connection=conn_ab, node=n_a) in connection__from_node()
    @test (connection=conn_ab, node=n_b) in connection__from_node()
    @test length(connection__node__node()) == 2
    @test (connection=conn_ab, node1=n_a, node2=n_b) in connection__node__node()
    @test (connection=conn_ab, node1=n_b, node2=n_a) in connection__node__node()
    @test connection_conv_cap_to_flow(connection=conn_ab, node=n_a) == 1
    @test connection_conv_cap_to_flow(connection=conn_ab, node=n_b) == 1
    @test fix_ratio_out_in_connection_flow(connection=conn_ab, node1=n_a, node2=n_b) == 1
    @test fix_ratio_out_in_connection_flow(connection=conn_ab, node1=n_b, node2=n_a) == 1
end