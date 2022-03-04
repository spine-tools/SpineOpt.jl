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

@testset "check migration scripts" begin
    @testset "check version upgrade *3* to *4*" begin
        url_in = "sqlite://"
        test_data = Dict(
        )
        _load_test_data(url_in, test_data)
        parameter_value_lists = [
            ["model_type_list","spineopt_operations"],
            ["model_type_list","spineopt_master"],
            ["model_type_list","spineopt_other"]
        ]
        object_parameter_values = [
            ["model", "instance", "model_type", "spineopt_operations"],
            ["model", "master_instance", "model_type", "spineopt_master"],
        ]
        object_parameters = [
            ["settings", "version", 3, "try", "try"],
        ]
        SpineInterface.import_data(
            url_in;
            parameter_value_lists=parameter_value_lists,
            object_parameter_values=object_parameter_values,
            object_parameters=object_parameters
        )
        SpineOpt.find_version(url_in)
        version = SpineOpt.find_version(url_in)
        log_level = 3
        SpineOpt.run_migrations(url, version, log_level)
        model_master = SpineOpt.model(:master_instance)
        model_operations = SpineOpt.model(:instance)
        @test model_type(model=model_master) == :spineopt_benders_master
        @test model_type(model=model_operations) == :spineopt_standard
    end
end
