using Documenter, SpineModel

makedocs(
    sitename = "SpineModel Documentation"
)

deploydocs(
    repo  = "github.com/Spine-project/Spine-Model.git",
    versions = ["stable" => "v^", "v#.#", devurl => devurl]
)
