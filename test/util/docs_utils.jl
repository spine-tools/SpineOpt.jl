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

@testset "docs_utils" begin
	default_translation = Dict(
	    ["relationship_classes"] => "Relationship Classes",
	    ["parameter_value_lists"] => "Parameter Value Lists",
	    ["object_parameters", "relationship_parameters"] => "Parameters",
	    ["object_classes"] => "Object Classes",
	)
	concept_dictionary = SpineOpt.initialize_concept_dictionary(SpineOpt.template(); translation=default_translation)
	@test Set(keys(concept_dictionary)) == Set(values(default_translation))
	concept_dictionary = SpineOpt.add_cross_references!(concept_dictionary)
	@test Set(keys(concept_dictionary)) == Set(values(default_translation))
	path = mktempdir()
	cpt_ref_path = joinpath(path, "src", "concept_reference")
	mkpath(cpt_ref_path)
	for (filename, concepts) in concept_dictionary
        # Loop over the unique names and write their information into the filename under a dedicated section.
        for concept in unique!(collect(keys(concepts)))
            description_path = joinpath(cpt_ref_path, "$(concept).md")
            write(description_path, "\n\n")
        end
    end
	@test SpineOpt.write_concept_reference_files(concept_dictionary, path) == 0

	pages=["Util" => nothing]
	testpages=["Util" => Any["Docs utils" => joinpath("util", "docs_utils.md")]]
	@test SpineOpt.drag_and_drop(pages,dirname(@__DIR__)) == testpages
end