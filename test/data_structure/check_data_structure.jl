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

@testset "check data structure" begin
    url_in = "sqlite://"
    db_map = _load_test_data(url_in, Dict())
    db_map.commit_session("Add test data")
    # TODO: Once we get our error messages right, we should use:
    # @test_throws ErrorException("...exception message...")
    # to make sure that the test passes for the good reasons.
    @test_throws ErrorException m = run_spineopt(db_map; log_level=0, optimize=false)
    db_map = _load_test_data(url_in, Dict())
    db_api.import_data(db_map; objects=[["model", "instance"]])
    db_map.commit_session("Add test data")
    @test_throws ErrorException m = run_spineopt(db_map; log_level=0, optimize=false)
    db_map = _load_test_data(url_in, Dict())
    db_api.import_data(
        db_map; 
        objects=[["temporal_block", "test_temporal_block"], ["unit", "test_unit"], ["node", "test_node"]],
        relationships=[["model__temporal_block", ["instance", "test_temporal_block"]]]
    )
    db_map.commit_session("Add test data")
    @test_throws ErrorException m = run_spineopt(db_map; log_level=0, optimize=false)
    db_map = _load_test_data(url_in, Dict())
    db_api.import_data(
        db_map; 
        objects=[["stochastic_structure", "test_stochastic_structure"]],
        relationships=[
            ["node__stochastic_structure", ["test_node", "test_stochastic_structure"]],
            ["model__stochastic_structure", ["instance", "test_stochastic_structure"]]
        ]
    )
    db_map.commit_session("Add test data")
    @test_throws ErrorException m = run_spineopt(db_map; log_level=0, optimize=false)
end