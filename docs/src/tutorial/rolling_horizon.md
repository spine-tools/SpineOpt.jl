# Rolling horizon tutorial

This tutorial provides a step-by-step guide to setup a rolling horizon optimization in a simple energy system with Spine Toolbox for SpineOpt.

## Introduction

Welcome to our tutorial, where we will walk you through the process of setting up a rolling horizon optimization in SpineOpt using Spine Toolbox. To get the most out of this tutorial, we suggest first completing the Unit Commitment tutorial, which can be found [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/unit_commitment/).

### Model assumptions

This tutorial is built on top of the Unit Commitment example. The main changes to that system are:

- The demand at *electricity\_node* is a 168-hour time series (i.e., one week) instead of a day
- The model uses the option roll forward to defines how much the model moves ahead in time between solves in a rolling optimization.

This tutorial includes a step-by-step guide to include the parameters to help analyze the results in SpineOpt and the unit commitment concepts.

## Step 1 - Update the demand

### Opening the Simple System project

- Launch the Spine Toolbox and select **File** and then **Open Project** or use the keyboard shortcut **Ctrl + O** to open the desired project.
- Locate the folder that you saved in the Simple System tutorial and click *Ok*. This will prompt the Simple System workflow to appear in the *Design View* section for you to start working on.
- Select the 'input' Data Store item in the *Design View*.
- Go to *Data Store Properties* and hit **Open editor**. This will open the database in the *Spine DB editor*.

In this tutorial, you will learn how to add unit commitment constraints to the Simple System using the *Spine DB editor*, but first let's start by updating the electricity demand from 24-hour to a 168-hour time series.

### Editing demand value

- Always in the Spine DB editor, locate the *Object tree* (typically at the top-left). Expand the [root] element if not expanded.
- Expand the [node] class, and select the *electricity\_node* from the expanded tree.
- Locate the *Object parameter* table (typically at the top-center).
- In the *Object parameter* table, identify the *demand* parameter which should have a 150 value from the Simple System first run.
- Right click on the value cell and then select *edit* from the context menu. The *Edit value* dialog will pop up.
- Change the *Parameter type* to *Time series fixed resolution*, *Resolution* to *1h*, and the demand values to the time series as in the image below. You can copy and paste the values from the file: [uc_electricity_node_demand.csv](figs_rolling_horizon/uc_electricity_node_demand_week.csv)
- Finish by pressing *OK* in the *Edit value* menu. In the *Object parameter* table you will see that the value of the *demand* has changed to *Time series*.

![image](figs_rolling_horizon/rh_electricity_demand.png)

When you're ready, commit all changes to the database.

### Executing the workflow

- Go back to Spine Toolbox's main window, and hit the **Execute project** button ![image](figs_simple_system/play-circle.png) from the tool bar. You should see 'Executing All Directed Acyclic Graphs' printed in the *Event log* (at the bottom left by default).

- Select the 'Run SpineOpt' Tool. You should see the output from SpineOpt in the *Julia Console* after clicking the *object activity control*.

### Examining the results

- Select the output data store and open the Spine DB editor. You can already inspect the fields in the displayed tables.
- You can also activate the table view by pressing **Alt + F** for the shortcut to the hamburger menu, and select **View -> Table**.
- Remember to select the latest run in the *Alternative tree*. Expand the *Output* element if not expanded.
- In the *Relationship parameter value* table, double click in the *Time series* values to explore the results of the different variables.
- The image below shows the electricity flow results for both power plants. As expected, the *power\_plant\_a* (i.e., the cheapest unit) always covers the demand first until its maximum capacity, and then the *power\_plant\_b* (i.e., the more expensive unit) covers the demand that is left. This is the most economical dispatch since the problem has no extra constraints (so far!).

![image](figs_unit_commitment/uc_flow_results_no_uc.png)

To explore the cost results, the pivot table view shows a more user-friendly option to analyze the results. Remember that you can find a description of how to create the pivot table view in the Simple System tutorial [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/). The cost components in the objective function are shown in the image below. As expected, all the costs are associated with the *variable\_om\_costs* since we haven't included the unit-commitment constraints yet.

![image](figs_unit_commitment/uc_costs_results_no_uc.png)

## Step 2 - Define the rolling horizon

