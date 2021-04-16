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

    2.a) Drag a tool *Load template* from the SpineOpt ribbon to the *Design View*. Connect an arrow from the *Load template* to the new *Input DB*. Make sure the  *Load template* item from the Design view is selected (then you can edit the properties of that workflow item in the *Tool properties* window. Add the url link in *Available resources* to the *Tool arguments* - you are passing the database address as a command line argument to the load_template.jl script so that it knows where to store the output. Then execute the *Load template* tool. Please note that this process uses SpineOpt to generate the data structure. It takes time, since everything is compiled when running a tool in Julia for the first time in each Julia session. You may also see lot of messages and warnings concernging the compilation, but they should be benign.
      
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

This part of the guide shows first an example how to insert objects and their parameter data. Then it shows what other objects, relationships and parameter data needs to be added for a very basic model. Lastly, the model instance is run.

1. Add a model instance to the *Input DB*. First, open the database editor by double-clicking the *Input DB*. Right click on *model* in the *Object tree*. Choose *Add objects*. Then, add a model object by writing a name to the *object name* field. You can use e.g. *instance*. Click ok.

    ![image](https://user-images.githubusercontent.com/40472544/114978841-880e8980-9e92-11eb-9272-5dc46708006f.png)

    ![image](https://user-images.githubusercontent.com/40472544/114978964-ba1feb80-9e92-11eb-9f73-14a6c11ad3bd.png)

2. Add parameters to the model instance. You need to define the *duration_unit* --> select 'hour' from the list. Then you need to define a *model_start* time and a *model_end* time. These need to be *Date time* parameters. Right-click on the *value* field and choose *Edit...*. Then you can change the parameter type to *Date time* and give an appropraite datetime.

    ![image](https://user-images.githubusercontent.com/40472544/114981259-5d263480-9e96-11eb-9338-1f4bbcff4ecc.png)

    ![image](https://user-images.githubusercontent.com/40472544/114979680-fc95f800-9e93-11eb-834d-75c5f9627c2a.png)

    ![image](https://user-images.githubusercontent.com/40472544/114979620-e5570a80-9e93-11eb-9163-6a4fbbe5631a.png)


3. Add other necessary objects and parameter data for the objects. See picture below. There are three object names that need to be written exactly since they are used internally by SpineOpt: *unit_flow*, *realization*, and *deterministic*. The date time and time series parameter data can be added by using right-click to access the *Edit...* dialog.

    ![image](https://user-images.githubusercontent.com/40472544/115009663-31667700-9eb5-11eb-8f71-163ff14233a7.png)

4. Add necessary relationships and parameter data for the relationships. See picture below. The capacity of the gas_turbine has to be sufficient to meet the highest demand for electricity, otherwise the model will be infeasible (it is possible to set penalty values, but they are not included in this example).

    ![image](https://user-images.githubusercontent.com/40472544/115010276-e305a800-9eb5-11eb-9b29-8bb4f5bb792d.png)


5. Run the model. Select *SpineOpt* and press *Execute selection*.

    ![image](https://user-images.githubusercontent.com/40472544/115010605-48599900-9eb6-11eb-930d-b2a258b61bf7.png)


6. Explore the results by double-clicking the *Results* database.

    ![image](https://user-images.githubusercontent.com/40472544/115010687-5d362c80-9eb6-11eb-8542-93a765c186cf.png) 

7. Create and run scenarios and build the model further

    ![image](https://user-images.githubusercontent.com/40472544/115011024-ca49c200-9eb6-11eb-8ddd-8b312c095b74.png)

    ![image](https://user-images.githubusercontent.com/40472544/115011214-0da43080-9eb7-11eb-93e5-e2991e81b429.png)




## Compatibility

This package requires Julia 1.2 or later.

## Prerequisites

To make use of the full functionality of SpineOpt, we strongly recommend the installation of [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).
SpineToolbox provides all the necessary tools for data management required by SpineOpt.
