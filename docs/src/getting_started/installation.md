# Installation

SpineOpt is cross-platform (Linux, Mac and Windows) and uses other cross-platform tools. The installation process includes several steps, since there are two other pieces of software that make the use of SpineOpt more convenient (Spine Toolbox and Conda) and two programming languages that are needed (Python for Spine Toolbox and Julia for SpineOpt). Python will be installed with Conda while Julia will be setup for Spine Toolbox (explained below). You may skip parts of the following installation process if you already have some of these software available - but please make sure they are in a clean Conda environment to avoid compatibility issues between different package versions.

1. The recommended interface to SpineOpt is [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox). Install Spine Toolbox following instructions from here: [Spine Toolbox installation](https://github.com/Spine-project/Spine-Toolbox#installation)

2. Setup Julia for Spine Toolbox: [Start Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox#running). Go to *File* --> *Settings* --> *Tools*. Either select an existing Julia installation or press *Install Julia* and follow the instructions.

3. Install SpineOpt from a Julia console (you can use the Julia console in Spine Toolbox: Go to *Consoles* --> *Start Julia Console*)
```julia
julia> using Pkg

julia> pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"

julia> pkg"add SpineOpt"
```   

4. Activate SpineOpt plugin. Go to *Plugins* --> *Install plugins* and select and install SpineOpt.

5. You should get a new ribbon in the toolbar with *Run SpineOpt* and *Load template*


# Setting up a workflow for SpineOpt in Spine Toolbox

The next steps are setting up a SpineOpt specific input database, connect it to a SpineOpt instance and setup a database for model results. 

1. Drag an empty *Data store* from the toolbar to the *Design View*. Select SQL database dialect (sqlite is a local file and works without a server). Click *New Spine DB* in the *Data Store Properties* window and create a new database (and save it, if it's sqlite).

2. Fill the *Data Store* with SpineOpt data format **either** by:

    2.a) Drag a tool *Load template* from the SpineOpt ribbon to the *Design View*. Connect an arrow from the *Load template* to the new *Data Store*. Select the *Load template* item from the Design view. Add the url link in *Available resources* to the *Tool arguments* - you are passing the database address as a command line argument to the load_template.jl script so that it knows where to store the output. Then execute the *Load template* tool.
  
    2.b) Start Julia (you can use the Julia console in Spine Toolbox). Copy the URL address of the Data Store from the 'Data Store Properties' --> a copy icon at the bottom. Start a separate Julia console: go to *Consoles* --> *Start Julia Console*. Then do:
```julia
julia> using SpineOpt

julia> SpineOpt.import_data("copied URL address, inside these quotes", SpineOpt.template() "Load SpineOpt template")
```

3. Drag SpineOpt tool icon to the *Design view*. Connect an arrow from the *Data store* to *SpineOpt*. Add 

4. Drag a new *Data store* from the toolbar to the *Design View*. You can rename it to e.g. *Results*. Select SQL database dialect (sqlite is a local file and works without a server). Click *New Spine DB* in the *Data Store Properties* window and create a new database (and save it, if it's sqlite). Connect an arrow from the *SpineOpt* to *Results*.

5. Select *SpineOpt* tool in the *Design view*. Add the url link for the input data store and the output data store from *Available resources* to the *Tool arguments* (in that order).

6. SpineOpt would be ready to run, but for the *Input DB*, which is empty of content (it's just a template that contains an appropriate data structure). The next step goes through setting up a simple toy model.

## Running SpineOpt

TODO

## Compatibility

This package requires Julia 1.2 or later.

## Prerequisites

To make use of the full functionality of SpineOpt, we strongly recommend the installation of [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).
SpineToolbox provides all the necessary tools for data management required by SpineOpt.

## How to Install

```julia
julia> using Pkg

julia> pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"

julia> pkg"add SpineOpt"

```
