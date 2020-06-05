using Documenter, SpineOpt

makedocs(
    sitename = "SpineOpt.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "Home" => "index.md",
        "Library" => "library.md",
    ]
)

deploydocs(
    repo  = "github.com/Spine-project/Spine-Model.git",
    versions = ["stable" => "v^", "v#.#"]
)
