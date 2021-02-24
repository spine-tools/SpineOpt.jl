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
module X end

@testset "generate missing items" begin
    SpineOpt.generate_missing_items(X)
    all_names = names(X)
    template = SpineOpt.template()
    @testset for (name,) in template["object_classes"]
        @test Symbol(name) in all_names
        @test getfield(X, Symbol(name)) isa ObjectClass
    end
    @testset for (name, _object_class_names) in template["relationship_classes"]
        @test Symbol(name) in all_names
        @test getfield(X, Symbol(name)) isa RelationshipClass
    end
    template_parameters = [template["object_parameters"]; template["relationship_parameters"]]
    @testset for (_class_name, name, _default_value) in template_parameters
        @test Symbol(name) in all_names
        @test getfield(X, Symbol(name)) isa Parameter
    end
end
