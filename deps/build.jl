using SpineInterface
using JSON

const template = JSON.parsefile(joinpath(@__DIR__, "..", "templates", "spineopt_template.json"))
const preproc_template = JSON.parsefile(joinpath(@__DIR__, "..", "templates", "preprocessing_template.json"))

merge!(append!, template, preproc_template)

open(joinpath(@__DIR__, "..", "src", "convenience_functions.jl"), "w") do io
	write_interface(io, template)
end