Let's assume that the *power\_plant\_b* has a minimum operating point of *10%*, meaning that if the power plant is *on*, it must produce at least *20MW*.

### Adding the minium operating point

- In the Spine DB editor, locate the *Relationship tree* (typically at the bottom-left). Expand the *root* element if not expanded.
- In *Relationship tree*, expand the *unit\_\_to\_node* class and select *power\_plant\_b | electricity\_node*.
- In the *Relationship parameter* table (typically at the bottom-center), select the *minimum\_operating\_point* parameter and the *Base* alternative, and enter the value *0.1* as seen in the image below. This will set the minimum operating point of *power\_plant\_b* when producing electricity.

![image](figs_unit_commitment/uc_power_plant_b_electricity_node_data_definition.png)

### Adding the unit commitment costs and initial states

- Locate the *Object tree* (typically at the top-left). Expand the [root] element if not expanded.
- Expand the [unit] class, and select the *power\_plant\_b* from the expanded tree.
- In the *Object parameter* table (typically at the top-center), select the following parameter as seen in the image below:
  - *online\_variable\_type* parameter and the *Base* alternative, and select the value *unit\_online\_variable\_type\_binary*. This will define that the unit commitment variables will be binary. SpineOpt identifies this situation from the input data and internally changes the model from LP to MIP.
  - *shut\_down\_cost* parameter and the *Base* alternative, and enter the value *7*. This will establish that there's a cost of '7' EUR per shutdown.
  - *start\_up\_cost* parameter and the *Base* alternative, and enter the value *5*. This will establish that there's a cost of '5' EUR per startup.
  - *units\_on\_cost* parameter and the *Base* alternative, and enter the value *3*. This will establish that there's a cost of '3' EUR per units on (e.g., idling cost).
  - *initial\_units\_on* parameter and the *Base* alternative, and enter the value *0*. This will establish that there are no units 'on' before the first time step.

![image](figs_unit_commitment/uc_power_plant_b_costs_definition.png)

When you're ready, commit all changes to the database.

### Executing the workflow with the rolling horizon

- Go back to Spine Toolbox's main window, and hit the **Execute project** button ![image](figs_simple_system/play-circle.png) from the tool bar. You should see 'Executing All Directed Acyclic Graphs' printed in the *Event log* (at the bottom left by default).

- Select the 'Run SpineOpt' Tool. You should see the output from SpineOpt in the *Julia Console* after clicking the *object activity control*.

- Do you notice something different in your solver log? Depending on the solver, the output might change, but you should be able to see that the solver is using MIP to solve the problem. For instance, if you are using the solver **HiGHS** (i.e., the default solver in SpineOpt), then you will see something like *"Solving MIP model with:"* and the *Branch and Bound* (B&B) tree solution. Since this is a tiny problem, sometimes the solver can find the optimal solution from the presolve step, avoiding going into the *B&B* step.

### Examining the results with rolling horizon

- Select the output data store and open the Spine DB editor. You can already inspect the fields in the displayed tables.
- You can also activate the table view by pressing **Alt + F** for the shortcut to the hamburger menu, and select **View -> Table**.
- Remember to select the latest run in the *Alternative tree*. Expand the *Output* element if not expanded.
- In the *Relationship parameter value* table, double click in the *Time series* values to explore the results of the different variables.
- The image below shows the electricity flow results for both power plants. Any difference? What happended to the flows in *power\_plant\_a* and *power\_plant\_b*?

![image](figs_unit_commitment/uc_flow_results_min_op_point.png)

- Let's take a look to the *units\_on* and *units\_started\_up* in the image below to get wider perspective.

![image](figs_unit_commitment/uc_results_min_op_point.png)

- So, since *power\_plant\_b* needs to be at least producing *20MW* when it is 'on', then *power\_plant\_a* needs to reduce its output even though it has the lower variable cost, making the total system cost (i.e., objective function) more expensive than in the previous run. The image below shows the cost components, where we can see the costs of having the *power\_plant\_b* on, its start-up and shutdown costs, and the increase in the *variable\_om\_costs* due to flow changes.

![image](figs_unit_commitment/uc_costs_results_min_op_point.png)

If you have completed this tutorial, congratulations! You have mastered the basic concepts of rolling horizon and how to set it up in SpineOpt using SpineToolbox. Keep up the good work!
