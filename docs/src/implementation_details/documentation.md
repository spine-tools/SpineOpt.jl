# Documentation

The documentation is mostly build with regular [Documenter.jl](https://documenter.juliadocs.org/stable/). `make.jl` is therefore the main file for building the documentation. However, there are a few convenience functions which automate some parts of the process. Some of these are located close to the documentation (e.g. SPINEOPT.jl/docs/src/mathematical\_formulation/write\_documentation\_sets\_and\_variables.jl) while other functions are inherently part of the SpineOpt code (e.g. SPINEOPT.jl/src/util/docs\_util.jl).

Parameters.md is one of the files that is automatically generated. Each parameter has a description in the concept_reference folder and is further processed with the spineopt template. As such there is no point in attempting to make changes directly in Parameters.md.

There is also a drag-and-drop feature for select chapters. For those chapters you can simply add your markdown file to the folder of the chapter and it will be automatically added to the documentation. To allow both manually composed chapters and automatically generated chapter, the functionality is only activated for empty chapters (of the structure "chapter name" => nothing).

The drag-and-drop function assumes a specific structure for the documentation files.
+ All chapters and corresponding markdownfiles are in the docs/src folder.
+ Folder names need to be lowercase with underscores because the automated folder names are derived from the page names in make.jl. A new chapter (e.g. implementation details) needs to follow this structure.
+ Markdown file names can have uppercases and can have underscores but don't need to because the page names in make.jl are derived from the actual file names. In other words, your filename will become the page name in the documentation so make this descriptive.