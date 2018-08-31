using Documenter, Example

include("../src/SpineModel.jl")
using SpineModel

makedocs(sitename = "SpineModel",
         repo = "https://gitlab.vtt.fi/spine/model/blob/{commit}{path}#{line}")
