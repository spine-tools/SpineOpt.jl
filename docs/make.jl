using Documenter, SpineModel

makedocs(
    sitename = "SpineModel Documentation"
)

deploydocs(
    repo  = "github.com/Spine-project/Spine-Model.git",
    devurl = "dev",
    versions = ["stable" => "v^", "v#.#", devurl => "dev"]
)
