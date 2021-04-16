## Compatibility

This package requires Julia 1.2 or later.

# Installation

SpineOpt is cross-platform (Linux, Mac and Windows) and uses other cross-platform tools. The installation process includes several steps, since there are two other pieces of software that make the use of SpineOpt more convenient (Spine Toolbox and Conda) and two programming languages that are needed (Python for Spine Toolbox and Julia for SpineOpt). Python will be installed with Conda while Julia will be setup for Spine Toolbox (explained below). 

You may skip parts of the following installation process if you already have some of these software available - but please make sure they are in a clean Conda environment to avoid compatibility issues between different package versions.

SpineOpt and Spine Toolbox are under active development and the getting started process could change. If you notice any problems with these instructions, please check if it is a known issue, and if not, then report an [issue](https://github.com/Spine-project/SpineOpt.jl/issues) or start a [discussion](https://github.com/Spine-project/SpineOpt.jl/discussions/categories/support-discuss-a-potential-bug) if you're unsure.

- The recommended interface to SpineOpt is [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox). Install Spine Toolbox following instructions from here: [Spine Toolbox installation](https://github.com/Spine-project/Spine-Toolbox#installation)

- Setup Julia for Spine Toolbox: [Start Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox#running). Go to *File* --> *Settings* --> *Tools*. Either select an existing Julia installation or press *Install Julia* and follow the instructions.

- Install SpineOpt from a Julia console (you can use the Julia console in Spine Toolbox: Go to *Consoles* --> *Start Julia Console*)
```julia
julia> using Pkg

julia> pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"

julia> pkg"add SpineOpt"
```   

- Activate SpineOpt plugin. Go to *Plugins* --> *Install plugins* and select and install SpineOpt.

- You should get a new ribbon in the toolbar with *Run SpineOpt* and *Load template*

    ![image](https://user-images.githubusercontent.com/40472544/114974012-42e65980-9e8a-11eb-9b00-edfc53b8baf0.png)

After this, you have SpineOpt available as a tool in Spine Toolbox, but next you need to setup a workflow including input and output dabases. Instructions are in the next section [here](https://spine-project.github.io/SpineOpt.jl/latest/getting_started/setup_workflow/).
