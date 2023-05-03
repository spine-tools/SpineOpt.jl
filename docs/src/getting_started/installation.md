# Compatibility

This package requires Julia 1.2 or later.

# Installation

SpineOpt is cross-platform (Linux, Mac and Windows) and uses other cross-platform tools. The installation process includes several steps, since there are two other pieces of software that make the use of SpineOpt more convenient (Spine Toolbox and Conda) and two programming languages that are needed (Python for Spine Toolbox and Julia for SpineOpt). Python will be installed with Conda while Julia is installed independently and then setup for Spine Toolbox (explained below). Conda can be replaced by another environment manager, but these instructions are for Conda.

You may skip parts of the following installation process if you already have some of these software available - but please make sure they are in a clean Conda environment to avoid compatibility issues between different package versions.

SpineOpt and Spine Toolbox are under active development and the getting started process could change. If you notice any problems with these instructions, please check if it is a known issue, and if not, then report an [issue](https://github.com/Spine-project/SpineOpt.jl/issues) or start a [discussion](https://github.com/Spine-project/SpineOpt.jl/discussions/categories/support-discuss-a-potential-bug) if you're unsure whether it is an actual issue.

- The recommended interface to SpineOpt is [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox). Install Spine Toolbox following instructions from here: [Spine Toolbox installation](https://github.com/Spine-project/Spine-Toolbox#installation)

- Setup Julia for Spine Toolbox: [Start Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox#running). Go to *File* --> *Settings* --> *Tools*. Either select an existing Julia installation, or press *Install Julia* button and follow the instructions. You can download & install Julia manually from https://julialang.org/downloads/.

- [Optional] If you want to install and run SpineOpt in a specific Julia project environment (the place for Project.toml and Manifest.toml), you can set the path to the environment folder to the line edit just below the Julia executable line edit (the one that says *Using Julia default project* when empty).

- [Optional] Select a Julia Kernel spec. If none exist, you need to install a Julia kernel specification either [manually](https://julialang.github.io/IJulia.jl/stable/manual/installation/#Installing-additional-Julia-kernels) or by using the dialog under *Kernel spec editor* button. Use the newly installed Julia, give the kernel spec a name and click 'Make kernel specification' button. Installing a kernel spec also installs the IJulia package if missing. The kernel specs allows you to interact with Julia code inside Spine Toolbox using the Julia console.

- Install SpineOpt by clicking the `Add/Update SpineOpt` button and follow the instructions on screen. You may also install SpineOpt manually by opening a Julia REPL (must be the same Julia that you just selected for Spine Toolbox). Enter the following into the REPL:
```julia
julia> using Pkg

julia> pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"

julia> pkg"add SpineOpt"
```   
This may take a while and nothing seems to happen, but the installation process should be ongoing.

- Add SpineOpt tool icons to Spine Toolbox. Go to *Plugins* --> *Install plugins* and select and install SpineOpt.

- You should get a new ribbon in the toolbar with *Run SpineOpt* and *Load template*

![image](https://user-images.githubusercontent.com/40472544/114974012-42e65980-9e8a-11eb-9b00-edfc53b8baf0.png)

After this, you have SpineOpt available as a tool in Spine Toolbox, but next you need to setup a workflow including input and output dabases. Instructions are in the next section [here](https://spine-project.github.io/SpineOpt.jl/latest/getting_started/setup_workflow/).
