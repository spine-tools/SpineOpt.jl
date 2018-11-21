using Documenter, SpineModel, PyCall #, Example,

makedocs(sitename = "SpineModel Documentation")

deploydocs(
    deps  = Deps.pip("mkdocs", "python-markdown-math"),
    repo  = "github.com/Spine-project/Spine-Model.git",
    julia = "0.6"
)
