# Installation

SpineOpt is cross-platform (Linux, Mac and Windows) and uses other cross-platform tools. The installation process includes several steps, since there are two other pieces of software that make the use of SpineOpt more convenient (Spine Toolbox and Conda) and two programming languages that are needed (Python for Spine Toolbox and Julia for SpineOpt). Python will be installed with Conda while Julia will be setup for Spine Toolbox (explained below). 

You may skip parts of the following installation process if you already have some of these software available - but please make sure they are in a clean Conda environment to avoid compatibility issues between different package versions.

SpineOpt and Spine Toolbox are under active development and the getting started process could change. If you notice any problems with these instructions, please check if it is a known issue, and if not, then report an [issue](https://github.com/Spine-project/SpineOpt.jl/issues) or start a [discussion](https://github.com/Spine-project/SpineOpt.jl/discussions/categories/support-discuss-a-potential-bug) if you're unsure.

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

    ![image](https://user-images.githubusercontent.com/40472544/114974012-42e65980-9e8a-11eb-9b00-edfc53b8baf0.png)


# Setting up a workflow for SpineOpt in Spine Toolbox

The next steps will set up a SpineOpt specific input database, connect it to a SpineOpt instance and setup a database for model results. 

1. Drag an empty *Data store* from the toolbar to the *Design View*. Give it a name like "Input DB". Select SQL database dialect (sqlite is a local file and works without a server). Click *New Spine DB* in the *Data Store Properties* window and create a new database (and save it, if it's sqlite).

    ![image](https://user-images.githubusercontent.com/40472544/114974364-e8013200-9e8a-11eb-99d6-9fbbd0d3992b.png)
    
    ![image](https://user-images.githubusercontent.com/40472544/114976986-97400800-9e8f-11eb-8bec-79d85aac5a66.png)

2. Fill the *Input DB* with SpineOpt data format **either** by:

    2.a) Drag a tool *Load template* from the SpineOpt ribbon to the *Design View*. Connect an arrow from the *Load template* to the new *Input DB*. Make sure the  *Load template* item from the Design view is selected (then you can edit the properties of that workflow item in the *Tool properties* window. Add the url link in *Available resources* to the *Tool arguments* - you are passing the database address as a command line argument to the load_template.jl script so that it knows where to store the output. Then execute the *Load template* tool.
  
    ![image](https://user-images.githubusercontent.com/40472544/114975150-6d391680-9e8c-11eb-94d3-325f56ff55cf.png)

    ![image](https://user-images.githubusercontent.com/40472544/114975271-9eb1e200-9e8c-11eb-93a5-5da3d07b8039.png)
    
    ![image](https://user-images.githubusercontent.com/40472544/114975643-44fde780-9e8d-11eb-9ea6-873b39d8ce9f.png)

    ![image](https://user-images.githubusercontent.com/40472544/114975723-68c12d80-9e8d-11eb-8053-a17ca1190114.png)


    2.b) Start Julia (you can start a separate Julia console in Spine Toolbox: go to *Consoles* --> *Start Julia Console*). Copy the URL address of the Data Store from the 'Data Store Properties' --> a copy icon at the bottom. Then run the following script with the right URL address pasted. The process uses SpineOpt itself to build the database structure. Please note that 'using SpineOpt' for the first time for each Julia session takes time - everything is being compiled.
    ```julia
    julia> using SpineOpt

    julia> SpineOpt.import_data("copied URL address, inside these quotes", SpineOpt.template(), "Load SpineOpt template")
    ```
Known issue: On Windows, the backslash between directories need to be changed to a double forward slash.

3. Drag SpineOpt tool icon to the *Design view*. Connect an arrow from the *Input DB* to *SpineOpt*. 

    ![image](https://user-images.githubusercontent.com/40472544/114976496-bdb17380-9e8e-11eb-827c-232bd5027818.png)


4. Drag a new *Data store* from the toolbar to the *Design View*. You can rename it to e.g. *Results*. Select SQL database dialect (sqlite is a local file and works without a server). Click *New Spine DB* in the *Data Store Properties* window and create a new database (and save it, if it's sqlite). Connect an arrow from the *SpineOpt* to *Results*.

    ![image](https://user-images.githubusercontent.com/40472544/114977707-c99e3500-9e90-11eb-9da1-356ed191ffb3.png)

5. Select *SpineOpt* tool in the *Design view*. Add the url link for the input data store and the output data store from *Available resources* to the *Tool arguments* (in that order).

    ![image](https://user-images.githubusercontent.com/40472544/114977877-171aa200-9e91-11eb-89e0-9896f6cc1fab.png)

6. SpineOpt would be ready to run, but for the *Input DB*, which is empty of content (it's just a template that contains an appropriate data structure). The next step goes through setting up a simple toy model.

## Running SpineOpt

TODO

## Compatibility

This package requires Julia 1.2 or later.

## Prerequisites

To make use of the full functionality of SpineOpt, we strongly recommend the installation of [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).
SpineToolbox provides all the necessary tools for data management required by SpineOpt.
