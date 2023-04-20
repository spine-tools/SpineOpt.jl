# Hydro Power Planning

Welcome to this Spine Toolbox tutorial for building hydro power planning
models. The tutorial guides you through the implementation of different
ways of modelling hydrodologically-coupled hydropower systems.

<div class="contents" local="">

</div>

## Introduction

This tutorial aims at demonstrating how we can model a hydropower system
in Spine (<span class="title-ref">SpineOpt.jl</span> and <span
class="title-ref">Spine-Toolbox</span>) with different assumptions and
goals. It starts off by setting up a simple model of system of two
hydropower plants and gradually introduces additional features. The goal
of the model is to capture the combined operation of two hydropower
plants (Språnget and Fallet) that operate on the same river as shown in
the picture bellow. Each power plant has its own reservoir and generates
electricity by discharging water. The plants might need to spill water,
i.e., release water from their reservoirs without generating
electricity, for various reasons. The water discharged or spilled by the
upstream power plant follows the river route and becomes available to
the downstream power plant.

### A system of two hydropower plants.

In order to run this tutorial you must first execute some preliminary
steps from the [Simple System](./simple_system.html) tutorial.
Specifically, execute all steps from the
[guide](./simple_system.html#guide), up to and including the step of
[importing-the-spineopt-database-template](./simple_system.html#importing-the-spineopt-database-template).
It is advisable to go through the whole tutorial in order to familiarise
yourself with Spine.

<div class="note">

<div class="title">

Note

</div>

Just remember to give a different name for the Spine Project of the
hydropower tutorial (e.g., ‘Two_hydro’) in the corresponding step, so to
not mix up the Spine Toolbox projects!

</div>

That is all you need at the moment, you can now start inserting the
data.

## Setting up a Basic Hydropower Model

For creating a SpineOpt model you need to create <span
class="title-ref">Objects</span>, <span
class="title-ref">Relationships</span> (associating the objects), and in
some cases, parameters values accompanying them. To do this, open the
input database using the Spine DB Editor (double click on the input
database in the <span class="title-ref">Design View</span> pane of Spine
Toolbox).

<div class="note">

<div class="title">

Note

</div>

To save your work in the Spine DB Editor you need to <span
class="title-ref">commit</span> your changes (please check the Simple
System tutorial for how to do that). As a good practice, you should
commit often as you enter the data in the model to avoid data loss.

</div>

### Defining objects

#### Commodities

Since we are modelling a hydropower system we will have to define two
commodities, water and electricity. In the Spine DB editor, locate the
<span class="title-ref">Object tree</span>, expand the root element if
required, right click on the commodity class, and select <span
class="title-ref">Add objects</span> from the context menu. In the <span
class="title-ref">Add objects</span> dialogue that should pop up, enter
the object names for the commodities as you see in the image below and
then press Ok.

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_commodities.png" class="align-center"
width="600" alt="Defining commodities." />
<figcaption aria-hidden="true">Defining commodities.</figcaption>
</figure>

#### Nodes

Follow a similar path to add nodes, right click on the node class, and
select <span class="title-ref">Add objects</span> from the context menu.
In the dialogue, enter the node names as shown:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_nodes.png" class="align-center" width="600"
alt="Defining nodes." />
<figcaption aria-hidden="true">Defining nodes.</figcaption>
</figure>

Nodes in SpineOpt are used to balance commodities. As you noticed, we
defined two nodes for each hydropower station (water nodes) and a single
electricity node. This is one possible way to model the hydropower plant
operation. This will become clearer in the next steps, but in a
nutshell, the <span class="title-ref">upper</span> node represents the
water arriving at each plant, while the <span
class="title-ref">lower</span> node represents the water that is
discharged and becomes available to the next plant.

#### Connections

Similarly, add connections, right click on the connection class, select
<span class="title-ref">Add objects</span> from the context menu and add
the following connections:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_connections.png" class="align-center"
width="600" alt="Defining connections." />
<figcaption aria-hidden="true">Defining connections.</figcaption>
</figure>

Connections enable the nodes to interact. Since, for each plant we need
to model the amount of water that is discharged and the amount that is
spilled, we must define two connections accordingly. When defining
relationships we shall associate the connections with the nodes.

#### Units

To convert from one type of commodity associated with one node to
another, you need a unit. You guessed it! Right click on the unit class,
select <span class="title-ref">Add objects</span> from the context menu
and add the following units:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_units.png" class="align-center" width="600"
alt="Defining units." />
<figcaption aria-hidden="true">Defining units.</figcaption>
</figure>

We have defined one unit for each hydropower plant that converts water
to electricity and an additional unit that we will use to model the
income from selling the electricity production in the electricity
market.

### Relationships

#### Assinging commodities to nodes

Since we have defined more than one commodities, we need to assign them
to nodes. In the Spine DB editor, locate the <span
class="title-ref">Relationship tree</span>, expand the root element if
required, right click on the <span
class="title-ref">node\_\_commodity</span> class, and select <span
class="title-ref">Add relationships</span> from the context menu. In the
<span class="title-ref">Add relationships</span> dialogue, enter the
following relationships as you see in the image below and then press Ok.

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_node_commodities.png" class="align-center"
width="600" alt="Introducing node__commodity relationships." />
<figcaption aria-hidden="true">Introducing <span
class="title-ref">node__commodity</span> relationships.</figcaption>
</figure>

#### Associating connections to nodes

Next step is to define the topology of flows between the nodes. To do
that insert the following relationships in the <span
class="title-ref">connection\_\_from_node</span> class:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_connection_from_node.png" class="align-center"
width="600" alt="Introducing connection__from_node relationships." />
<figcaption aria-hidden="true">Introducing <span
class="title-ref">connection__from_node</span>
relationships.</figcaption>
</figure>

as well as the following the following <span
class="title-ref">connection\_\_node_node</span> relationships as you
see in the figure:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_connection_node_node.png" class="align-center"
width="600" alt="Introducing connection__node_node relationships." />
<figcaption aria-hidden="true">Introducing <span
class="title-ref">connection__node_node</span>
relationships.</figcaption>
</figure>

#### Placing the units in the model

To define the topology of the units and be able to introduce their
parameters later on, you need to define the following relationships in
the <span class="title-ref">unit\_\_from_node</span> class:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_unit_from_node.png" class="align-center"
width="600" alt="Introducing unit__from_node relationships." />
<figcaption aria-hidden="true">Introducing <span
class="title-ref">unit__from_node</span> relationships.</figcaption>
</figure>

in the <span class="title-ref">unit\_\_node_node</span> class:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_unit_node_node.png" class="align-center"
width="600" alt="Introducing unit__node_node relationships." />
<figcaption aria-hidden="true">Introducing <span
class="title-ref">unit__node_node</span> relationships.</figcaption>
</figure>

and in the <span class="title-ref">unit\_\_to_node</span> class as you
see in the following figure:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_unit_to_node.png" class="align-center"
width="600" alt="Introducing unit__to_node relationships." />
<figcaption aria-hidden="true">Introducing <span
class="title-ref">unit__to_node</span> relationships.</figcaption>
</figure>

#### Defining the report outputs

To force Spine to export the optimal values of the optimization
variables to the output database you need to specify them in the form of
<span class="title-ref">report_output</span> relationships. Add the
following relationships to the <span
class="title-ref">report_output</span> class:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_report.png" class="align-center" width="600"
alt="Introducing report outputs with report_output relationships." />
<figcaption aria-hidden="true">Introducing report outputs with <span
class="title-ref">report_output</span> relationships.</figcaption>
</figure>

### Objects and Relationships parameter values

#### Defining model parameter values

The specify modelling properties of both objects and relationships you
need to introduce respective parameter values. To introduce object
parameter values first select the <span class="title-ref">model</span>
class in the Object tree and enter the following values in the <span
class="title-ref">Object parameter value</span> pane:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_model_parameters.png" class="align-center"
width="800" alt="Defining model execution parameters." />
<figcaption aria-hidden="true">Defining model execution
parameters.</figcaption>
</figure>

Observe the difference between the <span class="title-ref">Object
parameter value</span> and the <span class="title-ref">Object parameter
definition</span> sub-panes of the <span class="title-ref">Object
parameter value</span> pane. The first one is for the modeller to
introduce values for specific parameters, while the second one holds the
definition of all available parameters with their default values (these
are overwritten when the user introduces their own values). Feel free to
explore the different parameters and their default values. While
entering data in each row you will also observe that, in most cases,
clicking on each cell activates a drop-down list of elements that the
user must choose from. In the case of the <span
class="title-ref">value</span> cells, however, unless you need to input
a scalar value or a string, you should right-click on the cell and
select edit for specifying the data type of the parameter value. As you
see in the figure above, for the first <span
class="title-ref">duration_unit</span> parameter you is of type string,
while the <span class="title-ref">model_start</span> and <span
class="title-ref">model_end</span> parameters are of type Date time. The
Date time parameters can be edited by right-clicking on the
corresponding <span class="title-ref">value</span> cells, selecting
<span class="title-ref">Edit</span>, and then inserting the Date time
values that you see in the figure above in the <span
class="title-ref">Datetime</span> field using the correct format.

#### Defining node parameter values

Going back to hydropower modelling, we need to specify several
parameters for the nodes of the systems. In the same pane as before, but
this time selecting the <span class="title-ref">node</span> class from
the <span class="title-ref">Object tree</span>, we need to add the
following entries:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_node_parameters.png" class="align-center"
width="800" alt="Defining model execution parameters." />
<figcaption aria-hidden="true">Defining model execution
parameters.</figcaption>
</figure>

Before we go through the interpretation of each parameter, click on the
following link for each <span class="title-ref">fix_node_state</span>
parameter ([Node state
Språnget](https://raw.githubusercontent.com/spine-tools/Spine-Toolbox/master/docs/source/data/Spranget_node.txt),
[Node state
Fallet](https://raw.githubusercontent.com/spine-tools/Spine-Toolbox/master/docs/source/data/Fallet_node.txt)),
select all, copy the data and then paste them directly in the respective
parameter value cell. Spine should automatically detect and input the
timeseries data as a parameter value. The data type for those entries
should be <span class="title-ref">Timeseries</span> as shown in the
figure above. Alternatively, you can select the data type as <span
class="title-ref">Timeseries</span> and manually insert the data (values
with their corresponding datetimes).

To model the reservoirs of each hydropower plant, we leverage the <span
class="title-ref">state</span> feature that a node can have to represent
storage capability. We only need to do this for one of the two nodes
that we have used to model each plant and we choose the <span
class="title-ref">upper</span> level node. To define storage, we set the
value of the parameter <span class="title-ref">has_state</span> as True
(be careful to not set it as a string but select the boolean true value
by right clicking and selecting Edit in the respective cells). This
activates the storage capability of the node. Then, we need to set the
capacity of the reservoir by setting the <span
class="title-ref">node_state_cap</span> parameter value. Finally, we fix
the initial and final values of the reservoir by setting the parameter
<span class="title-ref">fix_node_state</span> to the respective values
(we introduce <span class="title-ref">nan</span> values for the time
steps that we don't want to impose such constraints). To model the local
inflow we use the <span class="title-ref">demand</span> parameter but
using the negated value of the actual inflow, due to the definition of
the parameter in Spine as a **demand**.

#### Defining the temporal resolution of the model

Spine automates the creation of the temporal resolution of the
optimization model and even supports different temporal resolutions for
different parts of the model. To define a model with an hourly
resolution we select the <span class="title-ref">temporal_block</span>
class in the <span class="title-ref">Object tree</span> and we set the
<span class="title-ref">resolution</span> parameter value to <span
class="title-ref">1h</span> as shown in the figure:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_temporal_block.png" class="align-center"
width="400" alt="Setting the temporal resolution of the model." />
<figcaption aria-hidden="true">Setting the temporal resolution of the
model.</figcaption>
</figure>

#### Defining connection parameter values

The water that is discharged from Språnget will flow from <span
class="title-ref">Språnget_lower</span> node to <span
class="title-ref">Fallet_upper</span> through the <span
class="title-ref">Språnget_to_Fallet_disc</span> connection, while the
water that is spilled will flow from <span
class="title-ref">Språnget_upper</span> directly to to <span
class="title-ref">Fallet_upper</span> through the <span
class="title-ref">Språnget_to_Fallet_spill</span> connection. To model
this we need to select the <span
class="title-ref">connection\_\_node_node</span> class in the
Relationship tree and add the following entries in the <span
class="title-ref">Relationship parameter value</span> pane, as shown
next:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_connection_node_node_parameters.png"
class="align-center" width="800"
alt="Defining discharge and spillage ratio flows." />
<figcaption aria-hidden="true">Defining discharge and spillage ratio
flows.</figcaption>
</figure>

#### Defining unit parameter values

Similarly, for each one of the <span
class="title-ref">unit\_\_from_node</span>, <span
class="title-ref">unit\_\_node_node</span>, and <span
class="title-ref">unit\_\_to_node</span> relationship classes we need to
add the the maximal water that can be discharged by each hydropower
plant:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_unit_from_node_parameters.png"
class="align-center" width="800"
alt="Setting the maximal water discharge of each plant." />
<figcaption aria-hidden="true">Setting the maximal water discharge of
each plant.</figcaption>
</figure>

To define the income from selling the produced electricity we use the
<span class="title-ref">vom_cost</span> parameter and negate the values
of the electricity prices. To automatically insert the timeseries data
in Spine, click on the [Electricity prices
timeseries](https://raw.githubusercontent.com/spine-tools/Spine-Toolbox/master/docs/source/data/el_prices.txt),
select all values, copy, and paste them, after having selected the value
cell of the corresponding row. You can plot and edit the timeseries data
by double clicking on the same cell afterwards:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_vom_cost.png" class="align-center" width="800"
alt="Previewing and editing the electricity prices timeseries." />
<figcaption aria-hidden="true">Previewing and editing the electricity
prices timeseries.</figcaption>
</figure>

Carrying on with our hydropower model we must define the conversion
ratios between the nodes. Assuming that water is not "lost" from the
<span class="title-ref">upper</span> node toward the <span
class="title-ref">lower</span> node and electricity is produced with the
discharged water with a given efficiency we define the following
parameter values for each hydropower plant, in the <span
class="title-ref">unit\_\_node_node</span> class:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_unit_node_node_parameters.png"
class="align-center" width="800"
alt="Defining conversion efficiencies." />
<figcaption aria-hidden="true">Defining conversion
efficiencies.</figcaption>
</figure>

Lastly, we can define the maximal electricity production of each plant
by inserting the following <span
class="title-ref">unit\_\_to_node</span> relationship parameter values:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_unit_to_node_parameters.png"
class="align-center" width="800"
alt="Setting the maximal electricity production of each plant." />
<figcaption aria-hidden="true">Setting the maximal electricity
production of each plant.</figcaption>
</figure>

Hooray! You can now commit the database, close the Spine DB Editor and
run your model! Go to the main Spine window and click on Execute <img
src="../../spinetoolbox/ui/resources/menu_icons/play-circle-solid.svg"
width="16" alt="execute" />.

### Examining the results

Select the output data store and open the Spine DB editor. To quickly
plot some results, you can expand the unit class in the Object tree and
select the <span class="title-ref">electricity_load</span> unit. In the
<span class="title-ref">Relationship parameter value</span> pane double
click on the value cell of

> **report1\|electricity_load\|electricity_node\|from_node\|realization**

object name. This will open a plotting window from were you can also
examine closer and retrieve the data, as shown in the next figure. The
<span class="title-ref">unit_flow</span> variable of the <span
class="title-ref">electricity_load</span> unit represents the total
electricity production in the system:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_results_electricity.png" class="align-center"
width="800" alt="Total electricity produced in the system." />
<figcaption aria-hidden="true">Total electricity produced in the
system.</figcaption>
</figure>

Now, take to a minute to reflect on how you could retrieve the data
representing the water that is discharged by each hydropower plant as
shown in the next figure:

<figure>
<img src="tutorial/figs_two_hydro/two_hydro_results_discharge.png" class="align-center"
width="800" alt="Water discharge of Språnget hydropower plant." />
<figcaption aria-hidden="true">Water discharge of Språnget hydropower
plant.</figcaption>
</figure>

The right answer is that you need to select some hydropower plant (e.g.,
Språnget) and then double-click on the value cell of the object name

> **report1\|Språnget_pwr_plant\|Språnget_lower\|to_node\|realization**,
> or
> **report1\|Språnget_pwr_plant\|Språnget_upper\|from_node\|realization**.

It could be useful to also reflect on why these objects give the same
results, and what do the results from the third element represent.
(Hint: observe the <span class="title-ref">to\_</span> or <span
class="title-ref">from\_</span> directions in the object names). As an
exercise, you can try to retrieve the timeseries data for spilled water
as well as the water levels at the reservoir of each hydropower plant.

You can further explore the model, or make changes in the input database
to observe how these affect the results, e.g., you can use different
electricity prices, values for the reservoir capacity (and
initialization points), as well as change the temporal resolution of the
model. All you need to do is commit the changes and run your model.
Every time that you run the model, your results are appended in the
output database with an execution timestamp. You can however filter your
results per execution, by selecting the <span
class="title-ref">Alternative</span> that you want from the <span
class="title-ref">Alternative/Scenario tree</span> pane. You can use the
exporter too to export specific variables in an Excel sheet.
Alternatively, you can export all the data of the output database by
going to the main menu (Press **Alt + F** to display it), selecting
**File -\> Export**, then select the items that you want, click ok and
export the data in Excel, or json format.

In the following, we extend this simple hydropower system to include
more elaborate modelling choices.

<div class="note">

<div class="title">

Note

</div>

In each of the next sections, we perform incremental changes to the
initial simple hydropower model. If you want to keep the database that
you created, you can duplicate the database file (right-click on the
input database and select **Duplicate and duplicate files**) and perform
the changes in the new database. You need to configure the workflow
accordingly in order to run the database you want (please check the
Simple System tutorial for how to do that).

</div>

## Maximisation of Stored Water

Instead of fixing the water content of the reservoirs at the end of the
planning period, we can consider that the remaining water in the
reservoirs has a value and then maximize the value along with the
revenues for producing electricity within the planning horizon. This
objective term is often called the **Value of stored water** and we can
approximate it by assuming that this water will be used to generate
electricity in the future that would be sold at a forecasted price. The
water stored in the upstream hydropower plant will become also available
to the downstream plant and this should be taken into account.

To model the value of stored water we need to make some additions and
modifications to the initial model.

 1.  First, add a new node (see `adding nodes <node>`) and give it a
     name (e.g., <span class="title-ref">stored_water</span>). This
     node will accumulate the water stored in the reservoirs at the end
     of the planning horizon. Associate the node with the water
     commodity (see `node__commodity <node__commodity>`).

 2.  Add three more units (see `adding units <unit>`); two will
     transfer the water at the end of the planning horizon in the new
     node that we just added (e.g., <span
     class="title-ref">Språnget_stored_water</span>, <span
     class="title-ref">Fallet_stored_water</span>), and one will be
     used as a <span class="title-ref">sink</span> introducing the
     value of stored water in the objective function (e.g., <span
     class="title-ref">value_stored_water</span>).

 3.  To establish the topology of the new units and nodes (see
     `adding unit relationships <unit_relationships>`):

     \* add one <span class="title-ref">unit\_\_from_node</span><span
     class="title-ref"> relationship, between the
     \`value_stored_water</span> unit from the <span
     class="title-ref">stored_water</span> node, another one between
     the <span class="title-ref">Språnget_stored_water</span> unit from
     the <span class="title-ref">Språnget_upper</span> node and one for
     <span class="title-ref">Faller_stored_water</span> from <span
     class="title-ref">Fallet_upper</span>.

     -   add one <span class="title-ref">unit\_\_node\_\_node</span>
         relationship between the <span
         class="title-ref">Språnget_stored_water</span> unit with the
         <span class="title-ref">stored_water</span> and <span
         class="title-ref">Språnget_upper</span> nodes and another one
         for <span class="title-ref">Fallet_stored_water</span> unit
         with the <span class="title-ref">stored_water</span> and <span
         class="title-ref">Fallet_upper</span> nodes,
     -   add a <span class="title-ref">unit\_\_to_node</span>
         relationship between the <span
         class="title-ref">Fallet_stored_water</span> and the <span
         class="title-ref">stored_water</span> node and another one
         between the <span
         class="title-ref">Språnget_stored_water</span> unit and the
         <span class="title-ref">stored_water</span> node.

 4.  Now we need to make some changes in object parameter values.

     -   Extend the planning horizon of the model by one hour, i.e.,
         change the <span class="title-ref">model_end</span> parameter
         value to <span class="title-ref">2021-01-02T01:00:00</span>
         (right-click on the value cell, click edit and paste the new
         datetime in the popup window).
     -   Remove the <span class="title-ref">fix_node_state</span>
         parameter values for the end of the optimization horizon as
         you seen in the following figure: double click on the <span
         class="title-ref">value</span> cell of the <span
         class="title-ref">Språnget_upper</span> and <span
         class="title-ref">Fallet_upper</span> nodes, select the third
         data row, right-click, select <span class="title-ref">Remove
         rows</span>, and click OK.
     -   Add an electricity price for the extra hour. Enter the
         parameter <span class="title-ref">vom_cost</span> on the <span
         class="title-ref">unit\_\_from_node</span> relationship
         between the <span class="title-ref">electricity_node</span>
         and the <span class="title-ref">electricity_load</span> and
         set 0 as the price of electricity for the last hour <span
         class="title-ref">2021-01-02T00:00:00</span>. The price is set
         to zero to ensure no electricity is sold during this hour.

     <figure>
     <img src="tutorial/figs_two_hydro/two_hydro_fix_node_state.png" class="align-center"
     width="600"
     alt="Modify the fix_node_state parameter value of Språnget_upper and Fallet_upper nodes." />
     <figcaption aria-hidden="true">Modify the <span
     class="title-ref">fix_node_state</span> parameter value of <span
     class="title-ref">Språnget_upper</span> and <span
     class="title-ref">Fallet_upper</span> nodes.</figcaption>
     </figure>

 5.  Finally, we need to add some relationship parameter values for the
     new units:

     -   Add a <span class="title-ref">vom_cost</span> parameter value
         on a <span
         class="title-ref">value_stored_water\|stored_water</span>
         instance of a <span class="title-ref">unit\_\_from_node</span>
         relationship, as you see in the figure bellow. For the
         timeseries you can copy-paste the data directly from [this
         link](https://raw.githubusercontent.com/spine-tools/Spine-Toolbox/master/docs/source/data/value_stored_water_vom.txt).
         If you examine the timeseries data you'll notice that we have
         imposed a zero cost for all the optimisation horizon, while we
         use an assumed future electricity value for the additional
         time step at the end of the horizon.

     <figure>
     <img src="tutorial/figs_two_hydro/two_hydro_max_stored_water_unit_values.png"
     class="align-center" width="800"
     alt="Adding vom_cost parameter value on the value_stored_water unit." />
     <figcaption aria-hidden="true">Adding <span
     class="title-ref">vom_cost</span> parameter value on the <span
     class="title-ref">value_stored_water</span> unit.</figcaption>
     </figure>

     -   Add two <span
         class="title-ref">fix_ratio_out_in_unit_flow</span> parameter
         values as you see in the figure bellow. The efficiency of
         <span class="title-ref">Fallet_stored_water</span> is the same
         as the <span class="title-ref">Fallet_pwr_plant</span> as the
         water in Fallet's reservoir will be used to produce
         electricity by the the Fallet plant only. On the other hand,
         the water from Språnget's reservoir will be used both by
         Fallet and Språnget plant, therefore we use the sum of the two
         efficiencies in the parameter value of <span
         class="title-ref">Språnget_stored_water</span>.

     <figure>
     <img src="tutorial/figs_two_hydro/two_hydro_max_stored_water_unit_node_node.png"
     class="align-center" width="800"
     alt="Adding fix_ratio_out_in_unit_flow parameter values on the Språnget_stored_water and Fallet_stored_water units." />
     <figcaption aria-hidden="true">Adding <span
     class="title-ref">fix_ratio_out_in_unit_flow</span> parameter values on
     the <span class="title-ref">Språnget_stored_water</span> and <span
     class="title-ref">Fallet_stored_water</span> units.</figcaption>
     </figure>

You can now commit your changes in the database, execute the project and
`examine the results <examine_results>`! As an exercise, try to retrieve
the value of stored water as it is calculated by the model.

## Spillage Constraints - Minimisation of Spilt Water

It might be the case that we need to impose certain limits to the amount
of water that is spilt on each time step of the planning horizon, e.g.,
for environmental reasons, there can be a minimum and a maximum spillage
level. At the same time, to avoid wasting water that could be used for
producing electricity, we could explicitly impose the spillage
minimisation to be added in the objective function.

 1.  Add one unit (see `adding units <unit>`) to impose the spillage
     constraints to each plant and name it (for example <span
     class="title-ref">Språnget_spill</span>).
 2.  Remove the <span class="title-ref">Språnget_to_Fallet_spill</span>
     connection (in the Object tree expand the connection class,
     right-click on <span
     class="title-ref">Språnget_to_Fallet_spill</span>, and the click
     **Remove**).
 3.  To establish the topology of the unit (see
     `adding unit relationships <unit_relationships>`):
     -   Add a <span class="title-ref">unit\_\_from_node</span>
         relationship, between the <span
         class="title-ref">Språnget_spill</span> unit from the <span
         class="title-ref">Språnget_upper</span> node,
     -   add a <span class="title-ref">unit\_\_node\_\_node</span>
         relationship between the <span
         class="title-ref">Språnget_spill</span> unit with the <span
         class="title-ref">Fallet_upper</span> and <span
         class="title-ref">Språnget_upper</span> nodes,
     -   add a <span class="title-ref">unit\_\_to_node</span>
         relationship between the <span
         class="title-ref">Språnget_spill</span> and the <span
         class="title-ref">Fallet_upper</span> node,
 4.  Add the relationship parameter values for the new units:

  -   Set the <span class="title-ref">unit_capacity</span> (to apply a
      maximum), the <span
      class="title-ref">minimum_operating_point</span> (defined as a
      percentage of the <span class="title-ref">unit_capacity</span>)
      to impose a minimum, and the <span
      class="title-ref">vom_cost</span> to penalise the water that is
      spilt:
 
  <figure>
  <img src="tutorial/figs_two_hydro/two_hydro_min_spill_unit_node_node.png"
  class="align-center" width="800"
  alt="Setting minimum (the minimal value is defined as percentage of capacity), maximum, and spillage penalty." />
  <figcaption aria-hidden="true">Setting minimum (the minimal value is
  defined as percentage of capacity), maximum, and spillage
  penalty.</figcaption>
  </figure>
 
  -   For the <span class="title-ref">Språnget_spill</span> unit
      define the <span
      class="title-ref">fix_ratio_out_in_unit_flow</span> parameter
      value of the <span
      class="title-ref">min_spillage\|Fallet_upper\|Språnget_upper</span>
      relationship to **1** (see
      `adding unit relationships <unit_relationships>`).

Commit your changes in the database, execute the project and
`examine the results <examine_results>`! As an exercise, you can perform
this process for and Fallet plant (you would also need to add another
water node, downstream of Fallet).

## Follow Contracted Load Curve

It is often the case that a system of hydropower plants should follow a
given production profile. To model this in the given system, all we have
to do is set a demand in the form of a timeseries to the <span
class="title-ref">electricity_node</span>.

 1.  Add the [Contracted load
     timeseries](https://raw.githubusercontent.com/spine-tools/Spine-Toolbox/master/docs/source/data/contracted_load.txt),
     to the <span class="title-ref">demand</span> parameter value of
     the <span class="title-ref">electricity_node</span> (see
     `adding node parameter values <node_parameters>`).

Commit your changes in the database, execute the project and
`examine the results <examine_results>`!

This concludes the tutorial, we hope that you enjoyed building
hydropower systems in Spine as much as we do!
