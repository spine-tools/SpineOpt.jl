# Setting up a workflow for SpineOpt in Spine Toolbox

The next steps will set up a SpineOpt specific input database, connect it to a SpineOpt instance and setup a database for model results. 

- Drag an empty *Data store* from the toolbar to the *Design View*. Give it a name like "Input DB". Select SQL database dialect (sqlite is a local file and works without a server). Click *New Spine DB* in the *Data Store Properties* window and create a new database (and save it, if it's sqlite).

    ![image](https://user-images.githubusercontent.com/40472544/114974364-e8013200-9e8a-11eb-99d6-9fbbd0d3992b.png)
    
    ![image](https://user-images.githubusercontent.com/40472544/114976986-97400800-9e8f-11eb-8bec-79d85aac5a66.png)

- Fill the *Input DB* with SpineOpt data format **either** by:

    - Drag a tool *Load template* from the SpineOpt ribbon to the *Design View*. Connect an arrow from the *Load template* to the new *Input DB*. Make sure the  *Load template* item from the Design view is selected (then you can edit the properties of that workflow item in the *Tool properties* window. Add the url link in *Available resources* to the *Tool arguments* - you are passing the database address as a command line argument to the load_template.jl script so that it knows where to store the output. Then execute the *Load template* tool. Please note that this process uses SpineOpt to generate the data structure. It takes time, since everything is compiled when running a tool in Julia for the first time in each Julia session. You may also see lot of messages and warnings concernging the compilation, but they should be benign.
      
    ![image](https://user-images.githubusercontent.com/40472544/114975150-6d391680-9e8c-11eb-94d3-325f56ff55cf.png)

    ![image](https://user-images.githubusercontent.com/40472544/114975271-9eb1e200-9e8c-11eb-93a5-5da3d07b8039.png)
    
    ![image](https://user-images.githubusercontent.com/40472544/114975643-44fde780-9e8d-11eb-9ea6-873b39d8ce9f.png)

    ![image](https://user-images.githubusercontent.com/40472544/114975723-68c12d80-9e8d-11eb-8053-a17ca1190114.png)


    - Start Julia (you can start a separate Julia console in Spine Toolbox: go to *Consoles* --> *Start Julia Console*). Copy the URL address of the Data Store from the 'Data Store Properties' --> a copy icon at the bottom. Then run the following script with the right URL address pasted. The process uses SpineOpt itself to build the database structure. Please note that 'using SpineOpt' for the first time for each Julia session takes time - everything is being compiled.
    ```julia
    julia> using SpineOpt

    julia> SpineOpt.import_data("copied URL address, inside these quotes", SpineOpt.template(), "Load SpineOpt template")
    ```
Known issue: On Windows, the backslash between directories need to be changed to a double forward slash.

- Drag SpineOpt tool icon to the *Design view*. Connect an arrow from the *Input DB* to *SpineOpt*. 

    ![image](https://user-images.githubusercontent.com/40472544/114976496-bdb17380-9e8e-11eb-827c-232bd5027818.png)


- Drag a new *Data store* from the toolbar to the *Design View*. You can rename it to e.g. *Results*. Select SQL database dialect (sqlite is a local file and works without a server). Click *New Spine DB* in the *Data Store Properties* window and create a new database (and save it, if it's sqlite). Connect an arrow from the *SpineOpt* to *Results*.

    ![image](https://user-images.githubusercontent.com/40472544/114977707-c99e3500-9e90-11eb-9da1-356ed191ffb3.png)

- Select *SpineOpt* tool in the *Design view*. Add the url link for the input data store and the output data store from *Available resources* to the *Tool arguments* (in that order).

    ![image](https://user-images.githubusercontent.com/40472544/114977877-171aa200-9e91-11eb-89e0-9896f6cc1fab.png)

- SpineOpt would be ready to run, but for the *Input DB*, which is empty of content (it's just a template that contains an appropriate data structure). The next step goes through setting up a simple toy model.
