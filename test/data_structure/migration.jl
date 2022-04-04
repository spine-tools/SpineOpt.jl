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

module Y end

@testset "find_version" begin
	url = "sqlite://"
	dbh = SpineInterface._create_db_handler(url, false)
    # With no data
    dbh.open_connection()
	@test SpineOpt.find_version(url) == 1
    dbh.close_connection()
    # With settings class only
    dbh.open_connection()
	data = Dict(:object_classes => ["settings"])
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 1
    dbh.close_connection()
    # With settings class and integer version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", 8)])
    dbh.open_connection()
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 8
    dbh.close_connection()
    # With settings class and string version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", "77")])
    dbh.open_connection()
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 77
    dbh.close_connection()
    # With settings class and float version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", 44.0)])
    dbh.open_connection()
    SpineInterface.import_data(url; data...)
	@test SpineOpt.find_version(url) == 44
    dbh.close_connection()
    # With settings class and invalid version parameter value
	data = Dict(:object_classes => ["settings"], :object_parameters => [("settings", "version", "latest")])
    dbh.open_connection()
    SpineInterface.import_data(url; data...)
	@test_throws ArgumentError SpineOpt.find_version(url)
    dbh.close_connection()
end

@testset "run_migrations" begin
	file_path, io = mktemp()
	url = "sqlite:///$file_path"
	SpineOpt.run_migrations(url, 1, 0)
	using_spinedb(url, Y)
	template = SpineOpt.template()
	object_class_names = [Symbol(x[1]) for x in template["object_classes"]]
	relationship_class_names = [Symbol(x[1]) for x in template["relationship_classes"]]
	parameter_names = vcat(
		[Symbol(x[2]) for x in template["object_parameters"]],
		[Symbol(x[2]) for x in template["relationship_parameters"]]
	)
	@test Set([x.name for x in object_classes(Y)]) == Set(object_class_names)
	@test Set([x.name for x in relationship_classes(Y)]) == Set(relationship_class_names)
	@test Set([x.name for x in parameters(Y)]) == Set(parameter_names)
	dummy = Object(:dummy, :settings)
	add_objects!(Y.settings, [dummy])
	@test Y.version(settings=dummy) == SpineOpt.current_version()
end