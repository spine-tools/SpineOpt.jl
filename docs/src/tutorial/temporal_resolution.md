# Temporal Resolution Tutorial

Welcome to Spine Toolbox's Temporal Resolution tutorial.

This tutorial provides a step-by-step guide to include uniform and/or variable temporal resolution in your model.

For more information on how time works in SpineOpt, see the [Temporal Framework](https://spine-tools.github.io/SpineOpt.jl/latest/advanced_concepts/temporal_framework/) documentation.

## Introduction

### Model assumptions 

- This tutorial builds upon the Simple System tutorial. Please follow [that tutorial](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/) first, or download the [finished model](**NEEDS LINK**).
- The scenario runs for 5 hours and the default temporal resolution is 1 hour.
- The fuel_node has a temporal resolution of [1, 1, 1, 2] hours.

## Tutorial

### Adjustments to Simple System

Before demonstrating flexible temporal resolution, we need to adjust the Simple System tutorial, so the results are more interesting to examine.

If you have the Simple System project saved, skip to **Adding variable electricity demand**.

If you are starting from scratch:

- File > New Project > Create/Select an empty folder
- Drag and drop a Data Store ("InputData"), a Run SpineOpt block, and another Data Store ("OutputData")

!!! note If you are missing the RunSpineOpt block, go to Plugins > Install Plugin > SpineOpt

Set up the input data:
- Select *InputData* and in the *Data Store Properties* window:\
	`Dialect: sqlite`\
	`New Spine db` (button bottom left)\
	`Save` - SpineToolbox will default to a location
- Double click on *InputData* to open the DB Editor
- Select the *Hamburger menu* (top right) > Import > Choose the Simple System JSON file you downloaded earlier

Set up the output data:
- Select *OutputData* and in the *Data Store Properties* window:\
	`Dialect: sqlite`\
	`New Spine db` (button bottom left)\
	`Save` - SpineToolbox will default to a location

Connect the system:
- Click on the white squares to connect the blocks with arrows

![image](figs_temporal_resolution/temporal_resolution_workflow.PNG)

SpineOpt has two arguments: 0) Input database connection 1) Output database connection\
Set these arguments:
- Select the Run SpineOpt block and in the *Tool Properties* window:
- Drag and drop `db_url@InputData` from *Available resources* to *Command line arguments*
- Then drag and drop `db_url@OutputData` the same way
- The order matters! Check that it matches the image below

![image](figs_temporal_resolution/temporal_resolution_input_output.PNG)

Now your simple system should be set up for running. Try clicking the Execute Project button to see if everything runs properly (all green checkmarks). We'll take a look at the data later.

#### Adding variable electricity demand

In SpineToolbox, double click on the *InputData*  block.

!!! note If you are ever missing a window in the Spine DB Editor, go to the *Hamburger menu* (top right) > under View: Docks > Choose the missing window - then drag and resize the window to your preference

In the *Object tree* window:
- Expand "node"
- Select the electricity node
- In the *Object parameter value* window, find the value for the electricity node's demand (should be 150 from the Simple System) - right click > Edit\
	`Parameter type: Time Series fixed resolution`\
	Copy and paste (or fill in the table):
	
		10
		20
		40
		50
		20

- Click OK - this sets the electricity demand to the variable profile listed above

![image](figs_temporal_resolution/temporal_resolution_time_series_demand.PNG)

### Uniform temporal resolution

#### Setting model start & end timestamps

In the *Object Tree* window:
- Expand the model
- Click on "simple"

In the *Object parameter value* window:
- Add model_start \
	`parameter_name:` (Double click) `model_start`\
	`alternative_name:` `Base`\
	`value:` (Right click) Edit > `Parameter Type: Date Time` > `1 Jan` (default)

- Add model_end\
	`parameter_name: model_end`\
	`alternative_name: Base`\
	`value:` Edit > `Parameter Type: Date Time` > 5 hours after start

Your *Object parameter value* window show look like this:

![image](figs_temporal_resolution/temporal_resolution_model_start_end.PNG)

!!! note Regularly save your changes by selecting the *Hamburger menu* (top right) > Commit > Write a message, such as "Save" > OK

#### Setting 1-hr resolution

In the *Object tree* window:
- Expand temporal_block
- Select the existing block (should be called "flat" from the Simple System)

In *Object parameter value* window: 
- Double click `1D` in the value column
- Change it to `1h`
- Click OK - this changes the time resolution from daily to hourly

Now we have a model that runs for 5 hours with hourly resolution.

- Save the changes (Commit) and return to the SpineToolbox window

#### Running the model & viewing results

- Click Execute Project (play arrow) and wait for the model to run

- Double click the *OutputData* block

In the *Relationship Tree* window:

- Select report_unit_node_direction_stochastic_scenario

In the *Frozen table* window, select the most recent "Run ..." entry

!!! note If the *Frozen table* window is empty, also add the *Pivot table* window using the *Hamburger menu*.

In the *Pivot table* window:
- Click and drag over all `Time series` in the `unit_flow` column, right click > Plot

!!! note If `Time series` entries are not visible, select the Hamburger menu > View > Pivot Table: Value

![image](figs_temporal_resolution/temporal_resolution_uniform_results.PNG)

You should see different colored lines, for the *electricity* and *fuel* flows that are *to* and *from* the powerplants (red and green are on top of each other). The blue line shows the electricity demand of [10, 20, 40, 50, 20] - and how the fuel demand from Powerplant A is this same array divided by 0.7 (the conversion ratio). PowerplantA can handle the demand and is more efficient than PowerplantB, so B does not produce.

### Flexible temporal resolution

#### Creating a time-varying resolution

- Return to the SpineToolbox window and select the *InputData* block.

In the *Object Tree* window:
- Expand the temporal_block\
Notice there's a "flat" temporal block, with the attribute that it's the "model_default_temporal_block"

- Right click on temporal_block and click "Add objects"\
`object_name: not_flat` > Click OK

In the *Object Parameter value* window:
- In a new row, set:\
	`object_name: not_flat`\
	`parameter_name: resolution`\
	`alternative_name: Base`\
	`value:` Right click > Edit:\
	`Parameter Type: Array`\
	`Value type: Duration`\
	`Value: 1, 1, 1, 2`

The array should look like this: 

![image](figs_temporal_resolution/temporal_resolution_not_flat_time.PNG)

In the *Object tree* window, expand "not_flat"
- Right click on model_temporal_block and select "Add relationships"\
	`model: simple`
- Click OK - This tells the model that not_flat is a valid temporal block for the simple model.

Now you have seen how to define a varying temporal resolution. You could give "not_flat" the attribute of "model_default_temporal_block" to change the entire model to this variable resolution - but instead we're going to assign it to a specific entity to show how you can mix resolutions in the same model.

#### Assigning an entity a unique resolution

In the *Object tree* window:
- Expand "not_flat"

- Right click on node_temporal_block and select "Add relationships"\
	`node: fuel_node`
- Click OK - This sets the fuel node's temporal resolution to "not_flat" instead of the default of "flat"

- Save the changes (Commit) and return to the SpineToolbox window

#### Running the model & viewing results

- Rerun the model and view the results like before

See how the yellow line (fuel demand of Powerplant A) now ends at a value of 50, which is equal to the last two demand values averaged over the 2hr window (70 + 30) / 2 = 50.

![image](figs_temporal_resolution/temporal_resolution_final_graph.PNG)

