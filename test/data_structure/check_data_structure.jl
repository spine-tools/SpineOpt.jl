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

@testset "check data structure" begin
    url_in = "sqlite://"
    _load_test_data(url_in, Dict())
    # TODO: Once we get our error messages right, we should use:
    # @test_throws ErrorException("...exception message...")
    # to make sure that the test passes for the good reasons.
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    _load_test_data(url_in, Dict())
    SpineInterface.import_data(url_in; objects=[["model", "instance"]])
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    _load_test_data(url_in, Dict())
    SpineInterface.import_data(
        url_in;
        objects=[["temporal_block", "test_temporal_block"], ["unit", "test_unit"], ["node", "test_node"]],
        relationships=[["model__temporal_block", ["instance", "test_temporal_block"]]],
    )
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
    _load_test_data(url_in, Dict())
    SpineInterface.import_data(
        url_in;
        objects=[["stochastic_structure", "test_stochastic_structure"]],
        relationships=[
            ["node__stochastic_structure", ["test_node", "test_stochastic_structure"]],
            ["model__stochastic_structure", ["instance", "test_stochastic_structure"]],
        ],
    )
    @test_throws ErrorException m = run_spineopt(url_in; log_level=0, optimize=false)
end
