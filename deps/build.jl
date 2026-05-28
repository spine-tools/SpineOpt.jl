using SpineInterface
using JSON

const template = JSON.parsefile(joinpath(@__DIR__, "..", "templates", "spineopt_template.json"))
const preproc_template = JSON.parsefile(joinpath(@__DIR__, "..", "templates", "preprocessing_template.json"))

merge!(append!, template, preproc_template)

pkgroot = normpath(joinpath(@__DIR__, ".."))
pkgroot_unix = replace(pkgroot, '\\' => '/')
srcfile = joinpath(pkgroot, "src", "convenience_functions.jl")

# Only regenerate the generated `convenience_functions.jl` when this package
# appears to be a development checkout. Heuristics:
# - if the package root contains a `.git` folder, or
# - if it is NOT located under the hashed `.julia/packages` depot folder.
if isdir(joinpath(pkgroot, ".git")) || !occursin("/.julia/packages/", lowercase(pkgroot_unix))
	@info "Generating convenience_functions.jl for dev package installation at $pkgroot"
	try
		open(srcfile, "w") do io
			write_interface(io, template)
		end
		# `starting_point` must use ObjectClass(:temporal_block) as its class dimension (not
		# :starting_point) so that parameter lookups like `has_free_start(temporal_block=blk)` correctly resolve it.
		# The template format cannot express this, so we append it manually.
		open(srcfile, "a") do io
			write(io, "\n# NOTE: manually appended — see deps/build.jl for explanation.\n")
			write(io, "const starting_point = ObjectClass(:temporal_block)\nexport starting_point\n")
		end
	catch
		@warn "Failed to generate convenience_functions.jl! Likely due to missing permissions."
	end
else
	@info "Skipping generation of convenience_functions.jl for non-dev package installation at $pkgroot"
end